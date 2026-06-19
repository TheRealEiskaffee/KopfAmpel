import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/theme/ampel_colors.dart';
import '../../../app/theme/category_icons.dart';
import '../../../app/theme/tag_palette.dart';
import '../../../core/bootstrap.dart';
import '../../../core/database/converters.dart' hide isSameDay;
import '../../../core/database/database_providers.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedDay = dayKey(_focusedDay);
  }

  void _handleDayTap(DateTime day, Map<DateTime, Severity> severityByDay) {
    final today = dayKey(DateTime.now());
    final key = dayKey(day);
    if (key.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(AppLocalizations.of(context).futureDateNotAllowed),
        ),
      );
      return;
    }
    setState(() {
      _selectedDay = key;
      _focusedDay = day;
    });
    // Only days without an entry open the editor directly. Days that already
    // have one show their details in the panel below — the user taps "Edit"
    // there to change them.
    if (!severityByDay.containsKey(key)) {
      DayDetailSheet.show(context, key);
    }
  }

  Future<void> _pickMonth() async {
    final picked = await _MonthYearPickerSheet.show(context, _focusedDay);
    if (picked != null && mounted) {
      setState(() => _focusedDay = picked);
    }
  }

  void _goToday() {
    final today = dayKey(DateTime.now());
    setState(() {
      _focusedDay = today;
      _selectedDay = today;
    });
  }

  void _shiftMonth(int delta) {
    final m = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
    if (m.isBefore(DateTime(2020, 1, 1)) || m.isAfter(DateTime(2100, 12, 1))) {
      return;
    }
    setState(() => _focusedDay = m);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    // Trigger one-shot startup work (seed default tags). We don't need the value.
    ref.watch(bootstrapProvider);

    // A notification body tap routes here with the day to open. Clear it first
    // so it fires once, then open that day's entry sheet.
    ref.listen<DateTime?>(pendingNotificationDayProvider, (prev, next) {
      if (next == null) return;
      ref.read(pendingNotificationDayProvider.notifier).state = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final key = dayKey(next);
        setState(() {
          _selectedDay = key;
          _focusedDay = next;
        });
        DayDetailSheet.show(context, key);
      });
    });

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
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _shiftMonth(-1),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _pickMonth,
                          child: Center(
                            child: Text(
                              DateFormat.yMMMM(locale).format(_focusedDay),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.home_outlined),
                        tooltip: l10n.today,
                        onPressed: _goToday,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _shiftMonth(1),
                      ),
                    ],
                  ),
                  TableCalendar(
                locale: locale,
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2100),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) =>
                    _selectedDay != null && isSameDay(d, _selectedDay!),
                calendarFormat: CalendarFormat.month,
                headerVisible: false,
                startingDayOfWeek: StartingDayOfWeek.monday,
                onDaySelected: (selected, focused) =>
                    _handleDayTap(selected, severityByDay),
                onPageChanged: (focused) => setState(() => _focusedDay = focused),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (ctx, day, focused) => _DayCell(
                    day: day,
                    severity: severityByDay[dayKey(day)],
                    isFuture: dayKey(day).isAfter(dayKey(DateTime.now())),
                  ),
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
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _DaySummary(selectedDay: _selectedDay)),
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
    this.isFuture = false,
  });

  final DateTime day;
  final Severity? severity;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (severity) {
      Severity.green => AmpelColors.green,
      Severity.yellow => AmpelColors.yellow,
      Severity.red => AmpelColors.red,
      // A logged "no headache" day gets a soft grey fill so it reads as
      // recorded — not forgotten. Days with no entry stay transparent (null).
      Severity.none => AmpelColors.none,
      null => null,
    };

    final bg = color?.withValues(alpha: 0.22) ?? Colors.transparent;
    final borderColor = isSelected
        ? scheme.primary
        : isToday
            ? scheme.primary.withValues(alpha: 0.4)
            : Colors.transparent;

    final cell = Container(
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

    if (!isFuture) return cell;
    return Opacity(opacity: 0.35, child: cell);
  }
}

