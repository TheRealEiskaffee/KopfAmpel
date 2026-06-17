import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        _DistributionCard(stats: stats),
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
