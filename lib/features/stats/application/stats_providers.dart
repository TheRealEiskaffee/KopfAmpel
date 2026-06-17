import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/domain/severity.dart';
import '../../../core/domain/tag_kind.dart';

enum StatsRange { sevenDays, thirtyDays, ninetyDays, allTime }

extension StatsRangeX on StatsRange {
  int? get days => switch (this) {
        StatsRange.sevenDays => 7,
        StatsRange.thirtyDays => 30,
        StatsRange.ninetyDays => 90,
        StatsRange.allTime => null,
      };
}

class TagCount {
  const TagCount(this.name, this.count);
  final String name;
  final int count;
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
    required this.topTriggers,
    required this.topMedications,
    required this.weekdayStats,
    required this.forecast,
    required this.weeklyAverageHeadacheDays,
    required this.longestFreeStreak,
    required this.currentFreeStreak,
  });

  final int totalEntries;
  final int rangeDays;
  final Map<Severity, int> countBySeverity;
  final List<TagCount> topTriggers;
  final List<TagCount> topMedications;
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

  /// Forecast requires at least this many entries before we show it; otherwise
  /// predictions are noise.
  static const int forecastMinEntries = 14;

  bool get hasForecast => totalEntries >= forecastMinEntries;
}

final statsRangeProvider = StateProvider<StatsRange>((_) => StatsRange.thirtyDays);

final statsProvider = FutureProvider<HeadacheStats>((ref) async {
  final range = ref.watch(statsRangeProvider);
  final db = ref.watch(appDatabaseProvider);

  final allEntries = await db.select(db.entries).get();
  final allTags = await db.select(db.tags).get();
  final allEntryTags = await db.select(db.entryTags).get();
  final tagById = {for (final t in allTags) t.id: t};

  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final cutoff = range.days == null ? null : today.subtract(Duration(days: range.days! - 1));
  final entries = cutoff == null
      ? allEntries
      : allEntries.where((e) => !e.date.isBefore(cutoff)).toList();

  final entryIds = entries.map((e) => e.id).toSet();

  // Severity distribution.
  final counts = <Severity, int>{
    for (final s in Severity.values) s: 0,
  };
  for (final e in entries) {
    final s = Severity.fromString(e.severity);
    counts[s] = (counts[s] ?? 0) + 1;
  }

  // Tag counts.
  final triggerCounts = <int, int>{};
  final medicationCounts = <int, int>{};
  for (final et in allEntryTags) {
    if (!entryIds.contains(et.entryId)) continue;
    final tag = tagById[et.tagId];
    if (tag == null) continue;
    if (tag.kind == TagKind.trigger.value) {
      triggerCounts[tag.id] = (triggerCounts[tag.id] ?? 0) + 1;
    } else if (tag.kind == TagKind.medication.value) {
      medicationCounts[tag.id] = (medicationCounts[tag.id] ?? 0) + 1;
    }
  }

  List<TagCount> topN(Map<int, int> source, int n) {
    final list = source.entries
        .map((e) => TagCount(tagById[e.key]!.name, e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list.take(n).toList();
  }

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
    topTriggers: topN(triggerCounts, 5),
    topMedications: topN(medicationCounts, 5),
    weekdayStats: weekdayStats,
    forecast: forecast,
    weeklyAverageHeadacheDays: weeklyAverage,
    longestFreeStreak: longest,
    currentFreeStreak: currentFree,
  );
});
