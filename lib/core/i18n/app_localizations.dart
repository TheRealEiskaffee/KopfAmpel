import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'i18n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'KopfAmpel'**
  String get appTitle;

  /// No description provided for @navCalendar.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get navCalendar;

  /// No description provided for @navStats.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get navSettings;

  /// No description provided for @calendarTitle.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get calendarTitle;

  /// No description provided for @statsTitle.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get statsTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @statsPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Statistiken erscheinen, sobald Einträge vorhanden sind.'**
  String get statsPlaceholder;

  /// No description provided for @severityNone.
  ///
  /// In de, this message translates to:
  /// **'Kein Kopfschmerz'**
  String get severityNone;

  /// No description provided for @severityGreen.
  ///
  /// In de, this message translates to:
  /// **'Leicht'**
  String get severityGreen;

  /// No description provided for @severityYellow.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get severityYellow;

  /// No description provided for @severityRed.
  ///
  /// In de, this message translates to:
  /// **'Stark'**
  String get severityRed;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @today.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get today;

  /// No description provided for @selectSeverity.
  ///
  /// In de, this message translates to:
  /// **'Wie stark waren die Kopfschmerzen?'**
  String get selectSeverity;

  /// No description provided for @noteLabel.
  ///
  /// In de, this message translates to:
  /// **'Notiz'**
  String get noteLabel;

  /// No description provided for @noteHint.
  ///
  /// In de, this message translates to:
  /// **'Optionale Anmerkung zu diesem Tag'**
  String get noteHint;

  /// No description provided for @triggersLabel.
  ///
  /// In de, this message translates to:
  /// **'Trigger'**
  String get triggersLabel;

  /// No description provided for @medicationsLabel.
  ///
  /// In de, this message translates to:
  /// **'Medikamente'**
  String get medicationsLabel;

  /// No description provided for @doseHint.
  ///
  /// In de, this message translates to:
  /// **'Dosis (optional)'**
  String get doseHint;

  /// No description provided for @addTag.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get addTag;

  /// No description provided for @addTagDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Neuen Tag anlegen'**
  String get addTagDialogTitle;

  /// No description provided for @addTagHint.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get addTagHint;

  /// No description provided for @noEntry.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Eintrag'**
  String get noEntry;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In de, this message translates to:
  /// **'Eintrag löschen?'**
  String get deleteEntryTitle;

  /// No description provided for @deleteEntryBody.
  ///
  /// In de, this message translates to:
  /// **'Der Eintrag für diesen Tag wird gelöscht.'**
  String get deleteEntryBody;

  /// No description provided for @loadFailed.
  ///
  /// In de, this message translates to:
  /// **'Konnte nicht geladen werden: {error}'**
  String loadFailed(String error);

  /// No description provided for @notificationTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie war heute?'**
  String get notificationTitle;

  /// No description provided for @notificationBody.
  ///
  /// In de, this message translates to:
  /// **'Hattest du heute Kopfschmerzen?'**
  String get notificationBody;

  /// No description provided for @notificationActionYes.
  ///
  /// In de, this message translates to:
  /// **'Ja'**
  String get notificationActionYes;

  /// No description provided for @notificationActionNo.
  ///
  /// In de, this message translates to:
  /// **'Nein'**
  String get notificationActionNo;

  /// No description provided for @notificationActionIgnore.
  ///
  /// In de, this message translates to:
  /// **'Ignorieren'**
  String get notificationActionIgnore;

  /// No description provided for @notificationChannelName.
  ///
  /// In de, this message translates to:
  /// **'Tägliche Erinnerung'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In de, this message translates to:
  /// **'Erinnerung, deine Kopfschmerzen einzutragen.'**
  String get notificationChannelDescription;

  /// No description provided for @reminderSection.
  ///
  /// In de, this message translates to:
  /// **'Erinnerung'**
  String get reminderSection;

  /// No description provided for @notificationsEnabled.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen aktiv'**
  String get notificationsEnabled;

  /// No description provided for @notificationsEnabledDescription.
  ///
  /// In de, this message translates to:
  /// **'Wenn aus, bekommst du keine Erinnerungen.'**
  String get notificationsEnabledDescription;

  /// No description provided for @reminderWindow.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungs-Zeitfenster'**
  String get reminderWindow;

  /// No description provided for @reminderWindowDescription.
  ///
  /// In de, this message translates to:
  /// **'Die tägliche Frage kommt zufällig in diesem Zeitraum.'**
  String get reminderWindowDescription;

  /// No description provided for @reminderWindowFrom.
  ///
  /// In de, this message translates to:
  /// **'Von'**
  String get reminderWindowFrom;

  /// No description provided for @reminderWindowTo.
  ///
  /// In de, this message translates to:
  /// **'Bis'**
  String get reminderWindowTo;

  /// No description provided for @reminderRepeats.
  ///
  /// In de, this message translates to:
  /// **'Wiederholen, wenn ignoriert'**
  String get reminderRepeats;

  /// No description provided for @reminderRepeatsDescription.
  ///
  /// In de, this message translates to:
  /// **'Die App fragt erneut, wenn du nicht reagierst.'**
  String get reminderRepeatsDescription;

  /// No description provided for @reminderRepeatDelay.
  ///
  /// In de, this message translates to:
  /// **'Abstand der Wiederholungen'**
  String get reminderRepeatDelay;

  /// No description provided for @reminderRepeatDelayDescription.
  ///
  /// In de, this message translates to:
  /// **'Die App wartet zufällig in diesem Bereich, bevor sie erneut fragt.'**
  String get reminderRepeatDelayDescription;

  /// No description provided for @reminderMaxRepeats.
  ///
  /// In de, this message translates to:
  /// **'Max. Wiederholungen pro Tag'**
  String get reminderMaxRepeats;

  /// No description provided for @minutesSuffix.
  ///
  /// In de, this message translates to:
  /// **'Min.'**
  String get minutesSuffix;

  /// No description provided for @dataSection.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get dataSection;

  /// No description provided for @manageTriggers.
  ///
  /// In de, this message translates to:
  /// **'Trigger verwalten'**
  String get manageTriggers;

  /// No description provided for @manageMedications.
  ///
  /// In de, this message translates to:
  /// **'Medikamente verwalten'**
  String get manageMedications;

  /// No description provided for @exportData.
  ///
  /// In de, this message translates to:
  /// **'Daten exportieren'**
  String get exportData;

  /// No description provided for @exportDataDescription.
  ///
  /// In de, this message translates to:
  /// **'Als JSON, CSV oder PDF teilen.'**
  String get exportDataDescription;

  /// No description provided for @appearanceSection.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get appearanceSection;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageDe.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get languageDe;

  /// No description provided for @languageEn.
  ///
  /// In de, this message translates to:
  /// **'Englisch'**
  String get languageEn;

  /// No description provided for @themeMode.
  ///
  /// In de, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @privacySection.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get privacySection;

  /// No description provided for @privacyInfo.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten bleiben ausschließlich auf deinem Gerät. KopfAmpel sendet nichts an Server.'**
  String get privacyInfo;

  /// No description provided for @manageTriggersTitle.
  ///
  /// In de, this message translates to:
  /// **'Trigger verwalten'**
  String get manageTriggersTitle;

  /// No description provided for @manageMedicationsTitle.
  ///
  /// In de, this message translates to:
  /// **'Medikamente verwalten'**
  String get manageMedicationsTitle;

  /// No description provided for @renameTagTitle.
  ///
  /// In de, this message translates to:
  /// **'Umbenennen'**
  String get renameTagTitle;

  /// No description provided for @deleteTagTitle.
  ///
  /// In de, this message translates to:
  /// **'Löschen?'**
  String get deleteTagTitle;

  /// No description provided for @deleteTagBody.
  ///
  /// In de, this message translates to:
  /// **'Wenn du das Tag löschst, verschwindet es auch aus Einträgen, die es nutzen.'**
  String get deleteTagBody;

  /// No description provided for @emptyTagList.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts angelegt. Tippe rechts unten auf +.'**
  String get emptyTagList;

  /// No description provided for @exportTitle.
  ///
  /// In de, this message translates to:
  /// **'Daten exportieren / importieren'**
  String get exportTitle;

  /// No description provided for @exportSection.
  ///
  /// In de, this message translates to:
  /// **'Exportieren'**
  String get exportSection;

  /// No description provided for @exportJson.
  ///
  /// In de, this message translates to:
  /// **'JSON (vollständig)'**
  String get exportJson;

  /// No description provided for @exportJsonDescription.
  ///
  /// In de, this message translates to:
  /// **'Backup für Re-Import oder andere Apps.'**
  String get exportJsonDescription;

  /// No description provided for @exportCsv.
  ///
  /// In de, this message translates to:
  /// **'CSV'**
  String get exportCsv;

  /// No description provided for @exportCsvDescription.
  ///
  /// In de, this message translates to:
  /// **'Tabellen-Format für Excel, Numbers, Google Sheets.'**
  String get exportCsvDescription;

  /// No description provided for @exportPdf.
  ///
  /// In de, this message translates to:
  /// **'PDF-Report'**
  String get exportPdf;

  /// No description provided for @exportPdfDescription.
  ///
  /// In de, this message translates to:
  /// **'Lesbarer Monats-Report, z.B. für Arztbesuche.'**
  String get exportPdfDescription;

  /// No description provided for @exportPdfAllTime.
  ///
  /// In de, this message translates to:
  /// **'Gesamter Zeitraum'**
  String get exportPdfAllTime;

  /// No description provided for @importSection.
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get importSection;

  /// No description provided for @importJson.
  ///
  /// In de, this message translates to:
  /// **'JSON-Backup importieren'**
  String get importJson;

  /// No description provided for @importJsonDescription.
  ///
  /// In de, this message translates to:
  /// **'Datei auswählen und Daten übernehmen.'**
  String get importJsonDescription;

  /// No description provided for @importModeTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie importieren?'**
  String get importModeTitle;

  /// No description provided for @importModeMerge.
  ///
  /// In de, this message translates to:
  /// **'Zusammenführen'**
  String get importModeMerge;

  /// No description provided for @importModeMergeDescription.
  ///
  /// In de, this message translates to:
  /// **'Fehlende Tage werden ergänzt, bestehende bleiben unverändert.'**
  String get importModeMergeDescription;

  /// No description provided for @importModeReplace.
  ///
  /// In de, this message translates to:
  /// **'Alles ersetzen'**
  String get importModeReplace;

  /// No description provided for @importModeReplaceDescription.
  ///
  /// In de, this message translates to:
  /// **'Vorhandene Daten werden gelöscht. Nicht rückgängig zu machen!'**
  String get importModeReplaceDescription;

  /// No description provided for @importDone.
  ///
  /// In de, this message translates to:
  /// **'Import abgeschlossen — {count, plural, =0{keine neuen Einträge} =1{1 neuer Eintrag} other{{count} neue Einträge}} hinzugefügt.'**
  String importDone(int count);

  /// No description provided for @importFailed.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen: {error}'**
  String importFailed(String error);

  /// No description provided for @exporting.
  ///
  /// In de, this message translates to:
  /// **'Wird erstellt …'**
  String get exporting;

  /// No description provided for @pdfMonthHeader.
  ///
  /// In de, this message translates to:
  /// **'Kopfschmerz-Report'**
  String get pdfMonthHeader;

  /// No description provided for @pdfStatsHeading.
  ///
  /// In de, this message translates to:
  /// **'Übersicht'**
  String get pdfStatsHeading;

  /// No description provided for @pdfStatsTotal.
  ///
  /// In de, this message translates to:
  /// **'Tage mit Eintrag'**
  String get pdfStatsTotal;

  /// No description provided for @pdfStatsGreen.
  ///
  /// In de, this message translates to:
  /// **'Leicht'**
  String get pdfStatsGreen;

  /// No description provided for @pdfStatsYellow.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get pdfStatsYellow;

  /// No description provided for @pdfStatsRed.
  ///
  /// In de, this message translates to:
  /// **'Stark'**
  String get pdfStatsRed;

  /// No description provided for @pdfStatsNone.
  ///
  /// In de, this message translates to:
  /// **'Ohne Kopfschmerz'**
  String get pdfStatsNone;

  /// No description provided for @pdfEntriesHeading.
  ///
  /// In de, this message translates to:
  /// **'Einträge'**
  String get pdfEntriesHeading;

  /// No description provided for @pdfFooter.
  ///
  /// In de, this message translates to:
  /// **'Generiert von KopfAmpel'**
  String get pdfFooter;

  /// No description provided for @statsRange7.
  ///
  /// In de, this message translates to:
  /// **'7 Tage'**
  String get statsRange7;

  /// No description provided for @statsRange30.
  ///
  /// In de, this message translates to:
  /// **'30 Tage'**
  String get statsRange30;

  /// No description provided for @statsRange90.
  ///
  /// In de, this message translates to:
  /// **'90 Tage'**
  String get statsRange90;

  /// No description provided for @statsRangeAll.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get statsRangeAll;

  /// No description provided for @statsTotalEntries.
  ///
  /// In de, this message translates to:
  /// **'Tage mit Eintrag'**
  String get statsTotalEntries;

  /// No description provided for @statsHeadacheDays.
  ///
  /// In de, this message translates to:
  /// **'Tage mit Kopfschmerzen'**
  String get statsHeadacheDays;

  /// No description provided for @statsHeadacheRate.
  ///
  /// In de, this message translates to:
  /// **'{rate}% Kopfschmerz-Tage'**
  String statsHeadacheRate(int rate);

  /// No description provided for @statsDistribution.
  ///
  /// In de, this message translates to:
  /// **'Verteilung'**
  String get statsDistribution;

  /// No description provided for @statsTopTriggers.
  ///
  /// In de, this message translates to:
  /// **'Häufigste Trigger'**
  String get statsTopTriggers;

  /// No description provided for @statsTopMedications.
  ///
  /// In de, this message translates to:
  /// **'Häufigste Medikamente'**
  String get statsTopMedications;

  /// No description provided for @statsNothing.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Daten in diesem Zeitraum.'**
  String get statsNothing;

  /// No description provided for @countSuffix.
  ///
  /// In de, this message translates to:
  /// **'× '**
  String get countSuffix;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei KopfAmpel'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In de, this message translates to:
  /// **'Halte deine Kopfschmerz-Tage einfach fest, erkenne Muster und behalte den Überblick. Alle Daten bleiben auf deinem Gerät.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingPermissionsTitle.
  ///
  /// In de, this message translates to:
  /// **'Erinnerungen'**
  String get onboardingPermissionsTitle;

  /// No description provided for @onboardingPermissionsBody.
  ///
  /// In de, this message translates to:
  /// **'Damit dich KopfAmpel einmal am Tag erinnern kann, brauchen wir die Erlaubnis für Benachrichtigungen.'**
  String get onboardingPermissionsBody;

  /// No description provided for @onboardingPermissionsLaterNote.
  ///
  /// In de, this message translates to:
  /// **'Du kannst die Erlaubnis später jederzeit in den Einstellungen deines Geräts ändern.'**
  String get onboardingPermissionsLaterNote;

  /// No description provided for @onboardingTimeTitle.
  ///
  /// In de, this message translates to:
  /// **'Wann soll erinnert werden?'**
  String get onboardingTimeTitle;

  /// No description provided for @onboardingTimeBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle ein Zeitfenster, in dem dich die App täglich erinnert. Der genaue Zeitpunkt wird zufällig in diesem Bereich gewählt.'**
  String get onboardingTimeBody;

  /// No description provided for @onboardingContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get onboardingContinue;

  /// No description provided for @onboardingAllow.
  ///
  /// In de, this message translates to:
  /// **'Erlauben'**
  String get onboardingAllow;

  /// No description provided for @onboardingLater.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get onboardingLater;

  /// No description provided for @onboardingFinish.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get onboardingFinish;

  /// No description provided for @onboardingSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get onboardingSkip;

  /// No description provided for @onboardingChoiceTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie möchtest du starten?'**
  String get onboardingChoiceTitle;

  /// No description provided for @onboardingChoiceBody.
  ///
  /// In de, this message translates to:
  /// **'Hast du Daten von einem anderen Gerät, kannst du sie importieren. Sonst geht\'s mit ein paar Einstellungen weiter.'**
  String get onboardingChoiceBody;

  /// No description provided for @onboardingChoiceImport.
  ///
  /// In de, this message translates to:
  /// **'Daten importieren'**
  String get onboardingChoiceImport;

  /// No description provided for @onboardingChoiceImportDescription.
  ///
  /// In de, this message translates to:
  /// **'Vorhandenes KopfAmpel-Backup einlesen.'**
  String get onboardingChoiceImportDescription;

  /// No description provided for @onboardingChoiceFresh.
  ///
  /// In de, this message translates to:
  /// **'Neu beginnen'**
  String get onboardingChoiceFresh;

  /// No description provided for @onboardingChoiceFreshDescription.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen jetzt einrichten und loslegen.'**
  String get onboardingChoiceFreshDescription;

  /// No description provided for @onboardingAppearanceTitle.
  ///
  /// In de, this message translates to:
  /// **'Sprache & Theme'**
  String get onboardingAppearanceTitle;

  /// No description provided for @onboardingAppearanceBody.
  ///
  /// In de, this message translates to:
  /// **'Du kannst beides später jederzeit ändern.'**
  String get onboardingAppearanceBody;

  /// No description provided for @onboardingReminderTitle.
  ///
  /// In de, this message translates to:
  /// **'Tägliche Erinnerung'**
  String get onboardingReminderTitle;

  /// No description provided for @onboardingReminderBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle, wann und wie oft KopfAmpel nachfragt.'**
  String get onboardingReminderBody;

  /// No description provided for @onboardingRepeatLabel.
  ///
  /// In de, this message translates to:
  /// **'Bei Ignorieren erneut fragen'**
  String get onboardingRepeatLabel;

  /// No description provided for @onboardingTagsTitle.
  ///
  /// In de, this message translates to:
  /// **'Trigger & Medikamente'**
  String get onboardingTagsTitle;

  /// No description provided for @onboardingTagsBody.
  ///
  /// In de, this message translates to:
  /// **'Wir haben eine Standard-Liste vorbereitet. Du kannst sie jetzt oder später anpassen.'**
  String get onboardingTagsBody;

  /// No description provided for @onboardingTagsManageTriggers.
  ///
  /// In de, this message translates to:
  /// **'Trigger anpassen'**
  String get onboardingTagsManageTriggers;

  /// No description provided for @onboardingTagsManageMedications.
  ///
  /// In de, this message translates to:
  /// **'Medikamente anpassen'**
  String get onboardingTagsManageMedications;

  /// No description provided for @onboardingDoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Alles bereit'**
  String get onboardingDoneTitle;

  /// No description provided for @onboardingDoneBody.
  ///
  /// In de, this message translates to:
  /// **'KopfAmpel ist eingerichtet.'**
  String get onboardingDoneBody;

  /// No description provided for @onboardingDoneImportedBody.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Backup eingelesen.} =1{1 Eintrag importiert.} other{{count} Einträge importiert.}} Du kannst direkt loslegen.'**
  String onboardingDoneImportedBody(int count);

  /// No description provided for @onboardingStart.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get onboardingStart;

  /// No description provided for @onboardingImportRunning.
  ///
  /// In de, this message translates to:
  /// **'Wird importiert…'**
  String get onboardingImportRunning;

  /// No description provided for @onboardingBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get onboardingBack;

  /// No description provided for @calendarFormatMonth.
  ///
  /// In de, this message translates to:
  /// **'Monat'**
  String get calendarFormatMonth;

  /// No description provided for @calendarFormatTwoWeeks.
  ///
  /// In de, this message translates to:
  /// **'2 Wochen'**
  String get calendarFormatTwoWeeks;

  /// No description provided for @calendarFormatWeek.
  ///
  /// In de, this message translates to:
  /// **'Woche'**
  String get calendarFormatWeek;

  /// No description provided for @futureDateNotAllowed.
  ///
  /// In de, this message translates to:
  /// **'Einträge in der Zukunft sind nicht möglich.'**
  String get futureDateNotAllowed;

  /// No description provided for @statsByWeekday.
  ///
  /// In de, this message translates to:
  /// **'Verteilung nach Wochentag'**
  String get statsByWeekday;

  /// No description provided for @statsByWeekdayHint.
  ///
  /// In de, this message translates to:
  /// **'Anteil Tage mit Kopfschmerzen pro Wochentag im gewählten Zeitraum.'**
  String get statsByWeekdayHint;

  /// No description provided for @statsForecastTitle.
  ///
  /// In de, this message translates to:
  /// **'Prognose nächste 7 Tage'**
  String get statsForecastTitle;

  /// No description provided for @statsForecastBody.
  ///
  /// In de, this message translates to:
  /// **'Wahrscheinlichkeit für Kopfschmerzen, basierend auf deinen bisherigen Wochentags-Daten.'**
  String get statsForecastBody;

  /// No description provided for @statsForecastNeedsMore.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht genug Daten — wir brauchen mindestens {needed} Einträge ({have} bisher).'**
  String statsForecastNeedsMore(int needed, int have);

  /// No description provided for @statsWeeklyAverage.
  ///
  /// In de, this message translates to:
  /// **'Pro Woche im Schnitt'**
  String get statsWeeklyAverage;

  /// No description provided for @statsWeeklyAverageValue.
  ///
  /// In de, this message translates to:
  /// **'{value} Tage'**
  String statsWeeklyAverageValue(String value);

  /// No description provided for @statsLongestStreak.
  ///
  /// In de, this message translates to:
  /// **'Längste kopfschmerz-freie Strähne'**
  String get statsLongestStreak;

  /// No description provided for @statsCurrentStreak.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Strähne'**
  String get statsCurrentStreak;

  /// No description provided for @statsStreakDays.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{0 Tage} =1{1 Tag} other{{count} Tage}}'**
  String statsStreakDays(int count);

  /// No description provided for @weekdayMon.
  ///
  /// In de, this message translates to:
  /// **'Mo'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In de, this message translates to:
  /// **'Di'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In de, this message translates to:
  /// **'Mi'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In de, this message translates to:
  /// **'Do'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In de, this message translates to:
  /// **'Fr'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In de, this message translates to:
  /// **'Sa'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In de, this message translates to:
  /// **'So'**
  String get weekdaySun;

  /// No description provided for @exportFailed.
  ///
  /// In de, this message translates to:
  /// **'Export fehlgeschlagen: {error}'**
  String exportFailed(String error);

  /// No description provided for @onboardingReminderDisabled.
  ///
  /// In de, this message translates to:
  /// **'Mitteilungen sind nicht erlaubt. Du kannst die Zeiten trotzdem speichern — sie greifen sobald du Mitteilungen in den iOS-Einstellungen freigibst.'**
  String get onboardingReminderDisabled;

  /// No description provided for @openSystemSettings.
  ///
  /// In de, this message translates to:
  /// **'iOS-Einstellungen öffnen'**
  String get openSystemSettings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
