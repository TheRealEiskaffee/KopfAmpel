/// Plain Dart record of localized strings the notification system needs.
/// Captured at foreground-scheduling time so background isolates and the
/// platform never have to resolve Flutter localizations.
class NotificationStrings {
  const NotificationStrings({
    required this.title,
    required this.body,
    required this.actionYes,
    required this.actionNo,
    required this.actionIgnore,
    required this.channelName,
    required this.channelDescription,
  });

  final String title;
  final String body;
  final String actionYes;
  final String actionNo;
  final String actionIgnore;
  final String channelName;
  final String channelDescription;
}
