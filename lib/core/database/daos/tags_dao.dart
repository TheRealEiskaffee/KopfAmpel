import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tags.dart';

part 'tags_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagsDao extends DatabaseAccessor<AppDatabase> with _$TagsDaoMixin {
  TagsDao(super.db);

  Future<List<TagRow>> all() => select(tags).get();

  Stream<List<TagRow>> watchByCategory(int categoryId) {
    final q = select(tags)
      ..where((t) => t.categoryId.equals(categoryId))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch();
  }

  Future<int> create({
    required String name,
    required int categoryId,
    bool isCustom = true,
    String? color,
  }) {
    return into(tags).insert(
      TagsCompanion.insert(
        name: name,
        categoryId: categoryId,
        isCustom: Value(isCustom),
        color: Value(color),
      ),
    );
  }

  /// Inserts a tag only if no row with the same (name, categoryId) exists yet.
  Future<int?> insertIfMissing({
    required String name,
    required int categoryId,
    bool isCustom = false,
    String? color,
  }) async {
    final existing = await (select(tags)
          ..where((t) => t.name.equals(name) & t.categoryId.equals(categoryId)))
        .getSingleOrNull();
    if (existing != null) return null;
    return create(name: name, categoryId: categoryId, isCustom: isCustom, color: color);
  }

  Future<int> rename(int id, String name) {
    return (update(tags)..where((t) => t.id.equals(id))).write(
      TagsCompanion(name: Value(name)),
    );
  }

  Future<int> updateTag(int id, {required String name, String? color}) {
    return (update(tags)..where((t) => t.id.equals(id))).write(
      TagsCompanion(name: Value(name), color: Value(color)),
    );
  }

  Future<int> deleteById(int id) {
    return (delete(tags)..where((t) => t.id.equals(id))).go();
  }
}
