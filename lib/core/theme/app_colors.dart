import 'package:flutter/material.dart';

/// The reviewed light palette; alpha values are encoded directly in ARGB.
abstract final class AppColors {
  static const primary = Color(0xFF9FE870);
  static const onPrimary = Color(0xFF163300);
  static const primaryHover = Color(0xFFCDFFAD);
  static const primaryPressed = Color(0xFF8AD05E);
  static const primarySubtle = Color(0xFFE2F6D5);
  static const canvas = Color(0xFFFAFAFA);
  static const backgroundMuted = Color(0xFFF5F6F4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE8EBE6);
  static const surfaceActive = Color(0xFFE0E4DD);
  static const textPrimary = Color(0xFF0E0F0C);
  static const textSecondary = Color(0xFF454745);
  static const textMuted = Color(0xFF686868);
  static const link = Color(0xFF2D7A1A);
  static const danger = Color(0xFFD03238);
  static const dangerPressed = Color(0xFFB22A30);
  // A light danger tint for Material's error container and future alerts.
  static const dangerSubtle = Color(0xFFFBEAEC);
  static const success = Color(0xFF054D28);
  static const borderDefault = Color(0x7A0E0F0C);
  static const borderSubtle = Color(0x0F0E0F0C);
  static const divider = Color(0x140E0F0C);
  static const focusRing = Color(0x99163300);
  static const overlay = Color(0x800E0F0C);
  static const snackbar = Color(0xFF1E201C);
  static const onSnackbar = Color(0xFFFCFCFC);
  static const outlineShadow = Color(0x1F0E0F0C);
  static const dialogShadow = Color(0x0F0E0F0C);
  static const transparent = Color(0x00000000);

  static const foodBackground = Color(0xFFFFC091);
  static const foodForeground = textPrimary;
  static const transportationBackground = Color(0xFF38C8FF);
  static const transportationForeground = textPrimary;
  static const shoppingBackground = primary;
  static const shoppingForeground = onPrimary;
  static const billsBackground = Color(0xFFFFD11A);
  static const billsForeground = textPrimary;
  static const otherBackground = surfaceMuted;
  static const otherForeground = textSecondary;
}
