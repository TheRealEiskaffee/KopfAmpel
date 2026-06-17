// ignore_for_file: avoid_print
//
// Generates a placeholder app icon for KopfAmpel.
//
// The icon is a 1024x1024 PNG showing a stylised Ampel (traffic light):
// a soft light-grey background, a subtle rounded rectangle "housing",
// and three filled circles in the AmpelColors (red on top, yellow in
// the middle, green at the bottom — same order as a real Ampel).
//
// Run via:
//   dart run tools/generate_icon.dart
//
// Output is written (idempotently) to assets/icons/app_icon.png.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const int _size = 1024;

// AmpelColors from the app's theme.
const int _ampelRed = 0xFFC62828;
const int _ampelYellow = 0xFFF9A825;
const int _ampelGreen = 0xFF2E7D32;

// Soft background + housing colours.
const int _background = 0xFFF2F3F5; // very light grey
const int _housing = 0xFFE2E5EA; // slightly darker rounded rectangle
const int _housingShadow = 0xFFD3D7DE;

img.Color _rgba(int argb) {
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return img.ColorRgba8(r, g, b, a);
}

/// Fills a rounded rectangle by drawing a filled rect for the body
/// and four filled circles at the corners.
void _fillRoundedRect(
  img.Image image, {
  required int x,
  required int y,
  required int w,
  required int h,
  required int radius,
  required img.Color color,
}) {
  // Horizontal band (full width, minus rounded corners on top/bottom).
  img.fillRect(
    image,
    x1: x,
    y1: y + radius,
    x2: x + w - 1,
    y2: y + h - radius - 1,
    color: color,
  );
  // Vertical band (full height, minus rounded corners on left/right).
  img.fillRect(
    image,
    x1: x + radius,
    y1: y,
    x2: x + w - radius - 1,
    y2: y + h - 1,
    color: color,
  );
  // Four corner circles.
  img.fillCircle(
    image,
    x: x + radius,
    y: y + radius,
    radius: radius,
    color: color,
  );
  img.fillCircle(
    image,
    x: x + w - radius - 1,
    y: y + radius,
    radius: radius,
    color: color,
  );
  img.fillCircle(
    image,
    x: x + radius,
    y: y + h - radius - 1,
    radius: radius,
    color: color,
  );
  img.fillCircle(
    image,
    x: x + w - radius - 1,
    y: y + h - radius - 1,
    radius: radius,
    color: color,
  );
}

Future<void> main() async {
  final image = img.Image(width: _size, height: _size, numChannels: 4);

  // 1. Background.
  img.fill(image, color: _rgba(_background));

  // 2. Subtle rounded rectangle "housing" behind the three lights.
  //    Centred horizontally, slightly tall.
  const housingWidth = 520;
  const housingHeight = 880;
  const housingRadius = 130;
  final housingX = (_size - housingWidth) ~/ 2;
  final housingY = (_size - housingHeight) ~/ 2;

  // Soft drop shadow underneath the housing.
  _fillRoundedRect(
    image,
    x: housingX + 10,
    y: housingY + 18,
    w: housingWidth,
    h: housingHeight,
    radius: housingRadius,
    color: _rgba(_housingShadow),
  );

  // Housing itself.
  _fillRoundedRect(
    image,
    x: housingX,
    y: housingY,
    w: housingWidth,
    h: housingHeight,
    radius: housingRadius,
    color: _rgba(_housing),
  );

  // 3. Three circles — red on top, yellow centre, green bottom.
  const lightRadius = 130;
  final centreX = _size ~/ 2;
  final spacing = (housingHeight - 6 * lightRadius) ~/ 4 + 2 * lightRadius;
  final firstY = housingY + (housingHeight - 2 * spacing) ~/ 2;

  final lights = <int>[_ampelRed, _ampelYellow, _ampelGreen];
  for (var i = 0; i < lights.length; i++) {
    final cy = firstY + i * spacing;

    // Very subtle inner shadow / outline.
    img.fillCircle(
      image,
      x: centreX,
      y: cy + 6,
      radius: lightRadius + 4,
      color: _rgba(_housingShadow),
    );

    img.fillCircle(
      image,
      x: centreX,
      y: cy,
      radius: lightRadius,
      color: _rgba(lights[i]),
    );

    // Tiny highlight to give a glassy look.
    final highlightR = (lightRadius * 0.32).round();
    final hx = centreX - (lightRadius * 0.35).round();
    final hy = cy - (lightRadius * 0.35).round();
    final highlight = img.ColorRgba8(255, 255, 255, 70);
    img.fillCircle(
      image,
      x: hx,
      y: hy,
      radius: highlightR,
      color: highlight,
    );
  }

  // Sanity: make sure the result is square and the right size.
  assert(image.width == _size && image.height == _size);
  // Use math just to keep the import meaningful for future tweaks.
  final ratio = image.width / math.max(1, image.height);
  assert(ratio == 1.0);

  final outFile = File('assets/icons/app_icon.png');
  await outFile.parent.create(recursive: true);
  await outFile.writeAsBytes(img.encodePng(image));

  print('Wrote ${outFile.path} (${_size}x$_size).');
}
