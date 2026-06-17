import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../database/app_database.dart';
import '../database/converters.dart';
import '../domain/prompt_response.dart';
import '../domain/severity.dart';
import 'notification_ids.dart';

/// Foreground tap handler — runs on the main isolate.
@pragma('vm:entry-point')
void onForegroundNotificationResponse(NotificationResponse response) {
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
  final payload = response.payload ?? '';
  final dayMatch = RegExp(r'day=([0-9T:\-.]+)').firstMatch(payload);
  if (dayMatch == null && platformId == null) return;

  // Drift across isolates: open a fresh handle to the same DB.
  final db = AppDatabase();
  try {
    final prompt = platformId != null
        ? await db.notificationPromptsDao.promptByPlatformId(platformId)
        : await db.notificationPromptsDao.promptForDay(
            dayKey(DateTime.parse(dayMatch!.group(1)!)),
          );
    if (prompt == null) return;
    final day = prompt.dayKey;

    final now = DateTime.now();
    PromptResponse? mapped;
    Severity? severity;

    switch (actionId) {
      case NotificationIds.actionYes:
        mapped = PromptResponse.yes;
        severity = Severity.yellow;
      case NotificationIds.actionNo:
        mapped = PromptResponse.no;
        severity = Severity.none;
      case NotificationIds.actionIgnore:
        mapped = PromptResponse.ignored;
    }

    if (mapped == null) {
      await db.notificationPromptsDao.markShown(prompt.id, now);
      return;
    }

    await db.notificationPromptsDao.markResponded(prompt.id, mapped.value, now);

    if (severity != null) {
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
      // If an entry already exists we leave it alone — the user has either
      // already curated it in the app or answered an earlier prompt today.
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('background notification handler failed: $e\n$st');
    }
  } finally {
    await db.close();
  }
}
