import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app/theme/tag_palette.dart';

Color hexToColor(String hex) =>
    Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);

/// Wrapping swatch picker shared by the category and tag editors. [selected] is
/// a hex string, or null for the "auto" colour derived from the name.
class ColorSwatchPicker extends StatelessWidget {
  const ColorSwatchPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ColorChoice(
          color: scheme.onSurfaceVariant,
          selected: selected == null,
          isAuto: true,
          onTap: () => onChanged(null),
        ),
        for (final hex in kColorSwatches)
          _ColorChoice(
            color: hexToColor(hex),
            selected: selected == hex,
            onTap: () => onChanged(hex),
          ),
      ],
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
    this.isAuto = false,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool isAuto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(23),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isAuto ? scheme.surfaceContainerHighest : color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: isAuto
            ? Icon(CupertinoIcons.wand_stars, size: 18, color: color)
            : selected
                ? const Icon(CupertinoIcons.checkmark, size: 18, color: Colors.white)
                : null,
      ),
    );
  }
}
