import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_providers.dart';
import '../i18n/app_localizations.dart';
import 'notification_scheduler.dart';
import 'notification_service.dart';
import 'notification_strings.dart';

final notificationsPluginProvider = Provider<FlutterLocalNotificationsPlugin>(
  (_) => FlutterLocalNotificationsPlugin(),
);

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(notificationsPluginProvider));
});

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(
    plugin: ref.watch(notificationsPluginProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

NotificationStrings notificationStringsOf(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return NotificationStrings(
    title: l10n.notificationTitle,
    body: l10n.notificationBody,
    actionYes: l10n.notificationActionYes,
    actionNo: l10n.notificationActionNo,
    actionIgnore: l10n.notificationActionIgnore,
    channelName: l10n.notificationChannelName,
    channelDescription: l10n.notificationChannelDescription,
  );
}
