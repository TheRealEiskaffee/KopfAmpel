import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/ampel_colors.dart';
import '../../../core/domain/severity.dart';
import '../../../core/i18n/app_localizations.dart';
import '../application/stats_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(statsProvider);
    final range = ref.watch(statsRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SegmentedButton<StatsRange>(
              segments: [
                ButtonSegment(value: StatsRange.sevenDays, label: Text(l10n.statsRange7)),
                ButtonSegment(value: StatsRange.thirtyDays, label: Text(l10n.statsRange30)),
                ButtonSegment(value: StatsRange.ninetyDays, label: Text(l10n.statsRange90)),
                ButtonSegment(value: StatsRange.allTime, label: Text(l10n.statsRangeAll)),
              ],
              selected: {range},
              onSelectionChanged: (sel) =>
                  ref.read(statsRangeProvider.notifier).state = sel.first,
            ),
          ),
        ),
      ),
      body: statsAsync.when(
        data: (stats) => _StatsBody(stats: stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.loadFailed(e.toString()))),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});
  final HeadacheStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (stats.totalEntries == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l10n.statsNothing, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: _BigStatCard(
                label: l10n.statsTotalEntries,
                value: '${stats.totalEntries}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BigStatCard(
                label: l10n.statsHeadacheDays,
                value: '${stats.headacheDays}',
                subline: l10n.statsHeadacheRate(stats.headacheRatePercent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MetricsRow(stats: stats),
        const SizedBox(height: 8),
        _DistributionCard(stats: stats),
        const SizedBox(height: 8),
        _WeekdayCard(stats: stats),
        const SizedBox(height: 8),
        _ForecastCard(stats: stats),
        const SizedBox(height: 8),
        _TopTagsCard(
          title: l10n.statsTopTriggers,
          items: stats.topTriggers,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        _TopTagsCard(
          title: l10n.statsTopMedications,
          items: stats.topMedications,
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ],
    );
  }
}

class _BigStatCard extends StatelessWidget {
  const _BigStatCard({required this.label, required this.value, this.subline});
  final String label;
  final String value;
  final String? subline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            if (subline != null) ...[
              const SizedBox(height: 4),
              Text(subline!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.stats});
  final HeadacheStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avg = stats.weeklyAverageHeadacheDays.toStringAsFixed(
      stats.weeklyAverageHeadacheDays >= 10 ? 0 : 1,
    );
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: l10n.statsWeeklyAverage,
            value: l10n.statsWeeklyAverageValue(avg),
            icon: Icons.av_timer_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            label: l10n.statsLongestStreak,
            value: l10n.statsStreakDays(stats.longestFreeStreak),
            icon: Icons.emoji_events_outlined,
            highlight: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            label: l10n.statsCurrentStreak,
            value: l10n.statsStreakDays(stats.currentFreeStreak),
            icon: Icons.local_fire_department_outlined,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: highlight ? scheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: highlight ? scheme.onPrimaryContainer : scheme.primary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: highlight ? scheme.onPrimaryContainer : null,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: highlight ? scheme.onPrimaryContainer : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.stats});
  final HeadacheStats stats;

  Color _colorFor(Severity s) => switch (s) {
        Severity.green => AmpelColors.green,
        Severity.yellow => AmpelColors.yellow,
        Severity.red => AmpelColors.red,
        Severity.none => AmpelColors.none,
      };

  String _labelFor(BuildContext ctx, Severity s) {
    final l10n = AppLocalizations.of(ctx);
    return switch (s) {
      Severity.none => l10n.severityNone,
      Severity.green => l10n.severityGreen,
      Severity.yellow => l10n.severityYellow,
      Severity.red => l10n.severityRed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = [
      Severity.none,
      Severity.green,
      Severity.yellow,
      Severity.red,
    ].where((s) => (stats.countBySeverity[s] ?? 0) > 0).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.statsDistribution, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: [
                          for (final s in entries)
                            PieChartSectionData(
                              value: (stats.countBySeverity[s] ?? 0).toDouble(),
                              color: _colorFor(s),
                              radius: 36,
                              title: '${stats.countBySeverity[s]}',
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final s in entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _colorFor(s),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _labelFor(context, s),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text('${stats.countBySeverity[s]}'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayCard extends StatelessWidget {
  const _WeekdayCard({required this.stats});
  final HeadacheStats stats;

  String _weekdayLabel(BuildContext context, int wd) {
    final l10n = AppLocalizations.of(context);
    return switch (wd) {
      1 => l10n.weekdayMon,
      2 => l10n.weekdayTue,
      3 => l10n.weekdayWed,
      4 => l10n.weekdayThu,
      5 => l10n.weekdayFri,
      6 => l10n.weekdaySat,
      _ => l10n.weekdaySun,
    };
  }

  Color _barColor(double rate) {
    if (rate >= 0.66) return AmpelColors.red;
    if (rate >= 0.33) return AmpelColors.yellow;
    if (rate > 0) return AmpelColors.green;
    return AmpelColors.none;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxRate = stats.weekdayStats
        .map((w) => w.rate)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.statsByWeekday, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.statsByWeekdayHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final stat in stats.weekdayStats)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(_weekdayLabel(context, stat.weekday)),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: maxRate == 0 ? 0 : stat.rate / maxRate,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                        color: _barColor(stat.rate),
                        backgroundColor: _barColor(stat.rate).withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 60,
                      child: Text(
                        stat.total == 0
                            ? '—'
                            : '${(stat.rate * 100).round()}%  ${stat.headacheDays}/${stat.total}',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.stats});
  final HeadacheStats stats;

  Color _badgeColor(double prob) {
    if (prob >= 0.66) return AmpelColors.red;
    if (prob >= 0.33) return AmpelColors.yellow;
    if (prob > 0) return AmpelColors.green;
    return AmpelColors.none;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat.EEEE(locale);
    final shortFmt = DateFormat.MMMd(locale);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.statsForecastTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.statsForecastBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (!stats.hasForecast)
              Text(
                l10n.statsForecastNeedsMore(
                  HeadacheStats.forecastMinEntries,
                  stats.totalEntries,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...stats.forecast.map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(dateFmt.format(f.date)),
                      ),
                      Expanded(
                        child: Text(
                          shortFmt.format(f.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _badgeColor(f.probability),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(f.probability * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopTagsCard extends StatelessWidget {
  const _TopTagsCard({
    required this.title,
    required this.items,
    required this.color,
  });

  final String title;
  final List<TagCount> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final maxCount = items.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final tc in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        tc.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: tc.count / maxCount,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${l10n.countSuffix}${tc.count}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
