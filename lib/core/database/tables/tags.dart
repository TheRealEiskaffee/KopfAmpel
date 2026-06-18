import 'package:drift/drift.dart';

import 'categories.dart';

@DataClassName('TagRow')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 64)();

  /// The category this tag belongs to. Deleting a category removes its tags.
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();

  BoolColumn get isCustom => boolean().withDefault(const Constant(true))();

  /// Optional hex color (e.g. '#FFA500').
  TextColumn get color => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {name, categoryId},
  ];
}
