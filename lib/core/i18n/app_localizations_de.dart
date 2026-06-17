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

  @override
  String get notificationTitle => 'Wie war heute?';

  @override
  String get notificationBody => 'Hattest du heute Kopfschmerzen?';

  @override
  String get notificationActionYes => 'Ja';

  @override
  String get notificationActionNo => 'Nein';

  @override
  String get notificationActionIgnore => 'Ignorieren';

  @override
  String get notificationChannelName => 'Tägliche Erinnerung';

  @override
  String get notificationChannelDescription =>
      'Erinnerung, deine Kopfschmerzen einzutragen.';

  @override
  String get reminderSection => 'Erinnerung';

  @override
  String get notificationsEnabled => 'Benachrichtigungen aktiv';

  @override
  String get notificationsEnabledDescription =>
      'Wenn aus, bekommst du keine Erinnerungen.';

  @override
  String get reminderWindow => 'Erinnerungs-Zeitfenster';

  @override
  String get reminderWindowDescription =>
      'Die tägliche Frage kommt zufällig in diesem Zeitraum.';

  @override
  String get reminderWindowFrom => 'Von';

  @override
  String get reminderWindowTo => 'Bis';

  @override
  String get reminderRepeats => 'Wiederholen, wenn ignoriert';

  @override
  String get reminderRepeatsDescription =>
      'Die App fragt erneut, wenn du nicht reagierst.';

  @override
  String get reminderRepeatDelay => 'Abstand der Wiederholungen';

  @override
  String get reminderRepeatDelayDescription =>
      'Die App wartet zufällig in diesem Bereich, bevor sie erneut fragt.';

  @override
  String get reminderMaxRepeats => 'Max. Wiederholungen pro Tag';

  @override
  String get minutesSuffix => 'Min.';

  @override
  String get dataSection => 'Daten';

  @override
  String get manageTriggers => 'Trigger verwalten';

  @override
  String get manageMedications => 'Medikamente verwalten';

  @override
  String get exportData => 'Daten exportieren';

  @override
  String get exportDataDescription => 'Als JSON, CSV oder PDF teilen.';

  @override
  String get appearanceSection => 'Darstellung';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get languageDe => 'Deutsch';

  @override
  String get languageEn => 'Englisch';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get privacySection => 'Datenschutz';

  @override
  String get privacyInfo =>
      'Alle Daten bleiben ausschließlich auf deinem Gerät. KopfAmpel sendet nichts an Server.';

  @override
  String get manageTriggersTitle => 'Trigger verwalten';

  @override
  String get manageMedicationsTitle => 'Medikamente verwalten';

  @override
  String get renameTagTitle => 'Umbenennen';

  @override
  String get deleteTagTitle => 'Löschen?';

  @override
  String get deleteTagBody =>
      'Wenn du das Tag löschst, verschwindet es auch aus Einträgen, die es nutzen.';

  @override
  String get emptyTagList => 'Noch nichts angelegt. Tippe rechts unten auf +.';
}
