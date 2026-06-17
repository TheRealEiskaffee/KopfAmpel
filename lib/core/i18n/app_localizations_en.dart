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
}
