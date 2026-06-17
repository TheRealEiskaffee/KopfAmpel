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

  @override
  String get selectSeverity => 'Wie stark waren die Kopfschmerzen?';

  @override
  String get noteLabel => 'Notiz';

  @override
  String get noteHint => 'Optionale Anmerkung zu diesem Tag';

  @override
  String get triggersLabel => 'Trigger';

  @override
  String get medicationsLabel => 'Medikamente';

  @override
  String get doseHint => 'Dosis (optional)';

  @override
  String get addTag => 'Hinzufügen';

  @override
  String get addTagDialogTitle => 'Neuen Tag anlegen';

  @override
  String get addTagHint => 'Name';

  @override
  String get noEntry => 'Noch kein Eintrag';

  @override
  String get deleteEntryTitle => 'Eintrag löschen?';

  @override
  String get deleteEntryBody => 'Der Eintrag für diesen Tag wird gelöscht.';

  @override
  String loadFailed(String error) {
    return 'Konnte nicht geladen werden: $error';
  }
}
