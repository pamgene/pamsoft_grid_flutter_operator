import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tercen Design System typography.
///
/// Font family: Fira Sans (with system fallbacks)
/// All values reference design-tokens.md
class AppTextStyles {
  AppTextStyles._();

  // Font families
  static const String fontFamily = 'Fira Sans';
  static const String fontFamilyMono = 'SF Mono';

  // Font sizes
  static const double textXs = 11.0;
  static const double textSm = 13.0;
  static const double textBase = 14.0;
  static const double textMd = 16.0;
  static const double textLg = 18.0;
  static const double textXl = 24.0;
  static const double text2xl = 32.0;

  // Font weights
  static const FontWeight weightLight = FontWeight.w300;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // Line heights
  static const double leadingTight = 1.25;
  static const double leadingNormal = 1.5;
  static const double leadingRelaxed = 1.75;

  // Pre-defined text styles
  static const TextStyle pageTitle = TextStyle(
    fontSize: text2xl,
    fontWeight: weightBold,
    height: leadingTight,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: textXl,
    fontWeight: weightSemibold,
    height: leadingTight,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: textLg,
    fontWeight: weightSemibold,
    height: leadingTight,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: textMd,
    fontWeight: weightRegular,
    height: leadingNormal,
    color: AppColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: textBase,
    fontWeight: weightRegular,
    height: leadingNormal,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: textSm,
    fontWeight: weightRegular,
    height: leadingNormal,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: textSm,
    fontWeight: weightMedium,
    height: leadingNormal,
    color: AppColors.textTertiary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: textXs,
    fontWeight: weightMedium,
    height: leadingNormal,
    color: AppColors.textMuted,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: textXs,
    fontWeight: weightSemibold,
    height: leadingNormal,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  static const TextStyle button = TextStyle(
    fontSize: textBase,
    fontWeight: weightMedium,
    height: leadingNormal,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: textSm,
    fontWeight: weightMedium,
    height: leadingNormal,
  );

  static const TextStyle code = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: textSm,
    fontWeight: weightRegular,
    height: leadingNormal,
  );
}
