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
  String get settingsPlaceholder =>
      'You will configure reminders, triggers and export here.';

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
}
