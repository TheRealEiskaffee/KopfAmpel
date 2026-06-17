import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/theme/ampel_colors.dart';
import '../../../core/bootstrap.dart';
import '../../../core/database/converters.dart' hide isSameDay;
import '../../../core/domain/severity.dart';
import '../../../core/i18n/app_localizations.dart';
import '../application/calendar_providers.dart';
import 'day_detail_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = dayKey(_focusedDay);
  }

  void _openDetail(DateTime day) {
    setState(() {
      _selectedDay = dayKey(day);
      _focusedDay = day;
    });
    DayDetailSheet.show(context, dayKey(day));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    // Trigger one-shot startup work (seed default tags). We don't need the value.
    ref.watch(bootstrapProvider);

    final severityAsync = ref.watch(monthSeverityProvider(_focusedDay));
    final severityByDay = severityAsync.maybeWhen(
      data: (m) => m,
      orElse: () => const <DateTime, Severity>{},
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarTitle)),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                locale: locale,
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2100),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) =>
                    _selectedDay != null && isSameDay(d, _selectedDay!),
                calendarFormat: _format,
                onFormatChanged: (f) => setState(() => _format = f),
                startingDayOfWeek: StartingDayOfWeek.monday,
                onDaySelected: (selected, focused) => _openDetail(selected),
                onPageChanged: (focused) => setState(() => _focusedDay = focused),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (ctx, day, focused) =>
                      _DayCell(day: day, severity: severityByDay[dayKey(day)]),
                  todayBuilder: (ctx, day, focused) => _DayCell(
                    day: day,
                    severity: severityByDay[dayKey(day)],
                    isToday: true,
                  ),
                  selectedBuilder: (ctx, day, focused) => _DayCell(
                    day: day,
                    severity: severityByDay[dayKey(day)],
                    isSelected: true,
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: _Legend()),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    this.severity,
    this.isToday = false,
    this.isSelected = false,
  });

  final DateTime day;
  final Severity? severity;
  final bool isToday;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (severity) {
      Severity.green => AmpelColors.green,
      Severity.yellow => AmpelColors.yellow,
      Severity.red => AmpelColors.red,
      Severity.none || null => null,
    };

    final bg = color?.withValues(alpha: 0.22) ?? Colors.transparent;
    final borderColor = isSelected
        ? scheme.primary
        : isToday
            ? scheme.primary.withValues(alpha: 0.4)
            : Colors.transparent;

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: color != null ? scheme.onSurface : null,
          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <(Color, String)>[
      (AmpelColors.green, l10n.severityGreen),
      (AmpelColors.yellow, l10n.severityYellow),
      (AmpelColors.red, l10n.severityRed),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.selectSeverity, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final (c, label) in items)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(label),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
