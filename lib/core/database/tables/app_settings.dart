import 'package:drift/drift.dart';

/// Sentinel for "always repeat" (no daily cap). Far above any reachable per-day
/// count, so the scheduler's `repeatCount >= maxRepeatsPerDay` check never trips
/// — repeats stay bounded by the daily reminder window.
const int kAlwaysRepeats = 999;

/// Singleton row (id = 0) holding all user-configurable preferences.
@DataClassName('AppSettingsRow')
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();

  /// Minutes since midnight (0–1439).
  IntColumn get windowStartMinutes => integer().withDefault(const Constant(18 * 60))();
  IntColumn get windowEndMinutes => integer().withDefault(const Constant(22 * 60))();

  BoolColumn get repeatEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get repeatMinDelayMin => integer().withDefault(const Constant(30))();
  IntColumn get repeatMaxDelayMin => integer().withDefault(const Constant(120))();
  IntColumn get maxRepeatsPerDay => integer().withDefault(const Constant(kAlwaysRepeats))();

  /// 'de' | 'en' | null (= follow system).
  TextColumn get locale => text().nullable()();

  /// 'light' | 'dark' | 'system'.
  TextColumn get themeMode => text().withDefault(const Constant('system'))();

  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(true))();

  BoolColumn get onboardingComplete => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
