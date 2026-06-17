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

class HeadacheStats {
  const HeadacheStats({
    required this.totalEntries,
    required this.countBySeverity,
    required this.topTriggers,
    required this.topMedications,
  });

  final int totalEntries;
  final Map<Severity, int> countBySeverity;
  final List<TagCount> topTriggers;
  final List<TagCount> topMedications;

  int get headacheDays =>
      (countBySeverity[Severity.green] ?? 0) +
      (countBySeverity[Severity.yellow] ?? 0) +
      (countBySeverity[Severity.red] ?? 0);

  int get headacheRatePercent =>
      totalEntries == 0 ? 0 : ((headacheDays / totalEntries) * 100).round();
}

final statsRangeProvider = StateProvider<StatsRange>((_) => StatsRange.thirtyDays);

final statsProvider = FutureProvider<HeadacheStats>((ref) async {
  final range = ref.watch(statsRangeProvider);
  final db = ref.watch(appDatabaseProvider);

  final allEntries = await db.select(db.entries).get();
  final allTags = await db.select(db.tags).get();
  final allEntryTags = await db.select(db.entryTags).get();
  final tagById = {for (final t in allTags) t.id: t};

  final cutoff = range.days == null
      ? null
      : DateTime.now().subtract(Duration(days: range.days! - 1));

  final entries = cutoff == null
      ? allEntries
      : allEntries
          .where((e) => !e.date.isBefore(
                DateTime(cutoff.year, cutoff.month, cutoff.day),
              ))
          .toList();

  final entryIds = entries.map((e) => e.id).toSet();

  final counts = <Severity, int>{
    for (final s in Severity.values) s: 0,
  };
  for (final e in entries) {
    final s = Severity.fromString(e.severity);
    counts[s] = (counts[s] ?? 0) + 1;
  }

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

  return HeadacheStats(
    totalEntries: entries.length,
    countBySeverity: counts,
    topTriggers: topN(triggerCounts, 5),
    topMedications: topN(medicationCounts, 5),
  );
});
