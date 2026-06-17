import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entry.dart';
import '../domain/severity.dart';
import '../domain/tag.dart';
import '../domain/tag_kind.dart';
import 'app_database.dart';
import 'daos/entries_dao.dart';
import 'daos/notification_prompts_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/tags_dao.dart';

/// Singleton database. Disposed when the ProviderScope dies.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final entriesDaoProvider = Provider<EntriesDao>((ref) {
  return ref.watch(appDatabaseProvider).entriesDao;
});

final tagsDaoProvider = Provider<TagsDao>((ref) {
  return ref.watch(appDatabaseProvider).tagsDao;
});

final notificationPromptsDaoProvider = Provider<NotificationPromptsDao>((ref) {
  return ref.watch(appDatabaseProvider).notificationPromptsDao;
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return ref.watch(appDatabaseProvider).settingsDao;
});

final settingsProvider = StreamProvider<AppSettingsRow>((ref) {
  return ref.watch(settingsDaoProvider).watch();
});

Tag _tagFromRow(dynamic row) {
  return Tag(
    id: row.id as int,
    name: row.name as String,
    kind: TagKind.fromString(row.kind as String),
    isCustom: row.isCustom as bool,
    color: row.color as String?,
  );
}

final triggerTagsProvider = StreamProvider<List<Tag>>((ref) {
  final dao = ref.watch(tagsDaoProvider);
  return dao.watchByKind(TagKind.trigger.value).map(
        (rows) => rows.map(_tagFromRow).toList(),
      );
});

final medicationTagsProvider = StreamProvider<List<Tag>>((ref) {
  final dao = ref.watch(tagsDaoProvider);
  return dao.watchByKind(TagKind.medication.value).map(
        (rows) => rows.map(_tagFromRow).toList(),
      );
});

class EntriesRepository {
  EntriesRepository(this._dao);
  final EntriesDao _dao;

  Future<HeadacheEntry?> findByDate(DateTime date) async {
    final result = await _dao.findByDate(date);
    if (result == null) return null;
    return _toDomain(result);
  }

  Future<int> upsert({
    required DateTime date,
    required Severity severity,
    String? note,
    required List<Tag> triggers,
    required List<MedicationEntry> medications,
  }) {
    return _dao.upsert(
      date: date,
      severity: severity.value,
      note: note,
      triggerTagIds: triggers.map((t) => t.id).toList(),
      medicationTagIdsToDose: {
        for (final m in medications) m.tag.id: m.dose,
      },
    );
  }

  Future<void> deleteByDate(DateTime date) => _dao.deleteByDate(date);

  HeadacheEntry _toDomain(EntryWithTags result) {
    final triggers = <Tag>[];
    final medications = <MedicationEntry>[];
    for (final row in result.tags) {
      final tag = _tagFromRow(row);
      if (tag.kind == TagKind.medication) {
        medications.add(MedicationEntry(tag: tag, dose: result.doses[tag.id]));
      } else {
        triggers.add(tag);
      }
    }
    return HeadacheEntry(
      id: result.entry.id,
      date: result.entry.date,
      severity: Severity.fromString(result.entry.severity),
      note: result.entry.note,
      triggers: triggers,
      medications: medications,
      createdAt: result.entry.createdAt,
      updatedAt: result.entry.updatedAt,
    );
  }
}

final entriesRepositoryProvider = Provider<EntriesRepository>((ref) {
  return EntriesRepository(ref.watch(entriesDaoProvider));
});
