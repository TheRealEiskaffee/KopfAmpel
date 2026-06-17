# KopfAmpel

> Privates Kopfschmerz-Tagebuch für Android & iOS

**English TL;DR:** KopfAmpel is a small, private headache diary built in Flutter.
Tap green / yellow / red once a day, optionally add triggers, medication and a
note, and watch the calendar light up over time. Everything stays on the
device — no servers, no analytics, no accounts.

---

## Features

- Kalender-Ansicht mit Ampel-Tagesfarben pro Tag (grün / gelb / rot je nach Schweregrad)
- Tägliche Erinnerung mit **Ja / Nein / Ignorieren**-Buttons direkt aus dem
  Notification-Center — ein Tap reicht für den schmerzfreien Tag
- Trigger und Medikamente als verwaltbare Tags (anlegen, umbenennen, archivieren)
- Export als **JSON**, **CSV** und **PDF**
- **JSON-Import** mit Wahl zwischen *Merge* und *Replace*
- Statistik-Übersicht mit Schweregrad-Verteilung (Pie-Chart) und Top-Triggern
- Vollständig auf Deutsch und Englisch — folgt der Systemsprache
- Light / Dark / System Theme
- **Komplett offline.** Keine Server, keine Cloud, keine Analytics, kein Tracking

## Tech-Stack

- **Flutter 3.44** / Dart 3.12
- **Riverpod 2.x** (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`) für State & DI
- **Drift** (SQLite, type-safe) für lokale Persistenz
- **go_router** für die Navigation
- **table_calendar** für die Kalender-Ansicht
- **flutter_local_notifications** + **flutter_timezone** für die tägliche Erinnerung
  inkl. Action-Buttons
- **permission_handler** für Notification- und Exact-Alarm-Permissions
- **pdf** + **csv** + **file_picker** + **share_plus** für Export und Import
- **fl_chart** für die Statistik-Charts

## Setup

### Voraussetzungen

- Flutter **3.44+** (`flutter --version`)
- Für iOS: Xcode 16+ und ein Apple-Developer-Account zum Signieren
- Für Android: Android Studio + Android SDK (min SDK 23 / Android 6)

### Erstinstallation

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run            # auf einem verbundenen Gerät / Simulator
```

> `build_runner` erzeugt die Drift- und Riverpod-Generated-Files
> (`*.g.dart`, `*.drift.dart`). Nach dem Ändern von Tabellen oder
> annotierten Providern noch einmal ausführen.

### App-Icon & Splash neu erzeugen

Das App-Icon ist ein Platzhalter, der per Skript erzeugt wird (drei
Ampel-Kreise auf hellem Hintergrund). Falls du etwas änderst:

```bash
dart run tools/generate_icon.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Plattform-Hinweise

### iOS

- Notification-Action-Buttons (Ja / Nein / Ignorieren) funktionieren am
  zuverlässigsten auf einem **echten iPhone**. Der Simulator zeigt sie zwar
  an, schluckt aber gelegentlich die Button-Antworten.
- Im Hintergrund holt ein `BGAppRefreshTask` mit dem Identifier
  `app.kopfampel.notificationRefresh` neue Notifications nach. iOS entscheidet
  selbst, wann er läuft — beim App-Open wird ohnehin nachgeholt.
- Faustregel: Die App sollte **mindestens einmal pro 14 Tage geöffnet werden**,
  sonst läuft die geplante Notification-Queue trocken (iOS limitiert auf 64
  pending notifications).

### Android

- Ab **Android 13** braucht die App die `POST_NOTIFICATIONS`-Permission. Sie
  wird beim ersten Start angefragt.
- Für punktgenaue Erinnerungen wird die **Exact-Alarm-Permission**
  (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`) ebenfalls beim ersten Start
  angefragt.
- Battery-Optimizer-Whitelisting wird *nicht* erzwungen, kann aber bei
  aggressiven Herstellern (Xiaomi, Oppo, Huawei) helfen.

## Architektur

Feature-First-Layout — jedes Feature hat seinen eigenen Ordner mit
`application/` (Riverpod Notifier / Services) und `presentation/`
(Widgets, Screens).

```
lib/
├── app/                      # MaterialApp, Theme, Router
├── core/
│   ├── database/             # Drift Tabellen & Schema
│   ├── notifications/        # local notifications + scheduling
│   └── i18n/                 # generierte ARB-Klassen
├── features/
│   ├── calendar/{application,presentation}
│   ├── entry/{application,presentation}
│   ├── tags/{application,presentation}
│   ├── export/{application,presentation}
│   ├── stats/{application,presentation}
│   └── settings/{application,presentation}
├── widgets/                  # geteilte Widgets
├── l10n/                     # ARB-Quellen (de.arb, en.arb)
└── main.dart
```

Die ARB-Files unter `lib/l10n/` werden durch `flutter gen-l10n` nach
`lib/core/i18n/` generiert (siehe `l10n.yaml`).

## Build für Release

```bash
flutter build apk --release            # Android — APK
flutter build appbundle --release      # Android — Play-Store-AAB
flutter build ios --release            # iOS — Signing nötig
```

Für iOS-Release muss in Xcode ein gültiges Signing-Team eingetragen sein
(`ios/Runner.xcworkspace` → Runner → Signing & Capabilities).

## Datenschutz

KopfAmpel ist **strikt lokal**:

- Alle Daten (Einträge, Tags, Einstellungen) liegen in einer SQLite-Datenbank
  auf dem Gerät.
- **Keine Server-Verbindung.** Die App spricht mit niemandem nach Hause.
- **Keine Analytics**, keine Crash-Reporter, kein Tracking, keine Werbung.
- **Backup** läuft ausschließlich über den manuellen JSON-Export (Settings →
  Daten → Exportieren). Wer auf ein neues Gerät umzieht, importiert die
  Datei dort wieder ein.

## Roadmap / Ideen

Nur Ideen für später — keine Zusagen:

- Korrelation mit Zyklus-Tracking (manuell importierbare CSV?)
- Vergleich mit Wetterdaten (Luftdruck-API als Trigger-Hinweis)
- Apple-Health-Sync (Headache-Episoden als HKCategorySample)
- Widget für den Home-Screen mit dem heutigen Ampel-Status
- Schmerz-Lokalisation als kleine Kopf-Skizze zum Antippen

## Lizenz

Privates Projekt — derzeit keine öffentliche Lizenz. Falls das Projekt später
öffentlich werden soll, kommt vermutlich **MIT** infrage. Bis dahin gilt:
alle Rechte vorbehalten.
