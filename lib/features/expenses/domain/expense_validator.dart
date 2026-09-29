import 'package:characters/characters.dart';

import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';

/// Validates expense input and produces normalized drafts.
final class ExpenseValidator {
  /// Creates a stateless validator.
  const ExpenseValidator();

  /// The maximum amount in whole Rupiah.
  static const int maxAmount = 999_999_999_999;

  /// The maximum note length in user-perceived characters.
  static const int maxNoteGraphemes = 100;

  static final RegExp _integerPattern = RegExp(r'^-?[0-9]+$');
  static final RegExp _leadingZeros = RegExp(r'^0+');

  /// Revalidates a draft and returns its normalized copy.
  ///
  /// Throws [ValidationFailure] when any field violates domain rules.
  ExpenseDraft validate(ExpenseDraft draft) {
    return validateInput(
      amountText: draft.amount.toString(),
      category: draft.category,
      transactionDate: draft.transactionDate,
      note: draft.note,
    );
  }

  /// Validates unformatted decimal amount input and a selected enum category.
  ///
  /// Category codes and arbitrary objects are rejected, not coerced to enums.
  /// [transactionDate] must already be a valid [ExpenseDate]. Failures carry
  /// field names and ARB keys; localized text is resolved outside the domain.
  ExpenseDraft validateInput({
    required String amountText,
    required Object? category,
    required ExpenseDate? transactionDate,
    String? note,
  }) {
    final amount = validateAmount(amountText);
    if (category is! ExpenseCategory) {
      throw const ValidationFailure('category', 'formCategoryRequired');
    }
    if (transactionDate == null) {
      throw const ValidationFailure('transactionDate', 'formDateRequired');
    }
    return ExpenseDraft(
      amount: amount,
      category: category,
      transactionDate: transactionDate,
      note: normalizeNote(note),
    );
  }

  /// Parses whole-Rupiah digits and enforces the valid amount range.
  int validateAmount(String amountText) {
    final input = amountText.trim();
    if (input.isEmpty) {
      throw const ValidationFailure('amount', 'formAmountRequired');
    }
    final match = _integerPattern.firstMatch(input);
    if (match == null || match.end != input.length) {
      throw const ValidationFailure('amount', 'formAmountInvalid');
    }
    if (input.startsWith('-')) {
      throw const ValidationFailure('amount', 'formAmountZero');
    }
    final digits = input.replaceFirst(_leadingZeros, '');
    if (digits.isEmpty) {
      throw const ValidationFailure('amount', 'formAmountZero');
    }
    // Compare before parsing so arbitrarily large digit input cannot overflow.
    final maximum = maxAmount.toString();
    if (digits.length > maximum.length ||
        (digits.length == maximum.length && digits.compareTo(maximum) > 0)) {
      throw const ValidationFailure('amount', 'formAmountTooLarge');
    }
    return int.parse(digits);
  }

  /// Trims note edges, preserves internal whitespace, and enforces graphemes.
  String? normalizeNote(String? note) {
    final normalized = note?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (normalized.characters.length > maxNoteGraphemes) {
      throw const ValidationFailure('note', 'formNoteTooLong');
    }
    return normalized;
  }
}
