import 'package:flutter/material.dart';

/// Status colours used to mark headache severity on the calendar.
/// Kept separate from the brand/primary palette so the UI never mixes them up.
@immutable
class AmpelColors {
  const AmpelColors._();

  static const Color green = Color(0xFF2E7D32);
  static const Color yellow = Color(0xFFF9A825);
  static const Color red = Color(0xFFC62828);
  static const Color none = Color(0xFF9E9E9E);

  static const Color greenSoft = Color(0xFFC8E6C9);
  static const Color yellowSoft = Color(0xFFFFECB3);
  static const Color redSoft = Color(0xFFFFCDD2);
}
