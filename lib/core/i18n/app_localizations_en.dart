// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KopfAmpel';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get statsTitle => 'Stats';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get statsPlaceholder => 'Stats will appear once you have entries.';

  @override
  String get severityNone => 'No headache';

  @override
  String get severityGreen => 'Mild';

  @override
  String get severityYellow => 'Moderate';

  @override
  String get severityRed => 'Severe';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get today => 'Today';

  @override
  String get selectSeverity => 'How bad was the headache?';

  @override
  String get noteLabel => 'Note';

  @override
  String get noteHint => 'Optional note for this day';

  @override
  String get triggersLabel => 'Triggers';

  @override
  String get medicationsLabel => 'Medications';

  @override
  String get doseHint => 'Dose (optional)';

  @override
  String get addTag => 'Add';

  @override
  String get addTagDialogTitle => 'Add new tag';

  @override
  String get addTagHint => 'Name';

  @override
  String get noEntry => 'No entry yet';

  @override
  String get deleteEntryTitle => 'Delete entry?';

  @override
  String get deleteEntryBody => 'The entry for this day will be removed.';

  @override
  String loadFailed(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get notificationTitle => 'How was today?';

  @override
  String get notificationBody => 'Did you have a headache today?';

  @override
  String get notificationActionYes => 'Yes';

  @override
  String get notificationActionNo => 'No';

  @override
  String get notificationActionIgnore => 'Ignore';

  @override
  String get notificationChannelName => 'Daily reminder';

  @override
  String get notificationChannelDescription =>
      'Reminder to log your headaches.';

  @override
  String get reminderSection => 'Reminder';

  @override
  String get notificationsEnabled => 'Notifications on';

  @override
  String get notificationsEnabledDescription =>
      'When off, you will not get reminders.';

  @override
  String get reminderWindow => 'Reminder window';

  @override
  String get reminderWindowDescription =>
      'The daily question fires at a random time inside this window.';

  @override
  String get reminderWindowFrom => 'From';

  @override
  String get reminderWindowTo => 'To';

  @override
  String get reminderRepeats => 'Repeat when ignored';

  @override
  String get reminderRepeatsDescription =>
      'The app asks again if you don\'t respond.';

  @override
  String get reminderRepeatDelay => 'Delay between repeats';

  @override
  String get reminderRepeatDelayDescription =>
      'The app waits a random amount inside this range before asking again.';

  @override
  String get reminderMaxRepeats => 'Max repeats per day';

  @override
  String get minutesSuffix => 'min';

  @override
  String get dataSection => 'Data';

  @override
  String get manageTriggers => 'Manage triggers';

  @override
  String get manageMedications => 'Manage medications';

  @override
  String get exportData => 'Export data';

  @override
  String get exportDataDescription => 'Share as JSON, CSV or PDF.';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageDe => 'German';

  @override
  String get languageEn => 'English';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get privacySection => 'Privacy';

  @override
  String get privacyInfo =>
      'All data stays on your device. KopfAmpel never sends anything to a server.';

  @override
  String get manageTriggersTitle => 'Manage triggers';

  @override
  String get manageMedicationsTitle => 'Manage medications';

  @override
  String get renameTagTitle => 'Rename';

  @override
  String get deleteTagTitle => 'Delete?';

  @override
  String get deleteTagBody =>
      'Deleting this tag also removes it from any entries that use it.';

  @override
  String get emptyTagList => 'Nothing here yet. Tap + to add one.';
}
