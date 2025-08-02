import 'package:flutter/material.dart';

class AppTheme {
  // ──────────────────────────────────────────────────────────
  // COLORS - Modern gradient and glassmorphism palette
  // ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1); // Modern indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF14B8A6); // Teal accent
  static const Color secondaryLight = Color(0xFF5EEAD4);
  static const Color accent = Color(0xFFF59E0B); // Amber accent
  static const Color background = Color(0xFF0F0F0F); // Deep black
  static const Color surface = Color(0xFF1A1A1A); // Elevated surface
  static const Color surfaceVariant = Color(0xFF2A2A2A); // Higher elevation
  static const Color glass = Color(0x1AFFFFFF); // Glass effect
  static const Color error = Color(0xFFEF4444);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Color(0xFFE5E7EB);
  static const Color onBackground = Color(0xFFF9FAFB);
  static const Color onSurface = Color(0xFFE5E7EB);
  static const Color onError = Colors.white;

  // ──────────────────────────────────────────────────────────
  // MODERN SPACING & RADIUS
  // ──────────────────────────────────────────────────────────
  static BorderRadius radiusXs = BorderRadius.circular(6);
  static BorderRadius radiusSm = BorderRadius.circular(8);
  static BorderRadius radiusMd = BorderRadius.circular(12);
  static BorderRadius radiusLg = BorderRadius.circular(16);
  static BorderRadius radiusXl = BorderRadius.circular(20);
  static BorderRadius radiusXxl = BorderRadius.circular(24);

  static const EdgeInsets paddingXs = EdgeInsets.all(4);
  static const EdgeInsets paddingSm = EdgeInsets.all(8);
  static const EdgeInsets paddingMd = EdgeInsets.all(16);
  static const EdgeInsets paddingLg = EdgeInsets.all(24);
  static const EdgeInsets paddingXl = EdgeInsets.all(32);

  // ──────────────────────────────────────────────────────────
  // SHADOWS & GLASSMORPHISM
  // ──────────────────────────────────────────────────────────
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 6),
    ),
  ];

  // Glassmorphism effect
  static BoxDecoration glassBox = BoxDecoration(
    borderRadius: radiusLg,
    border: Border.all(color: Colors.white.withOpacity(0.1)),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.05)],
    ),
  );

  // Enhanced card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    borderRadius: radiusLg,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [surfaceVariant, surface],
    ),
    boxShadow: shadowMd,
    border: Border.all(color: Colors.white.withOpacity(0.05)),
  );

  // ──────────────────────────────────────────────────────────
  // MODERN TYPOGRAPHY
  // ──────────────────────────────────────────────────────────
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    displayMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      height: 1.2,
    ),
    displaySmall: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.3,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.3,
    ),
  );

  // ──────────────────────────────────────────────────────────
  // ANIMATION CURVES & DURATIONS
  // ──────────────────────────────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationSlowest = Duration(milliseconds: 700);

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveEmphasized = Curves.easeOutQuart;
  static const Curve curveDecelerate = Curves.decelerate;
  static const Curve curveSpring = Curves.elasticOut;
}
