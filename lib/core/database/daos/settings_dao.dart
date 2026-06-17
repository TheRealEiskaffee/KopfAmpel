import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/app_settings.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<AppSettingsRow> get() async {
    final row = await (select(appSettings)..where((s) => s.id.equals(0))).getSingleOrNull();
    if (row != null) return row;
    // Self-heal: re-insert the singleton if the migration row went missing.
    await into(appSettings).insert(AppSettingsCompanion.insert(id: const Value(0)));
    return (select(appSettings)..where((s) => s.id.equals(0))).getSingle();
  }

  Stream<AppSettingsRow> watch() {
    return (select(appSettings)..where((s) => s.id.equals(0))).watchSingle();
  }

  Future<int> update_(AppSettingsCompanion changes) {
    return (update(appSettings)..where((s) => s.id.equals(0))).write(changes);
  }
}
