import 'package:flutter/material.dart';

/// Tercen Design System colour palette.
///
/// All colours reference the design tokens from tercen-style/claude-skills/foundation/design-tokens.md
class AppColors {
  AppColors._();

  // Primary (Light Theme)
  static const Color primary = Color(0xFF1E40AF);
  static const Color primaryDarker = Color(0xFF1E3A8A);
  static const Color primaryLighter = Color(0xFF2563EB);
  static const Color primarySurface = Color(0xFFDBEAFE);
  static const Color primaryBg = Color(0xFFEFF6FF);

  // Primary (Dark Theme) - Teal
  static const Color primaryDark = Color(0xFF14B8A6); // teal-500
  static const Color primaryDarkDarker = Color(0xFF0D9488); // teal-600
  static const Color primaryDarkLighter = Color(0xFF2DD4BF); // teal-400
  static const Color primaryDarkSurface = Color(0xFF153D47); // teal tinted surface
  static const Color primaryDarkBg = Color(0xFF122E35); // teal tinted bg

  // Links (Dark Theme) - Blue to differentiate from primary
  static const Color linkDark = Color(0xFF60A5FA); // blue-400

  // Accent/Semantic colours
  static const Color green = Color(0xFF047857);
  static const Color greenLight = Color(0xFFD1FAE5);
  static const Color teal = Color(0xFF0E7490);
  static const Color tealLight = Color(0xFFCFFAFE);
  static const Color amber = Color(0xFFB45309);
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color red = Color(0xFFB91C1C);
  static const Color redLight = Color(0xFFFEE2E2);

  // Neutrals
  static const Color neutral900 = Color(0xFF111827);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic aliases for clarity (Light Mode)
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral700;
  static const Color textTertiary = neutral600;
  static const Color textMuted = neutral500;
  static const Color textDisabled = neutral400;

  static const Color surface = white;
  static const Color surfaceElevated = neutral50;
  static const Color pageBackground = neutral100;
  static const Color border = neutral300;
  static const Color borderSubtle = neutral200;

  // Dark Mode specific colors
  static const Color darkPageBackground = Color(0xFF0A0A0A); // darker than neutral-900
  static const Color darkSurface = neutral900;
  static const Color darkSurfaceElevated = neutral800;
  static const Color darkBorder = neutral600;
  static const Color darkBorderSubtle = neutral700;
  static const Color darkTextPrimary = neutral50;
  static const Color darkTextSecondary = neutral200;
  static const Color darkTextTertiary = neutral400;
  static const Color darkTextMuted = neutral500;
  static const Color darkTextDisabled = neutral600;

  // Status colours (Tercen semantic mapping)
  static const Color success = green;
  static const Color successLight = greenLight;
  static const Color warning = amber;
  static const Color warningLight = amberLight;
  static const Color error = red;
  static const Color errorLight = redLight;
  static const Color info = teal;
  static const Color infoLight = tealLight;

  // Status colours (Dark Mode - adjusted for better contrast)
  static const Color successDark = Color(0xFF10B981); // green-light for dark
  static const Color warningDark = Color(0xFFFBBF24); // amber-light for dark
  static const Color errorDark = Color(0xFFF87171); // red-light for dark
  static const Color infoDark = Color(0xFF60A5FA); // blue for dark
}
