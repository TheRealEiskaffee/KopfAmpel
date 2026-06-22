import 'package:drift/drift.dart';

import '../app_database.dart';
import '../converters.dart';
import '../tables/entries.dart';
import '../tables/entry_tags.dart';
import '../tables/tags.dart';

part 'entries_dao.g.dart';

class EntryWithTags {
  EntryWithTags({required this.entry, required this.tags});
  final EntryRow entry;
  final List<TagRow> tags;
}

@DriftAccessor(tables: [Entries, EntryTags, Tags])
class EntriesDao extends DatabaseAccessor<AppDatabase> with _$EntriesDaoMixin {
  EntriesDao(super.db);

  Future<EntryWithTags?> findByDate(DateTime date) async {
    final key = dayKey(date);
    final row = await (select(entries)..where((e) => e.date.equals(key))).getSingleOrNull();
    if (row == null) return null;
    return _hydrate(row);
  }

  Stream<List<EntryRow>> watchAll() => select(entries).watch();

  /// Day-keys (local midnight) that already have an entry within the inclusive
  /// range — used by the scheduler to skip reminding on already-logged days.
  Future<Set<DateTime>> loggedDaysBetween(DateTime start, DateTime end) async {
    final rows = await (select(entries)
          ..where((e) => e.date.isBetweenValues(dayKey(start), dayKey(end))))
        .get();
    return rows.map((r) => dayKey(r.date)).toSet();
  }

  Stream<List<EntryRow>> watchBetween(DateTime start, DateTime end) {
    final q = select(entries)
      ..where((e) => e.date.isBetweenValues(dayKey(start), dayKey(end)))
      ..orderBy([(e) => OrderingTerm.asc(e.date)]);
    return q.watch();
  }

  Future<int> upsert({
    required DateTime date,
    required String severity,
    String? note,
    required List<int> tagIds,
  }) async {
    final key = dayKey(date);
    final now = DateTime.now();

    return transaction(() async {
      final existing = await (select(entries)..where((e) => e.date.equals(key))).getSingleOrNull();

      final int id;
      if (existing == null) {
        id = await into(entries).insert(
          EntriesCompanion.insert(
            date: key,
            severity: severity,
            note: Value(note),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        id = existing.id;
        await (update(entries)..where((e) => e.id.equals(id))).write(
          EntriesCompanion(
            severity: Value(severity),
            note: Value(note),
            updatedAt: Value(now),
          ),
        );
        await (delete(entryTags)..where((et) => et.entryId.equals(id))).go();
      }

      for (final tagId in tagIds) {
        await into(entryTags).insert(
          EntryTagsCompanion.insert(entryId: id, tagId: tagId),
        );
      }
      return id;
    });
  }

  Future<int> deleteByDate(DateTime date) {
    final key = dayKey(date);
    return (delete(entries)..where((e) => e.date.equals(key))).go();
  }

  Future<EntryWithTags> _hydrate(EntryRow row) async {
    final joinRows = await (select(entryTags).join([
      innerJoin(tags, tags.id.equalsExp(entryTags.tagId)),
    ])
          ..where(entryTags.entryId.equals(row.id)))
        .get();
    final tagsList = joinRows.map((r) => r.readTable(tags)).toList();
    return EntryWithTags(entry: row, tags: tagsList);
  }
}
