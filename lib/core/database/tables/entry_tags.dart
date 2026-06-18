import 'package:drift/drift.dart';

import 'entries.dart';
import 'tags.dart';

@DataClassName('EntryTagRow')
class EntryTags extends Table {
  IntColumn get entryId => integer().references(Entries, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId => integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {entryId, tagId};
}
