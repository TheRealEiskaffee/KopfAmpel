/// Stable identifiers shared between the foreground scheduler and the
/// background action handler. Changing these strings would orphan any
/// notifications already scheduled on a user's device.
class NotificationIds {
  const NotificationIds._();

  static const String androidChannelId = 'kopfampel_daily';
  static const String iosCategoryId = 'kopfampel_daily';

  // Severity quick-answers. Each logs an entry of that severity for the day
  // ('none' = a headache-free day).
  static const String actionNone = 'kopfampel.action.none';
  static const String actionLight = 'kopfampel.action.light';
  static const String actionMedium = 'kopfampel.action.medium';
  static const String actionSevere = 'kopfampel.action.severe';

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
