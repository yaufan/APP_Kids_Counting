import 'package:flutter/material.dart';

/// The app's colours: printing inks on cream paper (docs/art.md 「顏色」, the
/// same as design/art/kit.py), a dark brown ink for words, never pure black.
abstract final class Inks {
  static const ink = Color(0xFF3B2A1E);
  static const inkSoft = Color(0xFF7C6A5A);
  static const paper = Color(0xFFF6EDD9);
  static const cream = Color(0xFFFBF4E4);
  static const red = Color(0xFFC8553D);
  static const pink = Color(0xFFE6A49A);
  static const orange = Color(0xFFE08A3A);
  static const yellow = Color(0xFFEDBE3F);
  static const gold = Color(0xFFD9A53A);
  static const green = Color(0xFF86AE5E);
  static const leaf = Color(0xFF5E8C4A);
  static const olive = Color(0xFF9DB86A);
  static const sky = Color(0xFFBFD9DE);
  static const blue = Color(0xFF4F7FA8);
  static const wood = Color(0xFFD3A46C);
  static const brown = Color(0xFF94653F);
  static const soil = Color(0xFFB98A5E);
  static const dusk1 = Color(0xFF3E3A5E);
  static const dusk2 = Color(0xFFB0776A);
  static const parentBg = Color(0xFFF3EEE5);
  static const line = Color(0xFFE2D3BA);

  /// The dark ink edge of a shape printed in [c] (kit.edge_of).
  static Color edge(Color c) => Color.lerp(c, ink, .72)!;
}

abstract final class InkTheme {
  /// jf open 粉圓 (OFL): a rounded typeface made in Taiwan.
  static const font = 'Huninn';

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Inks.red, surface: Inks.paper),
      scaffoldBackgroundColor: Inks.paper,
      fontFamily: font,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    return base.copyWith(textTheme: base.textTheme.apply(bodyColor: Inks.ink, displayColor: Inks.ink, fontFamily: font));
  }
}
