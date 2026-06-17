import 'package:flutter/material.dart';

import '../app/theme/ampel_colors.dart';
import '../core/domain/severity.dart';

class SeverityDot extends StatelessWidget {
  const SeverityDot({required this.severity, this.size = 8, super.key});

  final Severity severity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      Severity.green => AmpelColors.green,
      Severity.yellow => AmpelColors.yellow,
      Severity.red => AmpelColors.red,
      Severity.none => AmpelColors.none,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
