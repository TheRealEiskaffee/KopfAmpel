import 'package:flutter/material.dart';

import '../../core/domain/tag.dart';

extension TagPalette on Tag {
  /// Falls back to a deterministic colour derived from the tag's name when
  /// nothing was stored — same name always produces the same colour, so the
  /// Trigger / Medikament chips look stable across sessions.
  Color get displayColor {
    final stored = color;
    if (stored != null && stored.startsWith('#') && stored.length == 7) {
      try {
        return Color(int.parse(stored.substring(1), radix: 16) | 0xFF000000);
      } catch (_) {
        // Fall through to the derived colour.
      }
    }
    return paletteColorForName(name);
  }
}

/// Golden-angle hue distribution so names with similar character sums still
/// land in different parts of the wheel.
Color paletteColorForName(String name) {
  if (name.isEmpty) return const Color(0xFF9E9E9E);
  final hash = name.codeUnits.fold<int>(0, (acc, c) => acc + c);
  final hue = (hash * 137.508) % 360;
  return HSLColor.fromAHSL(1, hue, 0.55, 0.6).toColor();
}
