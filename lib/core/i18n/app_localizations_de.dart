// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'KopfAmpel';

  @override
  String get navCalendar => 'Kalender';

  @override
  String get navStats => 'Statistik';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get calendarTitle => 'Kalender';

  @override
  String get statsTitle => 'Statistik';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get statsPlaceholder =>
      'Statistiken erscheinen, sobald Einträge vorhanden sind.';

  @override
  String get settingsPlaceholder =>
      'Hier kannst du später Erinnerungen, Trigger und Export einstellen.';

  @override
  String get severityNone => 'Kein Kopfschmerz';

  @override
  String get severityGreen => 'Leicht';

  @override
  String get severityYellow => 'Mittel';

  @override
  String get severityRed => 'Stark';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get today => 'Heute';
}
