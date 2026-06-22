import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../database/app_database.dart';
import '../database/converters.dart';
import '../domain/severity.dart';
import 'notification_ids.dart';
import 'notification_navigation.dart';

/// Foreground tap handler — runs on the main isolate.
@pragma('vm:entry-point')
void onForegroundNotificationResponse(NotificationResponse response) {
  final actionId = response.actionId;
  // A tap on the notification body (no action button) opens the app — route to
  // that day's entry sheet instead of logging anything. Action buttons fall
  // through to the silent persist path below.
  if (actionId == null || actionId.isEmpty) {
    final day = dayFromPayload(response.payload);
    if (day != null) {
      emitNotificationTap(dayKey(day));
      return;
    }
  }
  _persistResponse(response);
}

/// Background handler — must be a top-level function with the vm:entry-point
/// annotation so the engine can call it from a fresh isolate.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  _persistResponse(response);
}

Future<void> _persistResponse(NotificationResponse response) async {
  final actionId = response.actionId;
  final platformId = response.id;

  // The day is what actually matters for logging an entry, and the payload
  // carries it directly — so we don't depend on the prompt row existing. The
  // payload is the source of truth (timezone-correct); the platform id is only
  // a last-ditch fallback as that mapping is lossy across timezones.
  final payload = response.payload ?? '';
  final dayMatch = RegExp(r'day=([0-9T:\-.]+)').firstMatch(payload);
  DateTime? day;
  if (dayMatch != null) {
    try {
      day = dayKey(DateTime.parse(dayMatch.group(1)!));
    } catch (_) {
      // fall through to the platform-id fallback
    }
  }
  day ??= platformId != null
      ? dayKey(NotificationIds.dayFromPlatformId(platformId))
      : null;
  if (day == null) return;

  final now = DateTime.now();
  Severity? severity;
  switch (actionId) {
    case NotificationIds.actionNone:
      severity = Severity.none;
    case NotificationIds.actionLight:
      severity = Severity.green;
    case NotificationIds.actionMedium:
      severity = Severity.yellow;
    case NotificationIds.actionSevere:
      severity = Severity.red;
  }

  // Drift across isolates: open a fresh handle to the same DB.
  final db = AppDatabase();
  try {
    // Best-effort bookkeeping on the scheduled-prompt row. It may be missing
    // (e.g. pruned), so a failure here must never block writing the entry.
    final prompt = platformId != null
        ? await db.notificationPromptsDao.promptByPlatformId(platformId)
        : await db.notificationPromptsDao.promptForDay(day);
    if (prompt != null) {
      if (severity == null) {
        await db.notificationPromptsDao.markShown(prompt.id, now);
      } else {
        await db.notificationPromptsDao
            .markResponded(prompt.id, severity.value, now);
      }
    }

    // Not one of our severity actions — nothing to log.
    if (severity == null) return;

    // Log the day at the chosen severity ('none' = a headache-free day). If an
    // entry already exists we leave it alone — the user has either curated it in
    // the app or answered an earlier prompt today.
    final existing = await db.entriesDao.findByDate(day);
    if (existing == null) {
      await db.into(db.entries).insert(
            EntriesCompanion.insert(
              date: day,
              severity: severity.value,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('background notification handler failed: $e\n$st');
    }
  } finally {
    await db.close();
  }

  // The user answered, so silence the rest of today's reminders. (The next
  // reschedule also skips logged days, but cancelling now stops any remaining
  // pre-scheduled reminder from firing before the app is reopened.)
  if (severity != null) {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      for (var r = 0; r < NotificationIds.idsPerDay; r++) {
        await plugin.cancel(id: NotificationIds.platformIdFor(day, repeat: r));
      }
    } catch (_) {
      // Best-effort — never let cancellation failures surface.
    }
  }
}
