import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import '../database/converters.dart';
import 'notification_ids.dart';
import 'notification_strings.dart';

/// Window of days we keep filled with pending notifications.
const int kScheduleHorizonDays = 14;

/// iOS only keeps the 64 most imminent pending notifications, so we stay safely
/// under that across the whole horizon (initials + repeats).
const int kMaxPendingNotifications = 56;

class NotificationScheduler {
  NotificationScheduler({
    required this.plugin,
    required this.db,
  });

  final FlutterLocalNotificationsPlugin plugin;
  final AppDatabase db;

  /// Cancels all KopfAmpel notifications and re-seeds the horizon. For each day
  /// we schedule an initial reminder plus, if repeats are enabled, several more
  /// spread across the window — all **up front**. That way an ignored or
  /// swiped-away reminder still triggers the next one even if the app is never
  /// opened (iOS can't run our code to schedule a retry on the fly). Days the
  /// user has already logged are skipped, and answering cancels a day's rest
  /// (see the background handler).
  Future<void> rescheduleHorizon({required NotificationStrings strings}) async {
    final settings = await db.settingsDao.get();
    await plugin.cancelAll();
    if (!settings.notificationsEnabled) return;

    final today = dayKey(DateTime.now());
    // Prune stale prompt rows from earlier days so the table doesn't grow.
    await db.notificationPromptsDao.deleteOlderThan(today);

    final lastDay = today.add(const Duration(days: kScheduleHorizonDays - 1));
    final loggedDays = await db.entriesDao.loggedDaysBetween(today, lastDay);

    final now = DateTime.now();
    var scheduled = 0;
    // Initials first (one per day) so every day is covered, then repeats fill
    // the remaining budget soonest-first so today and the near days get the
    // most nudges.
    final repeats = <({DateTime day, int index, DateTime at})>[];
    for (var i = 0; i < kScheduleHorizonDays; i++) {
      final day = today.add(Duration(days: i));
      if (loggedDays.contains(day)) continue;
      final times = _dayScheduleTimes(day, settings);
      for (var idx = 0; idx < times.length; idx++) {
        if (!times[idx].isAfter(now)) continue; // only future times
        if (idx == 0) {
          if (scheduled < kMaxPendingNotifications) {
            await _scheduleNotification(
              day: day,
              scheduledFor: times[idx],
              repeatIndex: idx,
              strings: strings,
            );
            scheduled++;
          }
        } else {
          repeats.add((day: day, index: idx, at: times[idx]));
        }
      }
    }

    repeats.sort((a, b) => a.at.compareTo(b.at));
    for (final r in repeats) {
      if (scheduled >= kMaxPendingNotifications) break;
      await _scheduleNotification(
        day: r.day,
        scheduledFor: r.at,
        repeatIndex: r.index,
        strings: strings,
      );
      scheduled++;
    }
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

  /// The full sequence of reminder times for [day]: an initial time plus, if
  /// repeats are enabled, follow-ups spaced by a random gap until the window
  /// ends. Seeded by the date so re-running the scheduler doesn't shift the
  /// times (it only ever fills in / prunes), capped by the per-day setting and
  /// the platform-id budget.
  List<DateTime> _dayScheduleTimes(DateTime day, AppSettingsRow settings) {
    final start = settings.windowStartMinutes;
    final end = settings.windowEndMinutes;
    if (end <= start) return [_atMinute(day, start)];

    final seed = day.year * 10000 + day.month * 100 + day.day;
    final rng = Random(seed);

    final initialMinute = start + rng.nextInt(end - start);
    final times = <DateTime>[_atMinute(day, initialMinute)];
    if (!settings.repeatEnabled) return times;

    final maxTimes = min(settings.maxRepeatsPerDay + 1, NotificationIds.idsPerDay);
    final lo = settings.repeatMinDelayMin;
    final hi = settings.repeatMaxDelayMin;
    var minute = initialMinute;
    while (times.length < maxTimes) {
      minute += lo + (hi > lo ? rng.nextInt(hi - lo + 1) : 0);
      if (minute >= end) break;
      times.add(_atMinute(day, minute));
    }
    return times;
  }

  DateTime _atMinute(DateTime day, int minuteOfDay) =>
      DateTime(day.year, day.month, day.day, minuteOfDay ~/ 60, minuteOfDay % 60);
}
