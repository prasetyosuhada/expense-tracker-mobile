import 'package:flutter/material.dart';

import 'package:expensetracker/core/theme/app_colors.dart';

/// Local Geist display styles and Inter body/action styles.
abstract final class AppTypography {
  static const displayFamily = 'Geist';
  static const bodyFamily = 'Inter';

  static const monthlyTotal = TextStyle(
    fontFamily: displayFamily,
    fontSize: 40,
    fontWeight: FontWeight.w900,
    height: 1.1,
    color: AppColors.onPrimary,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );
  static const screenTitle = TextStyle(
    fontFamily: displayFamily,
    fontSize: 26,
    fontWeight: FontWeight.w900,
    height: 1.1,
    color: AppColors.textPrimary,
  );
  static const dialogTitle = TextStyle(
    fontFamily: displayFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.textPrimary,
  );
  static const sectionTitle = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.23,
    color: AppColors.textPrimary,
  );
  static const transactionAmount = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.23,
    color: AppColors.textPrimary,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );
  static const body = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.44,
    color: AppColors.textPrimary,
  );
  static const supportingBody = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.textSecondary,
  );
  static const button = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1,
  );
  static const caption = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.55,
    color: AppColors.textSecondary,
  );
  static const counter = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.textMuted,
  );

  static const textTheme = TextTheme(
    displaySmall: monthlyTotal,
    headlineMedium: screenTitle,
    headlineSmall: dialogTitle,
    titleMedium: sectionTitle,
    titleSmall: transactionAmount,
    bodyLarge: body,
    bodyMedium: supportingBody,
    bodySmall: counter,
    labelLarge: button,
    labelMedium: caption,
    labelSmall: counter,
  );
}
