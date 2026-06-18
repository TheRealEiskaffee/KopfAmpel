import 'package:drift/drift.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 64)();

  /// Optional icon key into [kCategoryIcons]. Null falls back to a default icon.
  TextColumn get icon => text().nullable()();

  /// Optional hex color (e.g. '#FFA500').
  TextColumn get color => text().nullable()();

  /// Display order, ascending. Lower numbers come first.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  BoolColumn get isCustom => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {name},
  ];
}
