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

  @override
  String get exportTitle => 'Daten exportieren / importieren';

  @override
  String get exportSection => 'Exportieren';

  @override
  String get exportJson => 'JSON (vollständig)';

  @override
  String get exportJsonDescription => 'Backup für Re-Import oder andere Apps.';

  @override
  String get exportCsv => 'CSV';

  @override
  String get exportCsvDescription =>
      'Tabellen-Format für Excel, Numbers, Google Sheets.';

  @override
  String get exportPdf => 'PDF-Report';

  @override
  String get exportPdfDescription =>
      'Lesbarer Monats-Report, z.B. für Arztbesuche.';

  @override
  String get exportPdfAllTime => 'Gesamter Zeitraum';

  @override
  String get importSection => 'Importieren';

  @override
  String get importJson => 'JSON-Backup importieren';

  @override
  String get importJsonDescription => 'Datei auswählen und Daten übernehmen.';

  @override
  String get importModeTitle => 'Wie importieren?';

  @override
  String get importModeMerge => 'Zusammenführen';

  @override
  String get importModeMergeDescription =>
      'Fehlende Tage werden ergänzt, bestehende bleiben unverändert.';

  @override
  String get importModeReplace => 'Alles ersetzen';

  @override
  String get importModeReplaceDescription =>
      'Vorhandene Daten werden gelöscht. Nicht rückgängig zu machen!';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Einträge',
      one: '1 neuer Eintrag',
      zero: 'keine neuen Einträge',
    );
    return 'Import abgeschlossen — $_temp0 hinzugefügt.';
  }

  @override
  String importFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get exporting => 'Wird erstellt …';

  @override
  String get pdfMonthHeader => 'Kopfschmerz-Report';

  @override
  String get pdfStatsHeading => 'Übersicht';

  @override
  String get pdfStatsTotal => 'Tage mit Eintrag';

  @override
  String get pdfStatsGreen => 'Leicht';

  @override
  String get pdfStatsYellow => 'Mittel';

  @override
  String get pdfStatsRed => 'Stark';

  @override
  String get pdfStatsNone => 'Ohne Kopfschmerz';

  @override
  String get pdfEntriesHeading => 'Einträge';

  @override
  String get pdfFooter => 'Generiert von KopfAmpel';

  @override
  String get statsRange7 => '7 Tage';

  @override
  String get statsRange30 => '30 Tage';

  @override
  String get statsRange90 => '90 Tage';

  @override
  String get statsRangeAll => 'Gesamt';

  @override
  String get statsTotalEntries => 'Tage mit Eintrag';

  @override
  String get statsHeadacheDays => 'Tage mit Kopfschmerzen';

  @override
  String statsHeadacheRate(int rate) {
    return '$rate% Kopfschmerz-Tage';
  }

  @override
  String get statsDistribution => 'Verteilung';

  @override
  String get statsTopTriggers => 'Häufigste Trigger';

  @override
  String get statsTopMedications => 'Häufigste Medikamente';

  @override
  String get statsNothing => 'Noch keine Daten in diesem Zeitraum.';

  @override
  String get countSuffix => '× ';

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei KopfAmpel';

  @override
  String get onboardingWelcomeBody =>
      'Halte deine Kopfschmerz-Tage einfach fest, erkenne Muster und behalte den Überblick. Alle Daten bleiben auf deinem Gerät.';

  @override
  String get onboardingPermissionsTitle => 'Erinnerungen';

  @override
  String get onboardingPermissionsBody =>
      'Damit dich KopfAmpel einmal am Tag erinnern kann, brauchen wir die Erlaubnis für Benachrichtigungen.';

  @override
  String get onboardingPermissionsLaterNote =>
      'Du kannst die Erlaubnis später jederzeit in den Einstellungen deines Geräts ändern.';

  @override
  String get onboardingTimeTitle => 'Wann soll erinnert werden?';

  @override
  String get onboardingTimeBody =>
      'Wähle ein Zeitfenster, in dem dich die App täglich erinnert. Der genaue Zeitpunkt wird zufällig in diesem Bereich gewählt.';

  @override
  String get onboardingContinue => 'Weiter';

  @override
  String get onboardingAllow => 'Erlauben';

  @override
  String get onboardingLater => 'Später';

  @override
  String get onboardingFinish => 'Fertig';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingChoiceTitle => 'Wie möchtest du starten?';

  @override
  String get onboardingChoiceBody =>
      'Hast du Daten von einem anderen Gerät, kannst du sie importieren. Sonst geht\'s mit ein paar Einstellungen weiter.';

  @override
  String get onboardingChoiceImport => 'Daten importieren';

  @override
  String get onboardingChoiceImportDescription =>
      'Vorhandenes KopfAmpel-Backup einlesen.';

  @override
  String get onboardingChoiceFresh => 'Neu beginnen';

  @override
  String get onboardingChoiceFreshDescription =>
      'Einstellungen jetzt einrichten und loslegen.';

  @override
  String get onboardingAppearanceTitle => 'Sprache & Theme';

  @override
  String get onboardingAppearanceBody =>
      'Du kannst beides später jederzeit ändern.';

  @override
  String get onboardingReminderTitle => 'Tägliche Erinnerung';

  @override
  String get onboardingReminderBody =>
      'Wähle, wann und wie oft KopfAmpel nachfragt.';

  @override
  String get onboardingRepeatLabel => 'Bei Ignorieren erneut fragen';

  @override
  String get onboardingTagsTitle => 'Trigger & Medikamente';

  @override
  String get onboardingTagsBody =>
      'Wir haben eine Standard-Liste vorbereitet. Du kannst sie jetzt oder später anpassen.';

  @override
  String get onboardingTagsManageTriggers => 'Trigger anpassen';

  @override
  String get onboardingTagsManageMedications => 'Medikamente anpassen';

  @override
  String get onboardingDoneTitle => 'Alles bereit';

  @override
  String get onboardingDoneBody => 'KopfAmpel ist eingerichtet.';

  @override
  String onboardingDoneImportedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge importiert.',
      one: '1 Eintrag importiert.',
      zero: 'Backup eingelesen.',
    );
    return '$_temp0 Du kannst direkt loslegen.';
  }

  @override
  String get onboardingStart => 'Los geht\'s';

  @override
  String get onboardingImportRunning => 'Wird importiert…';

  @override
  String get onboardingBack => 'Zurück';

  @override
  String get calendarFormatMonth => 'Monat';

  @override
  String get calendarFormatTwoWeeks => '2 Wochen';

  @override
  String get calendarFormatWeek => 'Woche';

  @override
  String get futureDateNotAllowed =>
      'Einträge in der Zukunft sind nicht möglich.';

  @override
  String get statsByWeekday => 'Verteilung nach Wochentag';

  @override
  String get statsByWeekdayHint =>
      'Anteil Tage mit Kopfschmerzen pro Wochentag im gewählten Zeitraum.';

  @override
  String get statsForecastTitle => 'Prognose nächste 7 Tage';

  @override
  String get statsForecastBody =>
      'Wahrscheinlichkeit für Kopfschmerzen, basierend auf deinen bisherigen Wochentags-Daten.';

  @override
  String statsForecastNeedsMore(int needed, int have) {
    return 'Noch nicht genug Daten — wir brauchen mindestens $needed Einträge ($have bisher).';
  }

  @override
  String get statsWeeklyAverage => 'Pro Woche im Schnitt';

  @override
  String statsWeeklyAverageValue(String value) {
    return '$value Tage';
  }

  @override
  String get statsLongestStreak => 'Längste kopfschmerz-freie Strähne';

  @override
  String get statsCurrentStreak => 'Aktuelle Strähne';

  @override
  String statsStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
      zero: '0 Tage',
    );
    return '$_temp0';
  }

  @override
  String get weekdayMon => 'Mo';

  @override
  String get weekdayTue => 'Di';

  @override
  String get weekdayWed => 'Mi';

  @override
  String get weekdayThu => 'Do';

  @override
  String get weekdayFri => 'Fr';

  @override
  String get weekdaySat => 'Sa';

  @override
  String get weekdaySun => 'So';

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get onboardingReminderDisabled =>
      'Mitteilungen sind nicht erlaubt. Du kannst die Zeiten trotzdem speichern — sie greifen sobald du Mitteilungen in den iOS-Einstellungen freigibst.';

  @override
  String get openSystemSettings => 'iOS-Einstellungen öffnen';

  @override
  String get tagGroupCustom => 'Eigene';

  @override
  String get tagGroupBuiltIn => 'Standard';
}
