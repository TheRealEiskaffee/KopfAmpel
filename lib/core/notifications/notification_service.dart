import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'background_handler.dart';
import 'notification_ids.dart';
import 'notification_strings.dart';

class NotificationService {
  NotificationService(this.plugin);

  final FlutterLocalNotificationsPlugin plugin;

  bool _initialized = false;

  Future<void> init({required NotificationStrings strings}) async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      // Fall back to UTC if the platform lookup fails — better than crashing.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          NotificationIds.iosCategoryId,
          actions: [
            DarwinNotificationAction.plain(
              NotificationIds.actionYes,
              strings.actionYes,
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              NotificationIds.actionNo,
              strings.actionNo,
            ),
            DarwinNotificationAction.plain(
              NotificationIds.actionIgnore,
              strings.actionIgnore,
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
          options: {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
        ),
      ],
    );

    await plugin.initialize(
      InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: onForegroundNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          NotificationIds.androidChannelId,
          strings.channelName,
          description: strings.channelDescription,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final notifStatus = await Permission.notification.request();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }
    return notifStatus.isGranted;
  }
}
