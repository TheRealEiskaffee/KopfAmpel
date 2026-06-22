import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import '../database/converters.dart';
import 'notification_ids.dart';
import 'notification_strings.dart';

/// Window of days we keep filled with pending notifications. iOS limits
/// scheduled notifications to 64; 14 days × ~4 max repeats sits well below.
const int kScheduleHorizonDays = 14;

class NotificationScheduler {
  NotificationScheduler({
    required this.plugin,
    required this.db,
  });

  final FlutterLocalNotificationsPlugin plugin;
  final AppDatabase db;

  /// Cancels all KopfAmpel notifications and reseeds the next [kScheduleHorizonDays]
  /// of randomised initial prompts based on the user's current window.
  Future<void> rescheduleHorizon({required NotificationStrings strings}) async {
    final settings = await db.settingsDao.get();
    if (!settings.notificationsEnabled) {
      await plugin.cancelAll();
      return;
    }

    await plugin.cancelAll();

    final today = dayKey(DateTime.now());
    // Prune answered/expired prompts from earlier days so the table doesn't
    // grow without bound; only today-and-forward rows are still relevant.
    await db.notificationPromptsDao.deleteOlderThan(today);
    for (var i = 0; i < kScheduleHorizonDays; i++) {
      final day = today.add(Duration(days: i));
      final scheduledFor = _randomTimeInWindow(day, settings);
      // Skip past times on day 0 — we only schedule for the future.
      if (scheduledFor.isBefore(DateTime.now())) continue;
      await _scheduleInitial(
        day: day,
        scheduledFor: scheduledFor,
        strings: strings,
      );
    }
  }

  /// Re-evaluates today's open prompts: either schedules another random
  /// retry (within the window, below the daily cap) or marks them missed.
  /// Called whenever the app comes back to foreground.
  Future<void> recoverOpenPrompts({required NotificationStrings strings}) async {
    final settings = await db.settingsDao.get();
    if (!settings.notificationsEnabled) return;

    final now = DateTime.now();
    final open = await db.notificationPromptsDao.openPromptsBefore(now);
    for (final p in open) {
      final day = p.dayKey;
      final windowEnd = DateTime(
        day.year,
        day.month,
        day.day,
        settings.windowEndMinutes ~/ 60,
        settings.windowEndMinutes % 60,
      );

      if (now.isAfter(windowEnd)) {
        await db.notificationPromptsDao.markResponded(p.id, 'missed', now);
        continue;
      }

      if (!settings.repeatEnabled) continue;
      if (p.repeatCount >= settings.maxRepeatsPerDay) continue;

      await scheduleRandomRepeat(
        day: day,
        repeatIndex: p.repeatCount + 1,
        strings: strings,
      );
      await db.notificationPromptsDao.bumpRepeat(p.id);
    }
  }

  /// Schedules a delayed retry inside the same day's window. Called from the
  /// background handler when the user did NOT tap any action.
  Future<void> scheduleRandomRepeat({
    required DateTime day,
    required int repeatIndex,
    required NotificationStrings strings,
  }) async {
    final settings = await db.settingsDao.get();
    if (!settings.repeatEnabled) return;
    if (repeatIndex >= settings.maxRepeatsPerDay) return;

    final now = DateTime.now();
    final windowEnd = DateTime(
      day.year,
      day.month,
      day.day,
      settings.windowEndMinutes ~/ 60,
      settings.windowEndMinutes % 60,
    );
    if (!now.isBefore(windowEnd)) return;

    final rng = Random();
    final minutes = settings.repeatMinDelayMin +
        rng.nextInt(settings.repeatMaxDelayMin - settings.repeatMinDelayMin + 1);
    final candidate = now.add(Duration(minutes: minutes));
    final scheduledFor = candidate.isAfter(windowEnd) ? windowEnd : candidate;

    await _scheduleNotification(
      day: day,
      scheduledFor: scheduledFor,
      repeatIndex: repeatIndex,
      strings: strings,
    );
  }

  Future<void> _scheduleInitial({
    required DateTime day,
    required DateTime scheduledFor,
    required NotificationStrings strings,
  }) {
    return _scheduleNotification(
      day: day,
      scheduledFor: scheduledFor,
      repeatIndex: 0,
      strings: strings,
    );
  }

  Future<void> _scheduleNotification({
    required DateTime day,
    required DateTime scheduledFor,
    required int repeatIndex,
    required NotificationStrings strings,
  }) async {
    final platformId = NotificationIds.platformIdFor(day, repeat: repeatIndex);
    final details = _details(strings);

    await plugin.zonedSchedule(
      id: platformId,
      title: strings.title,
      body: strings.body,
      scheduledDate: tz.TZDateTime.from(scheduledFor, tz.local),
      notificationDetails: details,
      // Inexact: a daily reminder doesn't need second-precision (the time is
      // already randomised across a multi-hour window), and inexact alarms work
      // without the "exact alarm" permission — so scheduling can't fail on
      // Android 12+ when that permission isn't granted.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'day=${day.toIso8601String()}',
    );

    // Track in DB so the background handler can find the right row when the
    // user taps an action.
    await db.notificationPromptsDao.insertPrompt(
      dayKey: day,
      scheduledFor: scheduledFor,
      platformId: platformId,
    );
  }

  NotificationDetails _details(NotificationStrings strings) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationIds.androidChannelId,
        strings.channelName,
        channelDescription: strings.channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        // Android shows at most ~3 action buttons, so we offer Kein / Leicht /
        // Stark (iOS additionally has Mittel). All handled silently in the
        // background (no showsUserInterface): each logs the day and dismisses.
        actions: [
          AndroidNotificationAction(
            NotificationIds.actionNone,
            strings.actionNone,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            NotificationIds.actionLight,
            strings.actionLight,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            NotificationIds.actionSevere,
            strings.actionSevere,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: NotificationIds.iosCategoryId,
      ),
    );
  }

  DateTime _randomTimeInWindow(DateTime day, AppSettingsRow settings) {
    // Deterministic per-day random so that re-running the scheduler does not
    // shift the user's reminder by minutes on every app open.
    final seed = day.year * 10000 + day.month * 100 + day.day;
    final rng = Random(seed);
    final start = settings.windowStartMinutes;
    final end = settings.windowEndMinutes;
    final pick = end <= start ? start : start + rng.nextInt(end - start);
    return DateTime(day.year, day.month, day.day, pick ~/ 60, pick % 60);
  }
}
