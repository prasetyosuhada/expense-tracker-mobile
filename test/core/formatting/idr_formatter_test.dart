import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:expensetracker/core/formatting/idr_formatter.dart';

void main() {
  group('IdrFormatter', () {
    test(
      'formats zero, thousands, and millions without decimals or spaces',
      () {
        final formatter = IdrFormatter();
        expect(formatter.formatDisplay(0), 'Rp0');
        expect(formatter.formatDisplay(25_000), 'Rp25.000');
        expect(formatter.formatDisplay(1_250_000), 'Rp1.250.000');
      },
    );

    test(
      'keeps large transaction and aggregate totals as complete integers',
      () {
        final formatter = IdrFormatter();
        expect(formatter.formatDisplay(999_999_999_999), 'Rp999.999.999.999');
        expect(
          formatter.formatDisplay(9_999_999_999_990_000),
          'Rp9.999.999.999.990.000',
        );
      },
    );

    test('uses Indonesian grouping regardless of the ambient locale', () {
      final formatter = IdrFormatter();
      final result = Intl.withLocale(
        'en_US',
        () => formatter.formatDisplay(1_250_000),
      );
      expect(result, 'Rp1.250.000');
    });
  });
}
