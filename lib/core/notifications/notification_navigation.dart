import 'dart:async';

/// Bridges a notification *body* tap (which opens the app) from the top-level
/// response handlers — they run outside the widget tree — to the UI, which then
/// opens that day's entry sheet. Action buttons (Yes/No/Ignore) never go through
/// here; they are handled silently in the background.
final StreamController<DateTime> _tapController =
    StreamController<DateTime>.broadcast();

Stream<DateTime> get notificationTapStream => _tapController.stream;

void emitNotificationTap(DateTime day) {
  if (!_tapController.isClosed) _tapController.add(day);
}

/// Extracts the day from a notification payload of the form `day=<ISO-8601>`.
DateTime? dayFromPayload(String? payload) {
  if (payload == null) return null;
  final match = RegExp(r'day=([0-9T:\-.]+)').firstMatch(payload);
  if (match == null) return null;
  try {
    return DateTime.parse(match.group(1)!);
  } catch (_) {
    return null;
  }
}
