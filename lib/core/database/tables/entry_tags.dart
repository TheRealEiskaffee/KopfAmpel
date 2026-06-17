import 'package:drift/drift.dart';

import 'entries.dart';
import 'tags.dart';

@DataClassName('EntryTagRow')
class EntryTags extends Table {
  IntColumn get entryId => integer().references(Entries, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId => integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  /// Free-text dose, only relevant for medication tags. Nullable for triggers.
  TextColumn get dose => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {entryId, tagId};
}
