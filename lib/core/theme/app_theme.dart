import 'package:flutter/material.dart';

import 'package:expensetracker/core/theme/app_colors.dart';
import 'package:expensetracker/core/theme/app_shapes.dart';
import 'package:expensetracker/core/theme/app_spacing.dart';
import 'package:expensetracker/core/theme/app_typography.dart';
import 'package:expensetracker/core/theme/category_colors.dart';
import 'package:expensetracker/core/theme/component_themes.dart';

/// Assembles the local semantic tokens into a Material 3 light theme.
abstract final class AppTheme {
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primarySubtle,
      onPrimaryContainer: AppColors.onPrimary,
      secondary: AppColors.link,
      onSecondary: AppColors.surface,
      secondaryContainer: AppColors.primarySubtle,
      onSecondaryContainer: AppColors.onPrimary,
      tertiary: AppColors.success,
      onTertiary: AppColors.surface,
      tertiaryContainer: AppColors.surfaceMuted,
      onTertiaryContainer: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.surface,
      errorContainer: AppColors.dangerSubtle,
      onErrorContainer: AppColors.dangerPressed,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.canvas,
      surfaceContainer: AppColors.backgroundMuted,
      surfaceContainerHigh: AppColors.surfaceMuted,
      surfaceContainerHighest: AppColors.surfaceMuted,
      surfaceBright: AppColors.surface,
      surfaceDim: AppColors.surfaceActive,
      outline: AppColors.borderDefault,
      outlineVariant: AppColors.divider,
      inverseSurface: AppColors.snackbar,
      onInverseSurface: AppColors.onSnackbar,
      inversePrimary: AppColors.primary,
      surfaceTint: AppColors.transparent,
      shadow: AppColors.dialogShadow,
      scrim: AppColors.overlay,
    ),
    fontFamily: AppTypography.bodyFamily,
    textTheme: AppTypography.textTheme,
    scaffoldBackgroundColor: AppColors.canvas,
    canvasColor: AppColors.canvas,
    disabledColor: AppColors.textMuted,
    dividerColor: AppColors.divider,
    focusColor: AppColors.focusRing,
    hoverColor: AppColors.backgroundMuted,
    highlightColor: AppColors.surfaceActive,
    splashColor: AppColors.surfaceMuted,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: const <ThemeExtension<dynamic>>[CategoryColors.light],
    filledButtonTheme: ComponentThemes.filledButton(),
    outlinedButtonTheme: ComponentThemes.outlinedButton(),
    textButtonTheme: ComponentThemes.textButton(),
    floatingActionButtonTheme: ComponentThemes.floatingActionButton,
    inputDecorationTheme: ComponentThemes.inputDecoration(),
    cardTheme: ComponentThemes.card,
    dialogTheme: ComponentThemes.dialog,
    bottomSheetTheme: ComponentThemes.bottomSheet,
    navigationBarTheme: ComponentThemes.navigationBar(),
    snackBarTheme: ComponentThemes.snackbar,
    progressIndicatorTheme: ComponentThemes.progressIndicator,
    appBarTheme: ComponentThemes.appBar,
    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
      size: AppSpacing.iconSize,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: AppShapes.hairlineWidth,
      space: AppShapes.hairlineWidth,
    ),
  );
}
