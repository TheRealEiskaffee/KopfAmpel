import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/ampel_colors.dart';
import '../../../app/theme/category_icons.dart';
import '../../../app/theme/tag_palette.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/domain/category.dart';
import '../../../core/domain/entry.dart';
import '../../../core/domain/severity.dart';
import '../../../core/domain/tag.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../widgets/confirm_dialog.dart';
import '../application/calendar_providers.dart';

class DayDetailSheet extends ConsumerStatefulWidget {
  const DayDetailSheet({required this.date, super.key});

  final DateTime date;

  static Future<void> show(BuildContext context, DateTime date) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // Cap the height so it stays a draggable bottom sheet (pill + backdrop
      // above) instead of filling the whole screen when there are many tags.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      builder: (_) => DayDetailSheet(date: date),
    );
  }

  @override
  ConsumerState<DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends ConsumerState<DayDetailSheet> {
  Severity _severity = Severity.none;
  final _noteController = TextEditingController();
  final Set<int> _selectedTagIds = {};
  bool _loaded = false;
  bool _existingEntry = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _hydrateFromEntry(HeadacheEntry entry) {
    _severity = entry.severity;
    _noteController.text = entry.note ?? '';
    _selectedTagIds
      ..clear()
      ..addAll(entry.tags.map((t) => t.id));
    _existingEntry = true;
  }

  void _toggleTag(int id) {
    setState(() {
      if (!_selectedTagIds.add(id)) _selectedTagIds.remove(id);
    });
  }

  Future<void> _save() async {
    final tags = _selectedTagIds
        .map((id) => Tag(id: id, name: '', categoryId: 0))
        .toList();

    await ref.read(entriesRepositoryProvider).upsert(
          date: widget.date,
          severity: _severity,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          tags: tags,
        );
    ref.invalidate(entryByDayProvider(widget.date));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteEntryTitle,
      message: l10n.deleteEntryBody,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok) return;
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
    final categoriesAsync = ref.watch(categoriesProvider);

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
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (_existingEntry)
                        IconButton(
                          tooltip: l10n.delete,
                          onPressed: _delete,
                          icon: Icon(
                            CupertinoIcons.delete,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  categoriesAsync.when(
                    data: (categories) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final category in categories)
                          _CategorySection(
                            category: category,
                            selectedIds: _selectedTagIds,
                            onToggle: _toggleTag,
                          ),
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, _) => Text(l10n.loadFailed(e.toString())),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const Divider(height: 17),
          // Pinned action bar — stays visible no matter how long the content is.
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
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
    );
  }
}

/// One category's header + selectable tag chips. Hidden when the category has
/// no tags so empty categories don't clutter the entry sheet.
class _CategorySection extends ConsumerWidget {
  const _CategorySection({
    required this.category,
    required this.selectedIds,
    required this.onToggle,
  });

  final Category category;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsByCategoryProvider(category.id));
    final tags = tagsAsync.valueOrNull ?? const [];
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconForKey(category.icon), size: 18, color: category.displayColor),
              const SizedBox(width: 8),
              Text(category.name, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tags)
                _SelectableColorChip(
                  color: t.displayColor,
                  label: t.name,
                  selected: selectedIds.contains(t.id),
                  onSelected: () => onToggle(t.id),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Selectable colour chip shared by the tag grid and the severity picker.
/// Selected → background is a light shade of [color] and the checkmark is a
/// darker shade of the same hue (always darker than the background); the colour
/// dot is hidden. Unselected → outlined, no grey fill, dot visible. Greys (e.g.
/// the "no headache" severity) stay grey.
class _SelectableColorChip extends StatelessWidget {
  const _SelectableColorChip({
    required this.color,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hsl = HSLColor.fromColor(color);
    // Keep near-grey colours grey; boost real colours so the light selected
    // fill reads clearly.
    final sat = hsl.saturation < 0.15 ? hsl.saturation : 0.85;
    final selectedBg = hsl.withSaturation(sat).withLightness(0.86).toColor();
    final checkColor = hsl.withLightness(0.38).toColor();

    return Theme(
      // Remove the grey press/hover overlay so tapping a chip doesn't flash grey.
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      child: FilterChip(
      selected: selected,
      showCheckmark: true,
      checkmarkColor: checkColor,
      selectedColor: selectedBg,
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: selected ? selectedBg : scheme.outlineVariant,
      ),
      // FilterChip keeps the avatar AND adds the checkmark when selected, which
      // shows two dots. Drop the avatar while selected so only the checkmark
      // (in the darker shade) remains.
      avatar: selected
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
      // When selected the background is a light tint, so force the label to the
      // same dark shade as the checkmark — otherwise it's invisible in dark mode
      // (light text on a light fill).
      label: Text(
        label,
        style: selected ? TextStyle(color: checkColor) : null,
      ),
      onSelected: (_) => onSelected(),
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
          _SelectableColorChip(
            color: color,
            label: label,
            selected: value == sev,
            onSelected: () => onChanged(sev),
          ),
      ],
    );
  }
}
