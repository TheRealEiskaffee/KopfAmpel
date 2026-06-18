import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/domain/category.dart';
import '../../../core/domain/severity.dart';

enum StatsRange { sevenDays, thirtyDays, ninetyDays, allTime }

extension StatsRangeX on StatsRange {
  int? get days => switch (this) {
        StatsRange.sevenDays => 7,
        StatsRange.thirtyDays => 30,
        StatsRange.ninetyDays => 90,
        StatsRange.allTime => null,
      };
}

/// One tag's association with headache days: how often it was logged on a day
/// that had a headache, and on what share of all headache days it appeared.
/// Carries its [category] so the stats screen can label and colour it.
class TagAssociation {
  const TagAssociation({
    required this.category,
    required this.tagName,
    required this.headacheCount,
    required this.share,
  });

  final Category category;
  final String tagName;

  /// Number of headache days on which this tag was present.
  final int headacheCount;

  /// [headacheCount] / total headache days, in 0–1.
  final double share;
}

class WeekdayStat {
  const WeekdayStat({
    required this.weekday,
    required this.total,
    required this.headacheDays,
  });
  // 1 = Monday … 7 = Sunday (matches DateTime.weekday).
  final int weekday;
  final int total;
  final int headacheDays;

  double get rate => total == 0 ? 0 : headacheDays / total;
}

class ForecastDay {
  const ForecastDay({required this.date, required this.probability});
  final DateTime date;

  /// 0–1 probability that this day will be a headache day, derived from the
  /// historical headache rate on the same weekday.
  final double probability;
}

class HeadacheStats {
  const HeadacheStats({
    required this.totalEntries,
    required this.rangeDays,
    required this.countBySeverity,
    required this.headacheAssociations,
    required this.weekdayStats,
    required this.forecast,
    required this.weeklyAverageHeadacheDays,
    required this.longestFreeStreak,
    required this.currentFreeStreak,
  });

  final int totalEntries;
  final int rangeDays;
  final Map<Severity, int> countBySeverity;

  /// Tags ranked by how often they coincide with headache days, each labelled
  /// with its category. This is the "what is associated with my headaches"
  /// view.
  final List<TagAssociation> headacheAssociations;

  final List<WeekdayStat> weekdayStats;
  final List<ForecastDay> forecast;
  final double weeklyAverageHeadacheDays;
  final int longestFreeStreak;
  final int currentFreeStreak;

  int get headacheDays =>
      (countBySeverity[Severity.green] ?? 0) +
      (countBySeverity[Severity.yellow] ?? 0) +
      (countBySeverity[Severity.red] ?? 0);

  int get headacheRatePercent =>
      totalEntries == 0 ? 0 : ((headacheDays / totalEntries) * 100).round();

  /// The single strongest association — used for the headline insight line.
  TagAssociation? get topAssociation =>
      headacheAssociations.isEmpty ? null : headacheAssociations.first;

  /// Forecast requires at least this many entries before we show it; otherwise
  /// predictions are noise.
  static const int forecastMinEntries = 14;

  bool get hasForecast => totalEntries >= forecastMinEntries;
}

final statsRangeProvider = StateProvider<StatsRange>((_) => StatsRange.thirtyDays);

/// Live-updating stats. We watch the entries stream so that adding or
/// editing an entry on the calendar repaints the stats tab the moment the
/// user switches over — no manual range toggle required.
final statsProvider = StreamProvider<HeadacheStats>((ref) {
  final range = ref.watch(statsRangeProvider);
  final db = ref.watch(appDatabaseProvider);

  return db.entriesDao.watchAll().asyncMap((allEntries) async {
    final allCategories = await db.select(db.categories).get();
    final allTags = await db.select(db.tags).get();
    final allEntryTags = await db.select(db.entryTags).get();
    return _computeStats(
      range: range,
      allEntries: allEntries,
      allCategories: allCategories,
      allTags: allTags,
      allEntryTags: allEntryTags,
    );
  });
});