/// Lower panel: shows the selected day's entry (severity + tags grouped by
/// category) with an edit affordance, or an empty state for days without one.
class _DaySummary extends ConsumerWidget {
  const _DaySummary({required this.selectedDay});

  final DateTime? selectedDay;

  (Color, String) _severity(BuildContext context, Severity s) {
    final l10n = AppLocalizations.of(context);
    return switch (s) {
      Severity.none => (AmpelColors.none, l10n.severityNone),
      Severity.green => (AmpelColors.green, l10n.severityGreen),
      Severity.yellow => (AmpelColors.yellow, l10n.severityYellow),
      Severity.red => (AmpelColors.red, l10n.severityRed),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedDay == null) return const SizedBox.shrink();
    final day = selectedDay!;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat.yMMMMEEEEd(locale).format(day);

    final entryAsync = ref.watch(entryByDayProvider(day));
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];

    return entryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(l10n.loadFailed(e.toString())),
      ),
      data: (entry) {
        if (entry == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(
                  l10n.noEntry,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  onPressed: () => DayDetailSheet.show(context, day),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addEntry),
                ),
              ],
            ),
          );
        }

        final (sevColor, sevLabel) = _severity(context, entry.severity);
        final namesByCategory = <int, List<String>>{};
        for (final t in entry.tags) {
          namesByCategory.putIfAbsent(t.categoryId, () => []).add(t.name);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => DayDetailSheet.show(context, day),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.editEntry),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: sevColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(sevLabel, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              if (entry.note != null && entry.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(entry.note!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              for (final cat in categories)
                if (namesByCategory[cat.id] != null &&
                    namesByCategory[cat.id]!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          iconForKey(cat.icon),
                          size: 15,
                          color: cat.displayColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${cat.name}: ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: (namesByCategory[cat.id]!..sort()).join(', '),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
            ],
          ),
        );
      },
    );
  }
}

/// Tap-the-header month/year picker. Shows a grid of months; tapping the year
/// label switches to a grid of years. Returns the chosen month (1st of month),
/// or null if dismissed.
class _MonthYearPickerSheet extends StatefulWidget {
  const _MonthYearPickerSheet({required this.initial});

  final DateTime initial;

  static const int minYear = 2020;
  static const int maxYear = 2100;

  static Future<DateTime?> show(BuildContext context, DateTime initial) {
    return showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (_) => _MonthYearPickerSheet(initial: initial),
    );
  }

  @override
  State<_MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<_MonthYearPickerSheet> {
  late int _year;
  late int _yearPageStart;
  bool _yearMode = false;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _yearPageStart = _year - (_year % 12);
  }

  void _step(int dir) {
    setState(() {
      if (_yearMode) {
        _yearPageStart = (_yearPageStart + dir * 12)
            .clamp(_MonthYearPickerSheet.minYear, _MonthYearPickerSheet.maxYear - 11)
            .toInt();
      } else {
        _year = (_year + dir)
            .clamp(_MonthYearPickerSheet.minYear, _MonthYearPickerSheet.maxYear)
            .toInt();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).viewPadding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _step(-1),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _yearMode = !_yearMode),
                  child: Text(
                    _yearMode
                        ? '$_yearPageStart – ${_yearPageStart + 11}'
                        : '$_year',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _step(1),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 2.1,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: _yearMode ? _yearTiles() : _monthTiles(locale),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _monthTiles(String locale) {
    return [
      for (var m = 1; m <= 12; m++)
        _GridTile(
          label: DateFormat.MMM(locale).format(DateTime(_year, m)),
          selected: _year == widget.initial.year && m == widget.initial.month,
          onTap: () => Navigator.of(context).pop(DateTime(_year, m, 1)),
        ),
    ];
  }

  List<Widget> _yearTiles() {
    return [
      for (var i = 0; i < 12; i++)
        if (_yearPageStart + i <= _MonthYearPickerSheet.maxYear)
          _GridTile(
            label: '${_yearPageStart + i}',
            selected: _yearPageStart + i == _year,
            onTap: () => setState(() {
              _year = _yearPageStart + i;
              _yearMode = false;
            }),
          ),
    ];
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
