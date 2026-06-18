import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<List<CategoryRow>> all() => select(categories).get();

  Stream<List<CategoryRow>> watchAll() {
    final q = select(categories)
      ..orderBy([(c) => OrderingTerm.asc(c.name.collate(Collate.noCase))]);
    return q.watch();
  }

  Future<int> create({
    required String name,
    String? icon,
    String? color,
    int sortOrder = 0,
    bool isCustom = true,
  }) {
    return into(categories).insert(
      CategoriesCompanion.insert(
        name: name,
        icon: Value(icon),
        color: Value(color),
        sortOrder: Value(sortOrder),
        isCustom: Value(isCustom),
      ),
    );
  }

  /// Inserts a category only if no row with the same name exists yet; returns
  /// the existing or newly-created id.
  Future<int> ensure({
    required String name,
    String? icon,
    String? color,
    int sortOrder = 0,
    bool isCustom = true,
  }) async {
    final existing =
        await (select(categories)..where((c) => c.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing.id;
    return create(
      name: name,
      icon: icon,
      color: color,
      sortOrder: sortOrder,
      isCustom: isCustom,
    );
  }

  Future<int> updateCategory(
    int id, {
    required String name,
    String? icon,
    String? color,
  }) {
    return (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        icon: Value(icon),
        color: Value(color),
      ),
    );
  }

  Future<int> deleteById(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  /// Next free sort order (max + 1), so a freshly added category lands last.
  Future<int> nextSortOrder() async {
    final rows = await select(categories).get();
    if (rows.isEmpty) return 0;
    return rows.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }
}
