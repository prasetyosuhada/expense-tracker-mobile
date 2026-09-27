import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/core/errors/validation_failure.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/domain/expense_validator.dart';

Matcher failure(String field, String message) => isA<ValidationFailure>()
    .having((error) => error.field, 'field', field)
    .having((error) => error.message, 'message key', message);

void main() {
  const validator = ExpenseValidator();
  final date = ExpenseDate(2026, 9, 8);

  group('ExpenseValidator', () {
    group('amount', () {
      final invalid = <String, String>{
        '': 'formAmountRequired',
        '   ': 'formAmountRequired',
        '0': 'formAmountZero',
        '000': 'formAmountZero',
        '-1': 'formAmountZero',
        '-999999999999999999999': 'formAmountZero',
        'abc': 'formAmountInvalid',
        '1.5': 'formAmountInvalid',
        '1,5': 'formAmountInvalid',
        '25.000': 'formAmountInvalid',
        '+1': 'formAmountInvalid',
        '1e3': 'formAmountInvalid',
        'Rp25000': 'formAmountInvalid',
        '１２': 'formAmountInvalid',
        '1\n2': 'formAmountInvalid',
        '1000000000000': 'formAmountTooLarge',
        '9999999999999999999999999999999': 'formAmountTooLarge',
      };
      for (final entry in invalid.entries) {
        test('rejects ${entry.key.codeUnits} with ${entry.value}', () {
          expect(
            () => validator.validateAmount(entry.key),
            throwsA(failure('amount', entry.value)),
          );
        });
      }

      for (final value in <String, int>{
        '1': 1,
        '999999999999': 999_999_999_999,
        '000025000': 25000,
        '00000000000000000000000000000001': 1,
        ' 25000 ': 25000,
      }.entries) {
        test('parses ${value.key} exactly', () {
          expect(validator.validateAmount(value.key), value.value);
        });
      }
    });

    group('category and date', () {
      for (final category in ExpenseCategory.values) {
        test('accepts ${category.name}', () {
          final draft = validator.validateInput(
            amountText: '1',
            category: category,
            transactionDate: date,
          );
          expect(draft.category, category);
          expect(draft.transactionDate, date);
        });
      }

      for (final category in <Object?>[null, 'food', 'unknown', 0]) {
        test('rejects unselected or unknown category $category', () {
          expect(
            () => validator.validateInput(
              amountText: '1',
              category: category,
              transactionDate: date,
            ),
            throwsA(failure('category', 'formCategoryRequired')),
          );
        });
      }

      test('rejects a missing date', () {
        expect(
          () => validator.validateInput(
            amountText: '1',
            category: ExpenseCategory.food,
            transactionDate: null,
          ),
          throwsA(failure('transactionDate', 'formDateRequired')),
        );
      });

      test('invalid calendars cannot enter the typed validation boundary', () {
        expect(() => ExpenseDate(2026, 2, 30), throwsArgumentError);
      });
    });

    group('note', () {
      for (final note in <String?>[null, '', '   ', '\t\n ']) {
        test('normalizes blank ${note?.codeUnits} to null', () {
          expect(validator.normalizeNote(note), isNull);
        });
      }

      test('trims edges and preserves internal whitespace and line breaks', () {
        expect(validator.normalizeNote('  Makan siang  '), 'Makan siang');
        expect(
          validator.normalizeNote(' \nMakan  siang\nlagi\t '),
          'Makan  siang\nlagi',
        );
      });

      for (final grapheme in <String>['a', '👨‍👩‍👧‍👦', 'e\u0301', '👍🏽']) {
        for (final length in <int>[99, 100]) {
          test('accepts $length graphemes of $grapheme', () {
            final note = List<String>.filled(length, grapheme).join();
            expect(validator.normalizeNote(note), note);
          });
        }
        test('rejects 101 graphemes of $grapheme', () {
          final note = List<String>.filled(101, grapheme).join();
          expect(
            () => validator.normalizeNote(note),
            throwsA(failure('note', 'formNoteTooLong')),
          );
        });
      }

      test('checks the normalized note length after trimming', () {
        final note = List<String>.filled(100, 'a').join();
        expect(validator.normalizeNote('  $note  '), note);
      });
    });

    group('draft revalidation', () {
      test('returns a normalized copy without changing the input', () {
        final original = ExpenseDraft(
          amount: 25000,
          category: ExpenseCategory.food,
          transactionDate: date,
          note: '  Makan siang  ',
        );
        final normalized = validator.validate(original);
        expect(normalized.amount, original.amount);
        expect(normalized.category, original.category);
        expect(normalized.transactionDate, original.transactionDate);
        expect(normalized.note, 'Makan siang');
        expect(original.note, '  Makan siang  ');
      });

      for (final amount in <int>[0, -1, 1_000_000_000_000]) {
        test('rejects invalid draft amount $amount', () {
          final draft = ExpenseDraft(
            amount: amount,
            category: ExpenseCategory.food,
            transactionDate: date,
            note: null,
          );
          expect(
            () => validator.validate(draft),
            throwsA(
              failure(
                'amount',
                amount <= 0 ? 'formAmountZero' : 'formAmountTooLarge',
              ),
            ),
          );
        });
      }

      test('rejects an oversized draft note', () {
        final draft = ExpenseDraft(
          amount: 1,
          category: ExpenseCategory.other,
          transactionDate: date,
          note: List<String>.filled(101, '👨‍👩‍👧‍👦').join(),
        );
        expect(
          () => validator.validate(draft),
          throwsA(failure('note', 'formNoteTooLong')),
        );
      });
    });
  });
}
