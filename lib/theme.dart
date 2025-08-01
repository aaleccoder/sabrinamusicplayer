import 'package:flutter/material.dart';

class AppTheme {
  // ──────────────────────────────────────────────────────────
  // COLORS
  // ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF3B38A0);
  static const Color primaryVariant = Color(0xFF2E2B8A);
  static const Color secondary = Color(0xFF36454F);
  static const Color secondaryVariant = Color(0xFFDB582E);
  static const Color background = Color.fromARGB(255, 18, 18, 18);
  static const Color surface = Color(0xFF1F1F1F);
  static const Color error = Color(0xFFCF6679);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Color.fromARGB(255, 193, 193, 193);
  static const Color onBackground = Colors.white;
  static const Color onSurface = Colors.white;
  static const Color onError = Colors.black;

  // ──────────────────────────────────────────────────────────
  // SPACING & RADIUS
  // ──────────────────────────────────────────────────────────
  static BorderRadius radiusSm = BorderRadius.circular(4);
  static BorderRadius radiusMd = BorderRadius.circular(8);
  static BorderRadius radiusLg = BorderRadius.circular(16);

  static const EdgeInsets paddingSm = EdgeInsets.all(8);
  static const EdgeInsets paddingMd = EdgeInsets.all(16);
  static const EdgeInsets paddingLg = EdgeInsets.all(24);

  // ──────────────────────────────────────────────────────────
  // TYPOGRAPHY
  // ──────────────────────────────────────────────────────────
  // Sizes and weights picked to ensure readability in dark mode.
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
    labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w300),
  );
}
