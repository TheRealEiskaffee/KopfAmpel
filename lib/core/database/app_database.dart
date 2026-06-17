import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/entries_dao.dart';
import 'daos/notification_prompts_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/tags_dao.dart';
import 'tables/app_settings.dart';
import 'tables/entries.dart';
import 'tables/entry_tags.dart';
import 'tables/notification_prompts.dart';
import 'tables/tags.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Entries, Tags, EntryTags, NotificationPrompts, AppSettings],
  daos: [EntriesDao, TagsDao, NotificationPromptsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Insert the singleton settings row.
          await into(appSettings).insert(
            AppSettingsCompanion.insert(id: const Value(0)),
          );
        },
      );

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
