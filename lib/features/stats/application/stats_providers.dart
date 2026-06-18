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

/// A tag treated as a headache risk factor: how much more likely a headache was
/// on the days the tag was logged, compared with the overall base rate.
/// Carries its [category] so the stats screen can label and colour it.
class TagAssociation {
  const TagAssociation({
    required this.category,
    required this.tagName,
    required this.daysWithTag,
    required this.headacheDaysWithTag,
    required this.probability,
    required this.lift,
    required this.typicalSeverity,
  });

  final Category category;
  final String tagName;

  /// Days in range the tag was logged on, and how many of those had a headache.
  final int daysWithTag;
  final int headacheDaysWithTag;

  /// Shrunk P(headache | tag), 0–1 (Beta-Binomial posterior mean).
  final double probability;

  /// [probability] / base rate. > 1 means the tag raises headache risk.
  final double lift;

  /// Typical severity of the headaches on this tag's headache days
  /// (Severity.none when there were none).
  final Severity typicalSeverity;
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

  /// Tags ranked by their headache risk factor (lift), strongest first.
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

  // Days that had a headache (drives both the base rate and the tag factors).
  final headacheEntryIds = entries
      .where((e) => Severity.fromString(e.severity).hasHeadache)
      .map((e) => e.id)
      .toSet();

  // Overall headache rate in the range — the base rate that the weekday
  // forecast and tag factors are measured against / pulled toward.
  final baseRate = entries.isEmpty ? 0.0 : headacheEntryIds.length / entries.length;

  // Per-tag counts within the range: on how many days a tag was logged, how
  // many of those were headache days, and the summed severity of those headache
  // days (severity weight = enum index: green 1, yellow 2, red 3).
  final severityById = <int, Severity>{
    for (final e in entries) e.id as int: Severity.fromString(e.severity),
  };
  final tagDays = <int, int>{};
  final tagHeadacheDays = <int, int>{};
  final tagSeveritySum = <int, int>{};
  for (final et in allEntryTags) {
    final eid = et.entryId as int;
    final sev = severityById[eid];
    if (sev == null) continue; // entry not in range
    final tag = tagById[et.tagId];
    if (tag == null) continue;
    final tid = tag.id as int;
    tagDays[tid] = (tagDays[tid] ?? 0) + 1;
    if (sev.hasHeadache) {
      tagHeadacheDays[tid] = (tagHeadacheDays[tid] ?? 0) + 1;
      tagSeveritySum[tid] = (tagSeveritySum[tid] ?? 0) + sev.index;
    }
  }

  Severity typicalSeverityFor(int n, int sum) {
    if (n == 0) return Severity.none;
    final avg = sum / n;
    if (avg < 1.5) return Severity.green;
    if (avg < 2.5) return Severity.yellow;
    return Severity.red;
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

  // Tag risk factors. P(headache | tag) is shrunk toward the base rate with a
  // Beta-Binomial prior (cautious on small samples); a tag needs a minimum
  // number of observations to count at all, and tags are ranked by
  // lift = P(headache | tag) / baseRate (> 1 = raises risk).
  const double tagPriorStrength = 4;
  const int minTagDays = 3;
  final associations = <TagAssociation>[];
  for (final e in tagDays.entries) {
    final n = e.value;
    if (n < minTagDays) continue;
    final h = tagHeadacheDays[e.key] ?? 0;
    final p = (h + baseRate * tagPriorStrength) / (n + tagPriorStrength);
    final lift = baseRate <= 0 ? 1.0 : p / baseRate;
    final tag = tagById[e.key]!;
    associations.add(
      TagAssociation(
        category: categoryFor(tag.categoryId as int),
        tagName: tag.name as String,
        daysWithTag: n,
        headacheDaysWithTag: h,
        probability: p,
        lift: lift,
        typicalSeverity: typicalSeverityFor(h, tagSeveritySum[e.key] ?? 0),
      ),
    );
  }
  associations.sort((a, b) {
    final byLift = b.lift.compareTo(a.lift);
    if (byLift != 0) return byLift;
    return b.daysWithTag.compareTo(a.daysWithTag);
  });
  final topAssociations = associations.take(8).toList();

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

  // Forecast for the next 7 days. A naive per-weekday rate is overconfident on
  // small samples (one headache on the only recorded Friday reads as 100%). We
  // use an empirical-Bayes (Beta-Binomial) posterior mean that shrinks each
  // weekday toward the base rate: (headacheDays + baseRate·k) / (total + k).
  // `k` acts as k pseudo-observations — a weekday only departs from the base
  // rate once it has real evidence; weekdays with no data fall back to the base
  // rate instead of 0%.
  const double forecastPriorStrength = 3;
  double weekdayProbability(int weekday) {
    final ws = weekdayStats[weekday - 1];
    return (ws.headacheDays + baseRate * forecastPriorStrength) /
        (ws.total + forecastPriorStrength);
  }

  final forecast = [
    for (var i = 1; i <= 7; i++)
      ForecastDay(
        date: today.add(Duration(days: i)),
        probability: weekdayProbability(today.add(Duration(days: i)).weekday),
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
