import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';

/// Convenience wrapper around SettingsDao for the settings UI. Keeps all
/// AppSettingsCompanion churn out of the widgets.
class SettingsActions {
  SettingsActions(this._ref);
  final Ref _ref;

  Future<void> setWindow({required int startMinutes, required int endMinutes}) {
    return _ref.read(settingsDaoProvider).update_(
          AppSettingsCompanion(
            windowStartMinutes: Value(startMinutes),
            windowEndMinutes: Value(endMinutes),
          ),
        );
  }

  Future<void> setNotificationsEnabled(bool value) {
    return _ref.read(settingsDaoProvider).update_(
          AppSettingsCompanion(notificationsEnabled: Value(value)),
        );
  }

  Future<void> setRepeatEnabled(bool value) {
    return _ref.read(settingsDaoProvider).update_(
          AppSettingsCompanion(repeatEnabled: Value(value)),
        );
  }

  Future<void> setRepeatDelay({required int minMinutes, required int maxMinutes}) {
    return _ref.read(settingsDaoProvider).update_(
          AppSettingsCompanion(
            repeatMinDelayMin: Value(minMinutes),
            repeatMaxDelayMin: Value(maxMinutes),
          ),
        );
  }

  Future<void> setMaxRepeats(int value) {
    return _ref.read(settingsDaoProvider).update_(
          AppSettingsCompanion(maxRepeatsPerDay: Value(value)),
        );
  }

  Future<void> setLocale(String? localeCode) {
    return _ref.read(settingsDaoProvider).update_(
          AppSettingsCompanion(locale: Value(localeCode)),
        );
  }

  Future<void> setThemeMode(String mode) {
    return _ref.read(settingsDaoProvider).update_(
          AppSettingsCompanion(themeMode: Value(mode)),
        );
  }
}

final settingsActionsProvider = Provider<SettingsActions>(SettingsActions.new);