HeadacheStats _computeStats({
  required StatsRange range,
  required List<dynamic> allEntries,
  required List<dynamic> allCategories,
  required List<dynamic> allTags,
  required List<dynamic> allEntryTags,
}) {
  final tagById = {for (final t in allTags) t.id as int: t};
  final categoryById = {for (final c in allCategories) c.id as int: c};

  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final cutoff = range.days == null ? null : today.subtract(Duration(days: range.days! - 1));
  final entries = cutoff == null
      ? allEntries
      : allEntries.where((e) => !e.date.isBefore(cutoff)).toList();

  // Severity distribution.
  final counts = <Severity, int>{
    for (final s in Severity.values) s: 0,
  };
  for (final e in entries) {
    final s = Severity.fromString(e.severity);
    counts[s] = (counts[s] ?? 0) + 1;
  }

  // Headache-day association: count tags only on days that had a headache.
  final headacheEntryIds = entries
      .where((e) => Severity.fromString(e.severity).hasHeadache)
      .map((e) => e.id)
      .toSet();
  final totalHeadacheDays = headacheEntryIds.length;

  final tagHeadacheCount = <int, int>{};
  for (final et in allEntryTags) {
    if (!headacheEntryIds.contains(et.entryId)) continue;
    final tag = tagById[et.tagId];
    if (tag == null) continue;
    tagHeadacheCount[tag.id as int] = (tagHeadacheCount[tag.id as int] ?? 0) + 1;
  }

  Category categoryFor(int id) {
    final row = categoryById[id];
    if (row == null) {
      return Category(id: id, name: '', sortOrder: 0);
    }
    return Category(
      id: row.id as int,
      name: row.name as String,
      icon: row.icon as String?,
      color: row.color as String?,
      sortOrder: row.sortOrder as int,
      isCustom: row.isCustom as bool,
    );
  }

  final headacheAssociations = tagHeadacheCount.entries
      .map((e) {
        final tag = tagById[e.key]!;
        return TagAssociation(
          category: categoryFor(tag.categoryId as int),
          tagName: tag.name as String,
          headacheCount: e.value,
          share: totalHeadacheDays == 0 ? 0 : e.value / totalHeadacheDays,
        );
      })
      .toList()
    ..sort((a, b) {
      final byCount = b.headacheCount.compareTo(a.headacheCount);
      if (byCount != 0) return byCount;
      return a.tagName.toLowerCase().compareTo(b.tagName.toLowerCase());
    });
  final topAssociations = headacheAssociations.take(8).toList();

  // Weekday distribution (1 = Monday … 7 = Sunday).
  final byWeekday = <int, (int total, int headache)>{
    for (var wd = 1; wd <= 7; wd++) wd: (0, 0),
  };
  for (final e in entries) {
    final wd = e.date.weekday;
    final prev = byWeekday[wd]!;
    final isHeadache = Severity.fromString(e.severity).hasHeadache;
    byWeekday[wd] = (prev.$1 + 1, prev.$2 + (isHeadache ? 1 : 0));
  }
  final weekdayStats = [
    for (var wd = 1; wd <= 7; wd++)
      WeekdayStat(
        weekday: wd,
        total: byWeekday[wd]!.$1,
        headacheDays: byWeekday[wd]!.$2,
      ),
  ];

  // Forecast for the next 7 days from per-weekday historical rate.
  final forecast = [
    for (var i = 1; i <= 7; i++)
      ForecastDay(
        date: today.add(Duration(days: i)),
        probability: weekdayStats[today.add(Duration(days: i)).weekday - 1].rate,
      ),
  ];

  // Streaks across entries in the range, sorted chronologically.
  final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
  var longest = 0;
  var current = 0;
  for (final e in sorted) {
    if (Severity.fromString(e.severity).hasHeadache) {
      current = 0;
    } else {
      current++;
      if (current > longest) longest = current;
    }
  }
  // Current free streak — walk backwards through entries until we hit a headache day.
  var currentFree = 0;
  for (final e in sorted.reversed) {
    if (Severity.fromString(e.severity).hasHeadache) break;
    currentFree++;
  }

  // Weekly average — total headache days divided by weeks in the actual range.
  final rangeDays = range.days ??
      (entries.isEmpty
          ? 0
          : today.difference(entries.first.date).inDays + 1);
  final weeklyAverage = rangeDays <= 0
      ? 0.0
      : (counts.entries
              .where((e) => e.key != Severity.none)
              .fold<int>(0, (sum, e) => sum + e.value)) /
          (rangeDays / 7);

  return HeadacheStats(
    totalEntries: entries.length,
    rangeDays: rangeDays,
    countBySeverity: counts,
    headacheAssociations: topAssociations,
    weekdayStats: weekdayStats,
    forecast: forecast,
    weeklyAverageHeadacheDays: weeklyAverage,
    longestFreeStreak: longest,
    currentFreeStreak: currentFree,
  );
}
