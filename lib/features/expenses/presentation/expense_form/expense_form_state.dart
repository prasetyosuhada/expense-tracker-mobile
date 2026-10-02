import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';

/// The outcome returned by submitting the add/edit form.
enum ExpenseFormResult { none, created, updated }

/// Raw form input and feedback, independent of widget controllers.
final class ExpenseFormState {
  ExpenseFormState({
    required this.amountText,
    required this.selectedCategory,
    required this.selectedDate,
    required this.noteText,
    Map<String, String> fieldErrors = const <String, String>{},
    this.hasSubmitted = false,
    this.isDirty = false,
    this.isSubmitting = false,
    this.submitFailure,
  }) : fieldErrors = Map<String, String>.unmodifiable(fieldErrors);

  /// Unformatted whole-Rupiah input; separators belong to the widget.
  final String amountText;
  final ExpenseCategory? selectedCategory;
  final ExpenseDate selectedDate;

  /// Preserves input whitespace until the domain normalizes the saved draft.
  final String noteText;

  /// Domain field names mapped to ARB keys, in form field order.
  final Map<String, String> fieldErrors;
  final bool hasSubmitted;

  /// Stays true after a field update, even when its initial value is restored.
  final bool isDirty;
  final bool isSubmitting;
  final AppFailure? submitFailure;
}
