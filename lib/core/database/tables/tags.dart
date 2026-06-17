import 'package:drift/drift.dart';

@DataClassName('TagRow')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 64)();

  /// 'trigger' | 'medication'.
  TextColumn get kind => text().withLength(min: 3, max: 16)();

  BoolColumn get isCustom => boolean().withDefault(const Constant(true))();

  /// Optional hex color (e.g. '#FFA500').
  TextColumn get color => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {name, kind},
  ];
}
