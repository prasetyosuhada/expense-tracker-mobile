import 'package:flutter/material.dart';

/// Shared radii, outlines, and component shapes.
abstract final class AppShapes {
  static const double small = 10;
  static const double medium = 16;
  static const double large = 30;
  static const double extraLarge = 40;
  static const double full = 9999;
  static const double borderWidth = 2;
  static const double hairlineWidth = 1;

  static const inputRadius = BorderRadius.all(Radius.circular(small));
  static const cardRadius = BorderRadius.all(Radius.circular(large));
  static const dialogRadius = BorderRadius.all(Radius.circular(extraLarge));
  static const snackbarRadius = BorderRadius.all(Radius.circular(medium));
  static const sheetRadius = BorderRadius.vertical(
    top: Radius.circular(extraLarge),
  );
  static const pill = StadiumBorder();
}
