import 'package:flutter/material.dart';

import 'package:expensetracker/core/theme/app_colors.dart';
import 'package:expensetracker/core/theme/app_elevation.dart';
import 'package:expensetracker/core/theme/app_shapes.dart';
import 'package:expensetracker/core/theme/app_spacing.dart';
import 'package:expensetracker/core/theme/app_typography.dart';

/// Material component overrides assembled from the shared semantic tokens.
abstract final class ComponentThemes {
  static const interactionDuration = Duration(milliseconds: 150);

  static FilledButtonThemeData filledButton() => FilledButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(_primaryBackground),
      foregroundColor: WidgetStateProperty.resolveWith(_primaryForeground),
      overlayColor: const WidgetStatePropertyAll(AppColors.transparent),
      side: WidgetStateProperty.resolveWith(_primaryOutline),
      minimumSize: const WidgetStatePropertyAll(
        Size(0, AppSpacing.primaryButtonHeight),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md,
        ),
      ),
      textStyle: const WidgetStatePropertyAll(AppTypography.button),
      shape: const WidgetStatePropertyAll(AppShapes.pill),
      elevation: const WidgetStatePropertyAll(AppElevation.flat),
      animationDuration: interactionDuration,
      tapTargetSize: MaterialTapTargetSize.padded,
    ),
  );

  static OutlinedButtonThemeData outlinedButton() => OutlinedButtonThemeData(
    style: _secondaryStyle().copyWith(
      backgroundColor: WidgetStateProperty.resolveWith(_secondaryBackground),
      side: WidgetStateProperty.resolveWith(_secondaryOutline),
    ),
  );

  static TextButtonThemeData textButton() => TextButtonThemeData(
    style: _secondaryStyle().copyWith(
      backgroundColor: WidgetStateProperty.resolveWith(_ghostBackground),
      side: WidgetStateProperty.resolveWith(_primaryOutline),
    ),
  );

  static ButtonStyle _secondaryStyle() => ButtonStyle(
    foregroundColor: WidgetStateProperty.resolveWith(_secondaryForeground),
    overlayColor: const WidgetStatePropertyAll(AppColors.transparent),
    minimumSize: const WidgetStatePropertyAll(Size(0, AppSpacing.touchTarget)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
    ),
    textStyle: const WidgetStatePropertyAll(AppTypography.button),
    shape: const WidgetStatePropertyAll(AppShapes.pill),
    elevation: const WidgetStatePropertyAll(AppElevation.flat),
    animationDuration: interactionDuration,
    tapTargetSize: MaterialTapTargetSize.padded,
  );

  static const floatingActionButton = FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    hoverColor: AppColors.primaryHover,
    focusColor: AppColors.focusRing,
    splashColor: AppColors.primaryPressed,
    elevation: AppElevation.flat,
    focusElevation: AppElevation.flat,
    hoverElevation: AppElevation.flat,
    highlightElevation: AppElevation.flat,
    disabledElevation: AppElevation.flat,
    shape: AppShapes.pill,
    iconSize: AppSpacing.iconSize,
    extendedSizeConstraints: BoxConstraints(
      minHeight: AppSpacing.primaryButtonHeight,
    ),
    extendedPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
    extendedIconLabelSpacing: AppSpacing.xs,
    extendedTextStyle: AppTypography.button,
  );

  static InputDecorationThemeData inputDecoration() => InputDecorationThemeData(
    filled: true,
    fillColor: WidgetStateColor.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? AppColors.surfaceMuted
          : AppColors.surface,
    ),
    contentPadding: const EdgeInsets.all(AppSpacing.inputPadding),
    constraints: const BoxConstraints(minHeight: AppSpacing.inputMinHeight),
    labelStyle: AppTypography.supportingBody,
    floatingLabelStyle: WidgetStateTextStyle.resolveWith(
      (states) => AppTypography.supportingBody.copyWith(
        color: states.contains(WidgetState.error)
            ? AppColors.danger
            : states.contains(WidgetState.focused)
            ? AppColors.onPrimary
            : AppColors.textSecondary,
      ),
    ),
    hintStyle: AppTypography.supportingBody.copyWith(
      color: AppColors.textMuted,
    ),
    helperStyle: AppTypography.counter,
    counterStyle: AppTypography.counter,
    errorStyle: AppTypography.supportingBody.copyWith(color: AppColors.danger),
    errorMaxLines: 3,
    border: _inputBorder(AppColors.borderDefault),
    enabledBorder: _inputBorder(AppColors.borderDefault),
    focusedBorder: _inputBorder(AppColors.primary),
    disabledBorder: _inputBorder(AppColors.divider),
    errorBorder: _inputBorder(AppColors.danger),
    focusedErrorBorder: _inputBorder(AppColors.danger),
    hoverColor: AppColors.backgroundMuted,
    focusColor: AppColors.focusRing,
  );

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: AppShapes.inputRadius,
    borderSide: BorderSide(color: color, width: AppShapes.borderWidth),
  );

  static const card = CardThemeData(
    color: AppColors.surface,
    surfaceTintColor: AppColors.transparent,
    elevation: AppElevation.flat,
    shadowColor: AppColors.outlineShadow,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: AppShapes.cardRadius,
      side: BorderSide(
        color: AppColors.borderSubtle,
        width: AppShapes.hairlineWidth,
      ),
    ),
  );

  static const dialog = DialogThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: AppColors.transparent,
    elevation: AppElevation.dialog,
    shadowColor: AppColors.dialogShadow,
    barrierColor: AppColors.overlay,
    shape: RoundedRectangleBorder(
      borderRadius: AppShapes.dialogRadius,
      side: BorderSide(
        color: AppColors.borderSubtle,
        width: AppShapes.hairlineWidth,
      ),
    ),
    titleTextStyle: AppTypography.dialogTitle,
    contentTextStyle: AppTypography.body,
    insetPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xl,
    ),
    actionsPadding: EdgeInsets.all(AppSpacing.dialogPadding),
  );

  static const bottomSheet = BottomSheetThemeData(
    backgroundColor: AppColors.surface,
    modalBackgroundColor: AppColors.surface,
    modalBarrierColor: AppColors.overlay,
    surfaceTintColor: AppColors.transparent,
    elevation: AppElevation.flat,
    modalElevation: AppElevation.flat,
    shadowColor: AppColors.outlineShadow,
    shape: RoundedRectangleBorder(borderRadius: AppShapes.sheetRadius),
    clipBehavior: Clip.antiAlias,
  );

  static NavigationBarThemeData navigationBar() => NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: AppColors.transparent,
    elevation: AppElevation.flat,
    indicatorColor: AppColors.primary,
    indicatorShape: AppShapes.pill,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        size: AppSpacing.iconSize,
        color: states.contains(WidgetState.selected)
            ? AppColors.onPrimary
            : AppColors.textSecondary,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => AppTypography.caption.copyWith(
        color: states.contains(WidgetState.selected)
            ? AppColors.onPrimary
            : AppColors.textSecondary,
      ),
    ),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.focused)
          ? AppColors.focusRing
          : states.contains(WidgetState.pressed)
          ? AppColors.surfaceMuted
          : AppColors.transparent,
    ),
  );

  static final snackbar = SnackBarThemeData(
    backgroundColor: AppColors.snackbar,
    contentTextStyle: AppTypography.supportingBody.copyWith(
      color: AppColors.onSnackbar,
    ),
    actionTextColor: AppColors.primary,
    disabledActionTextColor: AppColors.surfaceMuted,
    elevation: AppElevation.flat,
    shape: const RoundedRectangleBorder(borderRadius: AppShapes.snackbarRadius),
    behavior: SnackBarBehavior.floating,
    insetPadding: const EdgeInsets.all(AppSpacing.md),
  );

  static const progressIndicator = ProgressIndicatorThemeData(
    color: AppColors.onPrimary,
    circularTrackColor: AppColors.primarySubtle,
    linearTrackColor: AppColors.primarySubtle,
  );

  static const appBar = AppBarThemeData(
    backgroundColor: AppColors.canvas,
    foregroundColor: AppColors.textPrimary,
    surfaceTintColor: AppColors.transparent,
    elevation: AppElevation.flat,
    scrolledUnderElevation: AppElevation.flat,
    titleTextStyle: AppTypography.screenTitle,
  );

  static Color _primaryBackground(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return AppColors.surfaceMuted;
    if (states.contains(WidgetState.pressed)) return AppColors.primaryPressed;
    if (states.contains(WidgetState.hovered)) return AppColors.primaryHover;
    return AppColors.primary;
  }

  static Color _primaryForeground(Set<WidgetState> states) =>
      states.contains(WidgetState.disabled)
      ? AppColors.textMuted
      : AppColors.onPrimary;

  static Color _secondaryForeground(Set<WidgetState> states) =>
      states.contains(WidgetState.disabled)
      ? AppColors.textMuted
      : AppColors.textPrimary;

  static Color _secondaryBackground(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled) ||
        states.contains(WidgetState.pressed)) {
      return AppColors.surfaceMuted;
    }
    if (states.contains(WidgetState.hovered)) return AppColors.backgroundMuted;
    return AppColors.surface;
  }

  static Color _ghostBackground(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled) ||
        states.contains(WidgetState.pressed)) {
      return AppColors.surfaceMuted;
    }
    if (states.contains(WidgetState.hovered)) return AppColors.backgroundMuted;
    return AppColors.transparent;
  }

  static BorderSide _primaryOutline(Set<WidgetState> states) =>
      !states.contains(WidgetState.disabled) &&
          states.contains(WidgetState.focused)
      ? const BorderSide(
          color: AppColors.focusRing,
          width: AppShapes.borderWidth,
        )
      : BorderSide.none;

  static BorderSide _secondaryOutline(Set<WidgetState> states) => BorderSide(
    color: states.contains(WidgetState.disabled)
        ? AppColors.divider
        : states.contains(WidgetState.focused)
        ? AppColors.focusRing
        : AppColors.borderDefault,
    width: AppShapes.borderWidth,
  );
}
