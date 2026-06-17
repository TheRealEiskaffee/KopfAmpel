import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/domain/tag_kind.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../export/presentation/export_screen.dart';
import '../application/settings_actions.dart';
import 'tag_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: settingsAsync.when(
        data: (s) => _SettingsBody(settings: s),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.loadFailed(e.toString()))),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});
  final AppSettingsRow settings;

  Future<void> _refreshNotifications(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    final strings = notificationStringsOf(context);
    await ref.read(notificationSchedulerProvider).rescheduleHorizon(strings: strings);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(settingsActionsProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _Section(
          title: l10n.reminderSection,
          children: [
            SwitchListTile.adaptive(
              title: Text(l10n.notificationsEnabled),
              subtitle: Text(l10n.notificationsEnabledDescription),
              value: settings.notificationsEnabled,
              onChanged: (v) async {
                await actions.setNotificationsEnabled(v);
                if (context.mounted) await _refreshNotifications(context, ref);
              },
            ),
            _WindowTile(
              startMinutes: settings.windowStartMinutes,
              endMinutes: settings.windowEndMinutes,
              onChanged: (start, end) async {
                await actions.setWindow(startMinutes: start, endMinutes: end);
                if (context.mounted) await _refreshNotifications(context, ref);
              },
            ),
            SwitchListTile.adaptive(
              title: Text(l10n.reminderRepeats),
              subtitle: Text(l10n.reminderRepeatsDescription),
              value: settings.repeatEnabled,
              onChanged: actions.setRepeatEnabled,
            ),
            if (settings.repeatEnabled) ...[
              _DelayRangeTile(
                minMinutes: settings.repeatMinDelayMin,
                maxMinutes: settings.repeatMaxDelayMin,
                onChanged: (min, max) => actions.setRepeatDelay(
                  minMinutes: min,
                  maxMinutes: max,
                ),
              ),
              _MaxRepeatsTile(
                value: settings.maxRepeatsPerDay,
                onChanged: actions.setMaxRepeats,
              ),
            ],
          ],
        ),
        _Section(
          title: l10n.dataSection,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.tag),
              title: Text(l10n.manageTriggers),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const TagManagementScreen(kind: TagKind.trigger),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.bandage),
              title: Text(l10n.manageMedications),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const TagManagementScreen(kind: TagKind.medication),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.share),
              title: Text(l10n.exportData),
              subtitle: Text(l10n.exportDataDescription),
              trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
              onTap: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const ExportScreen(),
                ),
              ),
            ),
          ],
        ),
        _Section(
          title: l10n.appearanceSection,
          children: [
            _LocaleTile(
              localeCode: settings.locale,
              onChanged: actions.setLocale,
            ),
            _ThemeTile(
              themeMode: settings.themeMode,
              onChanged: actions.setThemeMode,
            ),
          ],
        ),
        _Section(
          title: l10n.privacySection,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      CupertinoIcons.lock,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.privacyInfo,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _WindowTile extends StatelessWidget {
  const _WindowTile({
    required this.startMinutes,
    required this.endMinutes,
    required this.onChanged,
  });

  final int startMinutes;
  final int endMinutes;
  final Future<void> Function(int start, int end) onChanged;

  TimeOfDay _asTime(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);
  int _asMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String _format(BuildContext context, int minutes) {
    final mat = MaterialLocalizations.of(context);
    return mat.formatTimeOfDay(_asTime(minutes), alwaysUse24HourFormat: true);
  }

  Future<void> _pickStart(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _asTime(startMinutes),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final start = _asMinutes(picked);
    await onChanged(start, start >= endMinutes ? start + 60 : endMinutes);
  }

  Future<void> _pickEnd(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _asTime(endMinutes),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final end = _asMinutes(picked);
    await onChanged(end <= startMinutes ? end - 60 : startMinutes, end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.reminderWindow, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      l10n.reminderWindowDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickStart(context),
                  icon: const Icon(CupertinoIcons.time, size: 18),
                  label: Text('${l10n.reminderWindowFrom} ${_format(context, startMinutes)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickEnd(context),
                  icon: const Icon(CupertinoIcons.time, size: 18),
                  label: Text('${l10n.reminderWindowTo} ${_format(context, endMinutes)}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DelayRangeTile extends StatefulWidget {
  const _DelayRangeTile({
    required this.minMinutes,
    required this.maxMinutes,
    required this.onChanged,
  });

  final int minMinutes;
  final int maxMinutes;
  final Future<void> Function(int min, int max) onChanged;

  @override
  State<_DelayRangeTile> createState() => _DelayRangeTileState();
}

class _DelayRangeTileState extends State<_DelayRangeTile> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = RangeValues(widget.minMinutes.toDouble(), widget.maxMinutes.toDouble());
  }

  @override
  void didUpdateWidget(_DelayRangeTile old) {
    super.didUpdateWidget(old);
    if (old.minMinutes != widget.minMinutes || old.maxMinutes != widget.maxMinutes) {
      _values = RangeValues(widget.minMinutes.toDouble(), widget.maxMinutes.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reminderRepeatDelay, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 2),
          Text(
            l10n.reminderRepeatDelayDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _values,
            min: 5,
            max: 240,
            divisions: 47,
            labels: RangeLabels(
              '${_values.start.round()} ${l10n.minutesSuffix}',
              '${_values.end.round()} ${l10n.minutesSuffix}',
            ),
            onChanged: (v) => setState(() => _values = v),
            onChangeEnd: (v) =>
                widget.onChanged(v.start.round(), v.end.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_values.start.round()} ${l10n.minutesSuffix}'),
              Text('${_values.end.round()} ${l10n.minutesSuffix}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MaxRepeatsTile extends StatelessWidget {
  const _MaxRepeatsTile({required this.value, required this.onChanged});

  final int value;
  final Future<void> Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      title: Text(l10n.reminderMaxRepeats),
      trailing: DropdownButton<int>(
        value: value,
        items: const [1, 2, 3, 5, 10]
            .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({required this.icon, required this.label, required this.segmented});

  final IconData icon;
  final String label;
  final Widget segmented;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(height: 32, child: segmented),
        ],
      ),
    );
  }
}

class _LocaleTile extends StatelessWidget {
  const _LocaleTile({required this.localeCode, required this.onChanged});

  final String? localeCode;
  final Future<void> Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // CupertinoSlidingSegmentedControl's type parameter must be non-null, so
    // we use 'system' as a sentinel and map it back to null at the edge.
    return _SegmentedRow(
      icon: CupertinoIcons.globe,
      label: l10n.language,
      segmented: CupertinoSlidingSegmentedControl<String>(
        groupValue: localeCode ?? 'system',
        children: {
          'system': Text(l10n.languageSystem),
          'de': Text(l10n.languageDe),
          'en': Text(l10n.languageEn),
        },
        onValueChanged: (v) {
          if (v == null) return;
          onChanged(v == 'system' ? null : v);
        },
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.themeMode, required this.onChanged});

  final String themeMode;
  final Future<void> Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SegmentedRow(
      icon: CupertinoIcons.moon,
      label: l10n.themeMode,
      segmented: CupertinoSlidingSegmentedControl<String>(
        groupValue: themeMode,
        children: {
          'system': Text(l10n.themeSystem),
          'light': Text(l10n.themeLight),
          'dark': Text(l10n.themeDark),
        },
        onValueChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
