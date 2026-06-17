import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tags.dart';

part 'tags_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.db);

  Future<List<TagRow>> all() => select(tags).get();

  Stream<List<TagRow>> watchByKind(String kind) {
    final q = select(tags)
      ..where((t) => t.kind.equals(kind))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch();
  }

  Future<int> create({
    required String name,
    required String kind,
    bool isCustom = true,
    String? color,
  }) {
    return into(tags).insert(
      TagsCompanion.insert(
        name: name,
        kind: kind,
        isCustom: Value(isCustom),
        color: Value(color),
      ),
    );
  }

  /// Inserts a tag only if no row with the same (name, kind) exists yet.
  Future<int?> insertIfMissing({
    required String name,
    required String kind,
    bool isCustom = false,
    String? color,
  }) async {
    final existing = await (select(tags)
          ..where((t) => t.name.equals(name) & t.kind.equals(kind)))
        .getSingleOrNull();
    if (existing != null) return null;
    return create(name: name, kind: kind, isCustom: isCustom, color: color);
  }

  Future<int> rename(int id, String name) {
    return (update(tags)..where((t) => t.id.equals(id))).write(
      TagsCompanion(name: Value(name)),
    );
  }

  Future<int> deleteById(int id) {
    return (delete(tags)..where((t) => t.id.equals(id))).go();
  }
}
