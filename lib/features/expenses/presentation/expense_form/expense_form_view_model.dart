import 'package:flutter/foundation.dart';

import 'package:expensetracker/core/clock/app_clock.dart';
import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';
import 'package:expensetracker/features/expenses/domain/expense_validator.dart';
import 'package:expensetracker/features/expenses/presentation/expense_form/expense_form_state.dart';

/// Coordinates form input, domain validation, and one pending create/update.
final class ExpenseFormViewModel extends ChangeNotifier {
  /// An omitted [expense] starts an empty form dated by the injected clock.
  ExpenseFormViewModel(this._repository, AppClock clock, {Expense? expense})
    : _expenseId = expense?.id,
      _state = ExpenseFormState(
        amountText: expense?.amount.toString() ?? '',
        selectedCategory: expense?.category,
        selectedDate:
            expense?.transactionDate ?? ExpenseDate.fromDateTime(clock.now()),
        noteText: expense?.note ?? '',
      );

  final ExpenseRepository _repository;
  final int? _expenseId;
  final ExpenseValidator _validator = const ExpenseValidator();
  ExpenseFormState _state;
  bool _isDisposed = false;

  ExpenseFormState get state => _state;
  bool get isEditing => _expenseId != null;

  void updateAmount(String amountText) => _updateInputs(
    amountText: amountText,
    selectedCategory: _state.selectedCategory,
    selectedDate: _state.selectedDate,
    noteText: _state.noteText,
  );

  void updateCategory(ExpenseCategory? category) => _updateInputs(
    amountText: _state.amountText,
    selectedCategory: category,
    selectedDate: _state.selectedDate,
    noteText: _state.noteText,
  );

  void updateDate(ExpenseDate date) => _updateInputs(
    amountText: _state.amountText,
    selectedCategory: _state.selectedCategory,
    selectedDate: date,
    noteText: _state.noteText,
  );

  void updateNote(String noteText) => _updateInputs(
    amountText: _state.amountText,
    selectedCategory: _state.selectedCategory,
    selectedDate: _state.selectedDate,
    noteText: noteText,
  );

  void _updateInputs({
    required String amountText,
    required ExpenseCategory? selectedCategory,
    required ExpenseDate selectedDate,
    required String noteText,
  }) {
    if (_isDisposed || _state.isSubmitting) return;
    final input = ExpenseFormState(
      amountText: amountText,
      selectedCategory: selectedCategory,
      selectedDate: selectedDate,
      noteText: noteText,
      hasSubmitted: _state.hasSubmitted,
      isDirty: true,
    );
    _state = ExpenseFormState(
      amountText: input.amountText,
      selectedCategory: input.selectedCategory,
      selectedDate: input.selectedDate,
      noteText: input.noteText,
      fieldErrors: input.hasSubmitted
          ? _validateFields(input)
          : const <String, String>{},
      hasSubmitted: input.hasSubmitted,
      isDirty: true,
    );
    notifyListeners();
  }

  /// Returns [ExpenseFormResult.none] for invalid, failed, or ignored calls.
  ///
  /// The pending guard is set before notifying listeners or awaiting storage.
  /// A committed write still returns its success result after disposal, while
  /// late completions never change the disposed model or notify its listeners.
  Future<ExpenseFormResult> submit() async {
    if (_isDisposed || _state.isSubmitting) return ExpenseFormResult.none;

    final errors = _validateFields(_state);
    _setSubmissionState(fieldErrors: errors, isSubmitting: errors.isEmpty);
    if (errors.isNotEmpty || _isDisposed) return ExpenseFormResult.none;

    AppFailure? submitFailure;
    try {
      final draft = _validator.validateInput(
        amountText: _state.amountText,
        category: _state.selectedCategory,
        transactionDate: _state.selectedDate,
        note: _state.noteText,
      );
      final id = _expenseId;
      if (id == null) {
        await _repository.create(draft);
        return ExpenseFormResult.created;
      }
      await _repository.update(id: id, draft: draft);
      return ExpenseFormResult.updated;
    } on AppFailure catch (failure) {
      submitFailure = failure;
      return ExpenseFormResult.none;
    } on Object catch (error) {
      submitFailure = UnexpectedFailure(error);
      return ExpenseFormResult.none;
    } finally {
      if (!_isDisposed) {
        final failure = submitFailure;
        _setSubmissionState(
          fieldErrors: <String, String>{
            ...errors,
            if (failure is ValidationFailure) failure.field: failure.message,
          },
          isSubmitting: false,
          submitFailure: failure,
        );
      }
    }
  }

  Map<String, String> _validateFields(ExpenseFormState input) {
    final errors = <String, String>{};
    void collect(void Function() validate) {
      try {
        validate();
      } on ValidationFailure catch (failure) {
        errors[failure.field] = failure.message;
      }
    }

    collect(() => _validator.validateAmount(input.amountText));
    // A known-valid amount isolates selection validation without duplicating
    // category/date rules or ARB keys from the domain validator.
    collect(
      () => _validator.validateInput(
        amountText: '1',
        category: input.selectedCategory,
        transactionDate: input.selectedDate,
      ),
    );
    collect(() => _validator.normalizeNote(input.noteText));
    return errors;
  }

  void _setSubmissionState({
    required Map<String, String> fieldErrors,
    required bool isSubmitting,
    AppFailure? submitFailure,
  }) {
    _state = ExpenseFormState(
      amountText: _state.amountText,
      selectedCategory: _state.selectedCategory,
      selectedDate: _state.selectedDate,
      noteText: _state.noteText,
      fieldErrors: fieldErrors,
      hasSubmitted: true,
      isDirty: _state.isDirty,
      isSubmitting: isSubmitting,
      submitFailure: submitFailure,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    super.dispose();
  }
}
