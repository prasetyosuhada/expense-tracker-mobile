import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/core/theme/app_theme.dart';
import 'package:expensetracker/core/theme/category_colors.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';

void main() {
  const light = CategoryColors.light;

  test('the registered extension exposes all five reviewed category pairs', () {
    final colors = AppTheme.light().extension<CategoryColors>();
    expect(colors, same(light));
    const backgrounds = <int>[
      0xFFFFC091,
      0xFF38C8FF,
      0xFF9FE870,
      0xFFFFD11A,
      0xFFE8EBE6,
    ];
    const foregrounds = <int>[
      0xFF0E0F0C,
      0xFF0E0F0C,
      0xFF163300,
      0xFF0E0F0C,
      0xFF454745,
    ];
    for (var index = 0; index < ExpenseCategory.values.length; index++) {
      final category = ExpenseCategory.values[index];
      expect(light.backgroundFor(category).toARGB32(), backgrounds[index]);
      expect(light.foregroundFor(category).toARGB32(), foregrounds[index]);
    }
  });

  test('copyWith replaces each color without changing the source', () {
    const replacement = Color(0xFF123456);
    final changed = light.copyWith(
      foodBackground: replacement,
      foodForeground: replacement,
      transportationBackground: replacement,
      transportationForeground: replacement,
      shoppingBackground: replacement,
      shoppingForeground: replacement,
      billsBackground: replacement,
      billsForeground: replacement,
      otherBackground: replacement,
      otherForeground: replacement,
    );
    for (final category in ExpenseCategory.values) {
      expect(changed.backgroundFor(category), replacement);
      expect(changed.foregroundFor(category), replacement);
      expect(light.backgroundFor(category), isNot(replacement));
      expect(light.foregroundFor(category), isNot(replacement));
    }
    final partial = light.copyWith(foodBackground: replacement);
    expect(partial.foodBackground, replacement);
    expect(partial.foodForeground, light.foodForeground);
    for (final category in ExpenseCategory.values.skip(1)) {
      expect(partial.backgroundFor(category), light.backgroundFor(category));
      expect(partial.foregroundFor(category), light.foregroundFor(category));
    }
  });

  test('lerp handles null, both endpoints, and every intermediate pair', () {
    final target = light.copyWith(
      foodBackground: Colors.black,
      foodForeground: Colors.white,
      transportationBackground: Colors.black,
      transportationForeground: Colors.white,
      shoppingBackground: Colors.black,
      shoppingForeground: Colors.white,
      billsBackground: Colors.black,
      billsForeground: Colors.white,
      otherBackground: Colors.black,
      otherForeground: Colors.white,
    );
    expect(light.lerp(null, 0.5), same(light));
    for (final t in <double>[0, 0.5, 1]) {
      final result = light.lerp(target, t);
      for (final category in ExpenseCategory.values) {
        expect(
          result.backgroundFor(category),
          Color.lerp(
            light.backgroundFor(category),
            target.backgroundFor(category),
            t,
          ),
        );
        expect(
          result.foregroundFor(category),
          Color.lerp(
            light.foregroundFor(category),
            target.foregroundFor(category),
            t,
          ),
        );
      }
    }
  });
}
