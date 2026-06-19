/// Plain Dart record of localized strings the notification system needs.
/// Captured at foreground-scheduling time so background isolates and the
/// platform never have to resolve Flutter localizations.
class NotificationStrings {
  const NotificationStrings({
    required this.title,
    required this.body,
    required this.actionNone,
    required this.actionLight,
    required this.actionMedium,
    required this.actionSevere,
    required this.channelName,
    required this.channelDescription,
  });

  final String title;
  final String body;
  final String actionNone;
  final String actionLight;
  final String actionMedium;
  final String actionSevere;
  final String channelName;
  final String channelDescription;
}
