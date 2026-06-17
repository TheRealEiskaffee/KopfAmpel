import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/ampel_colors.dart';
import '../../../app/theme/tag_palette.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/domain/entry.dart';
import '../../../core/domain/severity.dart';
import '../../../core/domain/tag.dart';
import '../../../core/domain/tag_kind.dart';
import '../../../core/i18n/app_localizations.dart';
import '../application/calendar_providers.dart';

class DayDetailSheet extends ConsumerStatefulWidget {
  const DayDetailSheet({required this.date, super.key});

  final DateTime date;

  static Future<void> show(BuildContext context, DateTime date) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DayDetailSheet(date: date),
    );
  }

  @override
  ConsumerState<DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends ConsumerState<DayDetailSheet> {
  Severity _severity = Severity.none;
  final _noteController = TextEditingController();
  final Set<int> _selectedTriggers = {};
  final Map<int, TextEditingController> _doseControllers = {};
  bool _loaded = false;
  bool _existingEntry = false;

  @override
  void dispose() {
    _noteController.dispose();
    for (final c in _doseControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _hydrateFromEntry(HeadacheEntry entry) {
    _severity = entry.severity;
    _noteController.text = entry.note ?? '';
    _selectedTriggers
      ..clear()
      ..addAll(entry.triggers.map((t) => t.id));
    for (final m in entry.medications) {
      _doseControllers[m.tag.id] = TextEditingController(text: m.dose ?? '');
    }
    _existingEntry = true;
  }

  TextEditingController _doseController(int medId) {
    return _doseControllers.putIfAbsent(medId, TextEditingController.new);
  }

  Future<void> _save() async {
    final medications = _doseControllers.entries
        .map(
          (e) => MedicationEntry(
            tag: Tag(id: e.key, name: '', kind: TagKind.medication),
            dose: e.value.text.trim().isEmpty ? null : e.value.text.trim(),
          ),
        )
        .toList();
    final triggers = _selectedTriggers
        .map((id) => Tag(id: id, name: '', kind: TagKind.trigger))
        .toList();

    await ref.read(entriesRepositoryProvider).upsert(
          date: widget.date,
          severity: _severity,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          triggers: triggers,
          medications: medications,
        );
    ref.invalidate(entryByDayProvider(widget.date));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteEntryTitle),
        content: Text(l10n.deleteEntryBody),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.delete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(entriesRepositoryProvider).deleteByDate(widget.date);
    ref.invalidate(entryByDayProvider(widget.date));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat.yMMMMEEEEd(locale).format(widget.date);

    final entryAsync = ref.watch(entryByDayProvider(widget.date));
    final triggersAsync = ref.watch(triggerTagsProvider);
    final medsAsync = ref.watch(medicationTagsProvider);

    entryAsync.whenData((entry) {
      if (!_loaded) {
        if (entry != null) _hydrateFromEntry(entry);
        _loaded = true;
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(l10n.selectSeverity, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _SeverityPicker(
              value: _severity,
              onChanged: (v) => setState(() => _severity = v),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteController,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.noteLabel,
                hintText: l10n.noteHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.triggersLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _TagChipGrid(
              tagsAsync: triggersAsync,
              selectedIds: _selectedTriggers,
              onToggle: (id) {
                setState(() {
                  if (!_selectedTriggers.add(id)) _selectedTriggers.remove(id);
                });
              },
            ),
            const SizedBox(height: 24),
            Text(l10n.medicationsLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _MedicationSection(
              medsAsync: medsAsync,
              selectedIds: _doseControllers.keys.toSet(),
              onToggle: (id) {
                setState(() {
                  if (_doseControllers.containsKey(id)) {
                    _doseControllers.remove(id)?.dispose();
                  } else {
                    _doseController(id);
                  }
                });
              },
              controllerFor: _doseController,
              doseHint: l10n.doseHint,
              tagNameById: (id) => medsAsync.maybeWhen(
                data: (list) => list.firstWhere(
                  (t) => t.id == id,
                  orElse: () => Tag(id: id, name: '?', kind: TagKind.medication),
                ).name,
                orElse: () => '',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_existingEntry)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(CupertinoIcons.delete, size: 18),
                      label: Text(l10n.delete),
                    ),
                  ),
                if (_existingEntry) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityPicker extends StatelessWidget {
  const _SeverityPicker({required this.value, required this.onChanged});

  final Severity value;
  final ValueChanged<Severity> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <(Severity, Color, String)>[
      (Severity.none, AmpelColors.none, l10n.severityNone),
      (Severity.green, AmpelColors.green, l10n.severityGreen),
      (Severity.yellow, AmpelColors.yellow, l10n.severityYellow),
      (Severity.red, AmpelColors.red, l10n.severityRed),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (sev, color, label) in items)
          ChoiceChip(
            selected: value == sev,
            onSelected: (_) => onChanged(sev),
            avatar: CircleAvatar(backgroundColor: color, radius: 8),
            label: Text(label),
          ),
      ],
    );
  }
}

class _TagChipGrid extends StatelessWidget {
  const _TagChipGrid({
    required this.tagsAsync,
    required this.selectedIds,
    required this.onToggle,
  });

  final AsyncValue<List<Tag>> tagsAsync;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return tagsAsync.when(
      data: (tags) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in tags)
            FilterChip(
              selected: selectedIds.contains(t.id),
              avatar: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: t.displayColor,
                  shape: BoxShape.circle,
                ),
              ),
              label: Text(t.name),
              onSelected: (_) => onToggle(t.id),
            ),
        ],
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text(AppLocalizations.of(context).loadFailed(e.toString())),
    );
  }
}

class _MedicationSection extends StatelessWidget {
  const _MedicationSection({
    required this.medsAsync,
    required this.selectedIds,
    required this.onToggle,
    required this.controllerFor,
    required this.doseHint,
    required this.tagNameById,
  });

  final AsyncValue<List<Tag>> medsAsync;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final TextEditingController Function(int) controllerFor;
  final String doseHint;
  final String Function(int) tagNameById;

  @override
  Widget build(BuildContext context) {
    return medsAsync.when(
      data: (meds) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in meds)
                  FilterChip(
                    selected: selectedIds.contains(t.id),
                    avatar: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: t.displayColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    label: Text(t.name),
                    onSelected: (_) => onToggle(t.id),
                  ),
              ],
            ),
            if (selectedIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final id in selectedIds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(tagNameById(id)),
                      ),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: controllerFor(id),
                          decoration: InputDecoration(
                            hintText: doseHint,
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(AppLocalizations.of(context).loadFailed(e.toString())),
    );
  }
}
