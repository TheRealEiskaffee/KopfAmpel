import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/categories_dao.dart';
import 'daos/entries_dao.dart';
import 'daos/notification_prompts_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/tags_dao.dart';
import 'tables/app_settings.dart';
import 'tables/categories.dart';
import 'tables/entries.dart';
import 'tables/entry_tags.dart';
import 'tables/notification_prompts.dart';
import 'tables/tags.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Entries, Categories, Tags, EntryTags, NotificationPrompts, AppSettings],
  daos: [EntriesDao, CategoriesDao, TagsDao, NotificationPromptsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedSettings();
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2 reshapes tags from a hard-coded `kind` into user-defined
          // categories. Per product decision this is a clean reset: data is
          // restored afterwards via JSON import (the importer still reads the
          // old export format). We drop every table and rebuild the schema.
          if (from < 2) {
            await m.deleteTable(entryTags.actualTableName);
            await m.deleteTable(entries.actualTableName);
            await m.deleteTable(tags.actualTableName);
            await m.deleteTable(categories.actualTableName);
            await m.deleteTable(notificationPrompts.actualTableName);
            await m.deleteTable(appSettings.actualTableName);
            await m.createAll();
            await _seedSettings();
          } else if (from < 3) {
            // v2 → v3 keeps all data; it only adopts the new "always repeat"
            // default for the daily reminder cap.
            await (update(appSettings)..where((s) => s.id.equals(0))).write(
              const AppSettingsCompanion(maxRepeatsPerDay: Value(kAlwaysRepeats)),
            );
          }
        },
        beforeOpen: (details) async {
          // Enforce foreign keys so deleting a category cascades to its tags
          // (and deleting a tag cascades to its entry links).
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _seedSettings() async {
    await into(appSettings).insert(
      AppSettingsCompanion.insert(id: const Value(0)),
    );
  }

  static QueryExecutor _open() {
    return driftDatabase(
      name: 'kopfampel',
      native: const DriftNativeOptions(
        // SQLite is in app-private storage; nothing leaves the device.
        shareAcrossIsolates: true,
      ),
    );
  }
}
