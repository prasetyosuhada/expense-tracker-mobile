import 'package:flutter/material.dart';

import 'package:expensetracker/core/theme/app_colors.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';

/// Semantic icon colors that have no corresponding ColorScheme slots.
@immutable
final class CategoryColors extends ThemeExtension<CategoryColors> {
  const CategoryColors({
    required this.foodBackground,
    required this.foodForeground,
    required this.transportationBackground,
    required this.transportationForeground,
    required this.shoppingBackground,
    required this.shoppingForeground,
    required this.billsBackground,
    required this.billsForeground,
    required this.otherBackground,
    required this.otherForeground,
  });

  static const light = CategoryColors(
    foodBackground: AppColors.foodBackground,
    foodForeground: AppColors.foodForeground,
    transportationBackground: AppColors.transportationBackground,
    transportationForeground: AppColors.transportationForeground,
    shoppingBackground: AppColors.shoppingBackground,
    shoppingForeground: AppColors.shoppingForeground,
    billsBackground: AppColors.billsBackground,
    billsForeground: AppColors.billsForeground,
    otherBackground: AppColors.otherBackground,
    otherForeground: AppColors.otherForeground,
  );

  final Color foodBackground;
  final Color foodForeground;
  final Color transportationBackground;
  final Color transportationForeground;
  final Color shoppingBackground;
  final Color shoppingForeground;
  final Color billsBackground;
  final Color billsForeground;
  final Color otherBackground;
  final Color otherForeground;

  Color backgroundFor(ExpenseCategory category) => switch (category) {
    ExpenseCategory.food => foodBackground,
    ExpenseCategory.transportation => transportationBackground,
    ExpenseCategory.shopping => shoppingBackground,
    ExpenseCategory.bills => billsBackground,
    ExpenseCategory.other => otherBackground,
  };

  Color foregroundFor(ExpenseCategory category) => switch (category) {
    ExpenseCategory.food => foodForeground,
    ExpenseCategory.transportation => transportationForeground,
    ExpenseCategory.shopping => shoppingForeground,
    ExpenseCategory.bills => billsForeground,
    ExpenseCategory.other => otherForeground,
  };

  @override
  CategoryColors copyWith({
    Color? foodBackground,
    Color? foodForeground,
    Color? transportationBackground,
    Color? transportationForeground,
    Color? shoppingBackground,
    Color? shoppingForeground,
    Color? billsBackground,
    Color? billsForeground,
    Color? otherBackground,
    Color? otherForeground,
  }) => CategoryColors(
    foodBackground: foodBackground ?? this.foodBackground,
    foodForeground: foodForeground ?? this.foodForeground,
    transportationBackground:
        transportationBackground ?? this.transportationBackground,
    transportationForeground:
        transportationForeground ?? this.transportationForeground,
    shoppingBackground: shoppingBackground ?? this.shoppingBackground,
    shoppingForeground: shoppingForeground ?? this.shoppingForeground,
    billsBackground: billsBackground ?? this.billsBackground,
    billsForeground: billsForeground ?? this.billsForeground,
    otherBackground: otherBackground ?? this.otherBackground,
    otherForeground: otherForeground ?? this.otherForeground,
  );

  @override
  CategoryColors lerp(covariant CategoryColors? other, double t) {
    if (other == null) return this;
    return CategoryColors(
      foodBackground:
          Color.lerp(foodBackground, other.foodBackground, t) ?? foodBackground,
      foodForeground:
          Color.lerp(foodForeground, other.foodForeground, t) ?? foodForeground,
      transportationBackground:
          Color.lerp(
            transportationBackground,
            other.transportationBackground,
            t,
          ) ??
          transportationBackground,
      transportationForeground:
          Color.lerp(
            transportationForeground,
            other.transportationForeground,
            t,
          ) ??
          transportationForeground,
      shoppingBackground:
          Color.lerp(shoppingBackground, other.shoppingBackground, t) ??
          shoppingBackground,
      shoppingForeground:
          Color.lerp(shoppingForeground, other.shoppingForeground, t) ??
          shoppingForeground,
      billsBackground:
          Color.lerp(billsBackground, other.billsBackground, t) ??
          billsBackground,
      billsForeground:
          Color.lerp(billsForeground, other.billsForeground, t) ??
          billsForeground,
      otherBackground:
          Color.lerp(otherBackground, other.otherBackground, t) ??
          otherBackground,
      otherForeground:
          Color.lerp(otherForeground, other.otherForeground, t) ??
          otherForeground,
    );
  }
}
