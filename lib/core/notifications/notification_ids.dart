/// Stable identifiers shared between the foreground scheduler and the
/// background action handler. Changing these strings would orphan any
/// notifications already scheduled on a user's device.
class NotificationIds {
  const NotificationIds._();

  static const String androidChannelId = 'kopfampel_daily';
  static const String iosCategoryId = 'kopfampel_daily';

  static const String actionYes = 'kopfampel.action.yes';
  static const String actionNo = 'kopfampel.action.no';
  static const String actionIgnore = 'kopfampel.action.ignore';

  /// 10 platform-ids per day (1 initial + up to 9 repeats).
  static const int idsPerDay = 10;

  static int platformIdFor(DateTime day, {int repeat = 0}) {
    final epochDay = day
        .toUtc()
        .difference(DateTime.utc(1970))
        .inDays;
    return epochDay * idsPerDay + repeat;
  }

  static DateTime dayFromPlatformId(int platformId) {
    final epochDay = platformId ~/ idsPerDay;
    return DateTime.utc(1970).add(Duration(days: epochDay));
  }
}
