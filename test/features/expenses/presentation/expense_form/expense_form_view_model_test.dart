import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_change.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';
import 'package:expensetracker/features/expenses/domain/home_summary.dart';
import 'package:expensetracker/features/expenses/presentation/expense_form/expense_form_state.dart';
import 'package:expensetracker/features/expenses/presentation/expense_form/expense_form_view_model.dart';

import '../../../../helpers/fake_app_clock.dart';
import '../../../../helpers/fake_expense_repository.dart';

void main() {
  late FakeAppClock clock;
  late Expense original;
  late FakeExpenseRepository fake;
  late _ControlledFormRepository controlled;
  late ExpenseFormViewModel model;

  void useEditMode({Expense? expense}) {
    model.dispose();
    model = ExpenseFormViewModel(
      controlled,
      clock,
      expense: expense ?? original,
    );
  }

  void fillForm() {
    model.updateAmount('00025000');
    model.updateCategory(ExpenseCategory.food);
    model.updateDate(ExpenseDate(2026, 10, 1));
    model.updateNote('  Makan\nsiang  ');
  }

  setUp(() {
    clock = FakeAppClock(DateTime(2026, 10, 2, 0, 1));
    original = Expense(
      id: 7,
      amount: 15000,
      category: ExpenseCategory.transportation,
      transactionDate: ExpenseDate(2026, 9, 30),
      note: 'Ojek',
      createdAt: DateTime.utc(2026, 9, 30, 8),
      updatedAt: DateTime.utc(2026, 9, 30, 8),
    );
    fake = FakeExpenseRepository(
      clock: clock,
      initialExpenses: <Expense>[original],
    );
    controlled = _ControlledFormRepository(fake);
    model = ExpenseFormViewModel(controlled, clock);
  });

  tearDown(() async {
    model.dispose();
    await fake.dispose();
  });

  group('initial input and dirty state', () {
    test('add mode starts clean and uses local clock components once', () {
      final state = model.state;
      expect(model.isEditing, isFalse);
      expect(state.amountText, isEmpty);
      expect(state.selectedCategory, isNull);
      expect(state.selectedDate, ExpenseDate(2026, 10, 2));
      expect(state.noteText, isEmpty);
      expect(state.fieldErrors, isEmpty);
      expect(state.hasSubmitted, isFalse);
      expect(state.isDirty, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.submitFailure, isNull);

      clock.currentTime = DateTime(2026, 10, 3);
      expect(model.state.selectedDate, ExpenseDate(2026, 10, 2));
    });

    test('edit mode copies every field and the stored date', () {
      useEditMode();

      expect(model.isEditing, isTrue);
      expect(model.state.amountText, '15000');
      expect(model.state.selectedCategory, original.category);
      expect(model.state.selectedDate, original.transactionDate);
      expect(model.state.noteText, original.note);
      expect(model.state.isDirty, isFalse);
      expect(model.state.hasSubmitted, isFalse);
      expect(model.state.isSubmitting, isFalse);
      expect(model.state.submitFailure, isNull);
      expect(model.state.fieldErrors, isEmpty);
    });

    test('edit mode represents a null note as empty input', () {
      useEditMode(
        expense: Expense(
          id: original.id,
          amount: original.amount,
          category: original.category,
          transactionDate: original.transactionDate,
          note: null,
          createdAt: original.createdAt,
          updatedAt: original.updatedAt,
        ),
      );

      expect(model.state.noteText, isEmpty);
      expect(model.state.isDirty, isFalse);
    });

    final updates = <String, void Function(ExpenseFormViewModel)>{
      'amount': (model) => model.updateAmount('0'),
      'category': (model) => model.updateCategory(ExpenseCategory.bills),
      'date': (model) => model.updateDate(ExpenseDate(1900, 1, 1)),
      'note': (model) => model.updateNote('note'),
    };
    for (final entry in updates.entries) {
      test('${entry.key} update marks dirty without premature errors', () {
        final before = model.state;
        var notifications = 0;
        model.addListener(() => notifications++);

        entry.value(model);

        expect(model.state.isDirty, isTrue);
        expect(model.state.hasSubmitted, isFalse);
        expect(model.state.fieldErrors, isEmpty);
        expect(before.isDirty, isFalse);
        expect(notifications, 1);
      });
    }

    test('restoring an initial value still keeps the form dirty', () {
      useEditMode();
      model.updateAmount('20000');
      model.updateAmount(original.amount.toString());

      expect(model.state.amountText, original.amount.toString());
      expect(model.state.isDirty, isTrue);
    });

    test('field error maps copy their source and reject mutation', () {
      final errors = <String, String>{'amount': 'formAmountRequired'};
      final state = ExpenseFormState(
        amountText: '',
        selectedCategory: null,
        selectedDate: ExpenseDate(2026, 10, 2),
        noteText: '',
        fieldErrors: errors,
      );
      errors.clear();

      expect(state.fieldErrors, <String, String>{
        'amount': 'formAmountRequired',
      });
      expect(state.fieldErrors.clear, throwsUnsupportedError);
    });
  });

  group('domain validation', () {
    test('empty submit reports both required fields without a write', () async {
      expect(await model.submit(), ExpenseFormResult.none);

      expect(model.state.fieldErrors, <String, String>{
        'amount': 'formAmountRequired',
        'category': 'formCategoryRequired',
      });
      expect(model.state.hasSubmitted, isTrue);
      expect(model.state.isDirty, isFalse);
      expect(model.state.isSubmitting, isFalse);
      expect(model.state.submitFailure, isNull);
      expect(model.state.amountText, isEmpty);
      expect(model.state.selectedCategory, isNull);
      expect(controlled.createCalls, 0);
      expect(await fake.getAll(), <Expense>[original]);
    });

    test('collects errors in field order and updates them live', () async {
      model.updateNote(List<String>.filled(101, '👨‍👩‍👧‍👦').join());
      expect(await model.submit(), ExpenseFormResult.none);
      final before = model.state;
      expect(before.fieldErrors.keys, <String>['amount', 'category', 'note']);
      expect(before.fieldErrors['note'], 'formNoteTooLong');

      model.updateAmount('25000');
      expect(model.state.fieldErrors.keys, <String>['category', 'note']);
      model.updateCategory(ExpenseCategory.food);
      expect(model.state.fieldErrors.keys, <String>['note']);
      model.updateNote('valid');
      expect(model.state.fieldErrors, isEmpty);
      model.updateAmount('0');
      expect(model.state.fieldErrors['amount'], 'formAmountZero');
      model.updateCategory(null);
      expect(model.state.fieldErrors['category'], 'formCategoryRequired');
      model.updateDate(ExpenseDate(1900, 1, 1));
      expect(model.state.fieldErrors.keys, <String>['amount', 'category']);
      expect(before.fieldErrors.keys, <String>['amount', 'category', 'note']);
      expect(controlled.createCalls, 0);
    });

    final invalidAmounts = <String, String>{
      '': 'formAmountRequired',
      '0': 'formAmountZero',
      '-1': 'formAmountZero',
      'abc': 'formAmountInvalid',
      '25.000': 'formAmountInvalid',
      '1000000000000': 'formAmountTooLarge',
    };
    for (final editMode in <bool>[false, true]) {
      for (final entry in invalidAmounts.entries) {
        test(
          '${editMode ? 'edit' : 'add'} rejects amount "${entry.key}"',
          () async {
            if (editMode) useEditMode();
            model.updateCategory(ExpenseCategory.food);
            model.updateAmount(entry.key);

            expect(await model.submit(), ExpenseFormResult.none);
            expect(model.state.fieldErrors, <String, String>{
              'amount': entry.value,
            });
            expect(model.state.amountText, entry.key);
            expect(controlled.createCalls, 0);
            expect(controlled.updateIds, isEmpty);
            expect(await fake.getAll(), <Expense>[original]);
          },
        );
      }
    }

    for (final amount in <String>['1', '999999999999']) {
      test('accepts boundary amount $amount', () async {
        fillForm();
        model.updateAmount(amount);

        expect(await model.submit(), ExpenseFormResult.created);
        final saved = (await fake.getAll()).first;
        expect(saved.amount, int.parse(amount));
        expect(model.state.fieldErrors, isEmpty);
      });
    }

    test('accepts 100 compound graphemes and rejects the next one', () async {
      useEditMode();
      final note = List<String>.filled(100, '👨‍👩‍👧‍👦').join();
      model.updateNote(note);
      expect(await model.submit(), ExpenseFormResult.updated);
      expect((await fake.getAll()).single.note, note);

      model.updateNote('${note}e\u0301');
      expect(model.state.fieldErrors['note'], 'formNoteTooLong');
      expect(await model.submit(), ExpenseFormResult.none);
      expect(controlled.updateIds, <int>[original.id]);
      expect((await fake.getAll()).single.note, note);
    });
  });

  group('submit and recovery', () {
    test('create saves a normalized draft and preserves raw input', () async {
      fillForm();
      final before = model.state;
      final events = <ExpenseChange>[];
      final subscription = fake.changes.listen(events.add);
      addTearDown(subscription.cancel);
      final states = <ExpenseFormState>[];
      model.addListener(() => states.add(model.state));

      expect(await model.submit(), ExpenseFormResult.created);
      await Future<void>.delayed(Duration.zero);

      final saved = (await fake.getAll()).first;
      expect(saved.amount, 25000);
      expect(saved.category, ExpenseCategory.food);
      expect(saved.transactionDate, ExpenseDate(2026, 10, 1));
      expect(saved.note, 'Makan\nsiang');
      expect(events, <ExpenseChange>[ExpenseChange.created]);
      expect(states.map((state) => state.isSubmitting), <bool>[true, false]);
      expect(model.state.hasSubmitted, isTrue);
      expect(model.state.submitFailure, isNull);
      _expectSameInput(model.state, before);
      expect(controlled.createCalls, 1);
      expect(controlled.updateIds, isEmpty);
    });

    test('edit updates the original ID and preserves creation time', () async {
      useEditMode();
      fillForm();
      model.updateNote('   ');

      expect(await model.submit(), ExpenseFormResult.updated);

      final saved = (await fake.getAll()).single;
      expect(saved.id, original.id);
      expect(saved.amount, 25000);
      expect(saved.category, ExpenseCategory.food);
      expect(saved.transactionDate, ExpenseDate(2026, 10, 1));
      expect(saved.note, isNull);
      expect(saved.createdAt, original.createdAt);
      expect(saved.updatedAt, clock.now().toUtc());
      expect(original.note, 'Ojek');
      expect(model.state.noteText, '   ');
      expect(controlled.createCalls, 0);
      expect(controlled.updateIds, <int>[original.id]);
    });

    test(
      'two separately completed submits can create identical entries',
      () async {
        fillForm();
        expect(await model.submit(), ExpenseFormResult.created);
        expect(await model.submit(), ExpenseFormResult.created);

        final saved = (await fake.getAll())
            .where((expense) => expense.id != original.id)
            .toList();
        expect(saved.length, 2);
        expect(saved.first.id, isNot(saved.last.id));
        expect(saved.first.amount, saved.last.amount);
      },
    );

    for (final editMode in <bool>[false, true]) {
      test(
        '${editMode ? 'edit' : 'add'} ignores duplicate submit and pending edits',
        () async {
          if (editMode) useEditMode();
          fillForm();
          controlled.writeGate = Completer<void>();
          final duplicateResults = <Future<ExpenseFormResult>>[];
          model.addListener(() {
            if (model.state.isSubmitting) duplicateResults.add(model.submit());
          });
          final submission = model.submit();
          final pending = model.state;

          expect(pending.isSubmitting, isTrue);
          expect(await model.submit(), ExpenseFormResult.none);
          expect(await duplicateResults.single, ExpenseFormResult.none);
          model.updateAmount('1');
          model.updateCategory(null);
          model.updateDate(ExpenseDate(1900, 1, 1));
          model.updateNote('changed while saving');
          expect(model.state, same(pending));

          controlled.writeGate!.complete();
          expect(
            await submission,
            editMode ? ExpenseFormResult.updated : ExpenseFormResult.created,
          );
          expect(model.state.isSubmitting, isFalse);
          expect(controlled.createCalls, editMode ? 0 : 1);
          expect(controlled.updateIds, editMode ? <int>[original.id] : isEmpty);
          _expectSameInput(model.state, pending);
        },
      );

      test(
        '${editMode ? 'edit' : 'add'} storage failure keeps input and permits retry',
        () async {
          if (editMode) useEditMode();
          fillForm();
          const failure = StorageFailure(null);
          if (editMode) {
            fake.updateFailure = failure;
          } else {
            fake.createFailure = failure;
          }
          final before = model.state;

          expect(await model.submit(), ExpenseFormResult.none);
          _expectSameInput(model.state, before);
          expect(model.state.submitFailure, same(failure));
          expect(model.state.isSubmitting, isFalse);
          expect(model.state.hasSubmitted, isTrue);
          expect(model.state.isDirty, isTrue);
          expect(model.state.fieldErrors, isEmpty);
          expect(await fake.getAll(), <Expense>[original]);

          fake.createFailure = null;
          fake.updateFailure = null;
          controlled.writeGate = Completer<void>();
          final retry = model.submit();
          expect(model.state.submitFailure, isNull);
          expect(model.state.isSubmitting, isTrue);
          controlled.writeGate!.complete();
          expect(
            await retry,
            editMode ? ExpenseFormResult.updated : ExpenseFormResult.created,
          );
          expect(model.state.submitFailure, isNull);
        },
      );
    }

    test(
      'editing after failure clears feedback and revalidates live',
      () async {
        fillForm();
        fake.createFailure = const StorageFailure(null);
        await model.submit();

        model.updateAmount('0');

        expect(model.state.submitFailure, isNull);
        expect(model.state.fieldErrors['amount'], 'formAmountZero');
        expect(model.state.isDirty, isTrue);
      },
    );

    test(
      'repository validation failure supplies field and submit feedback',
      () async {
        fillForm();
        const failure = ValidationFailure('note', 'formNoteTooLong');
        fake.createFailure = failure;
        final before = model.state;

        expect(await model.submit(), ExpenseFormResult.none);
        expect(model.state.submitFailure, same(failure));
        expect(model.state.fieldErrors, <String, String>{
          'note': 'formNoteTooLong',
        });
        _expectSameInput(model.state, before);
        expect(await fake.getAll(), <Expense>[original]);
      },
    );

    test(
      'missing edited expense preserves input and exposes NotFoundFailure',
      () async {
        useEditMode();
        fillForm();
        await fake.delete(original.id);
        final before = model.state;

        expect(await model.submit(), ExpenseFormResult.none);
        final failure = model.state.submitFailure;
        expect(failure, isA<NotFoundFailure>());
        expect((failure as NotFoundFailure).id, original.id);
        _expectSameInput(model.state, before);
        expect(model.state.isSubmitting, isFalse);
        expect(await fake.getAll(), isEmpty);
      },
    );

    test('unmapped write error becomes an UnexpectedFailure', () async {
      fillForm();
      final error = StateError('unmapped write error');
      controlled.writeError = error;
      final before = model.state;

      expect(await model.submit(), ExpenseFormResult.none);
      final failure = model.state.submitFailure;
      expect(failure, isA<UnexpectedFailure>());
      expect((failure as UnexpectedFailure).cause, same(error));
      _expectSameInput(model.state, before);
      expect(model.state.isSubmitting, isFalse);
      expect(await fake.getAll(), <Expense>[original]);
    });
  });

  group('dispose', () {
    for (final editMode in <bool>[false, true]) {
      for (final shouldFail in <bool>[false, true]) {
        test(
          '${editMode ? 'edit' : 'add'} ignores late ${shouldFail ? 'failure' : 'success'}',
          () async {
            if (editMode) useEditMode();
            fillForm();
            controlled.writeGate = Completer<void>();
            var notifications = 0;
            model.addListener(() => notifications++);
            final submission = model.submit();
            final pending = model.state;
            final before = notifications;
            model.dispose();
            model.dispose();
            if (shouldFail) {
              controlled.writeGate!.completeError(const StorageFailure(null));
            } else {
              controlled.writeGate!.complete();
            }

            expect(
              await submission,
              shouldFail
                  ? ExpenseFormResult.none
                  : editMode
                  ? ExpenseFormResult.updated
                  : ExpenseFormResult.created,
            );
            model.updateAmount('1');
            model.updateCategory(null);
            model.updateDate(ExpenseDate(1900, 1, 1));
            model.updateNote('after disposal');
            expect(await model.submit(), ExpenseFormResult.none);
            expect(notifications, before);
            expect(model.state, same(pending));
            expect(model.state.submitFailure, isNull);
            expect(controlled.createCalls, editMode ? 0 : 1);
            expect(
              controlled.updateIds,
              editMode ? <int>[original.id] : isEmpty,
            );
            // Disposal never takes ownership of the injected repository.
            expect(await fake.getAll(), isNotEmpty);
          },
        );
      }
    }

    test('a disposed valid form never starts a write', () async {
      fillForm();
      final before = model.state;
      model.dispose();

      expect(await model.submit(), ExpenseFormResult.none);
      expect(controlled.createCalls, 0);
      expect(model.state, same(before));
      expect(await fake.getAll(), <Expense>[original]);
    });
  });
}

void _expectSameInput(ExpenseFormState actual, ExpenseFormState expected) {
  expect(actual.amountText, expected.amountText);
  expect(actual.selectedCategory, expected.selectedCategory);
  expect(actual.selectedDate, expected.selectedDate);
  expect(actual.noteText, expected.noteText);
}

/// Controls write scheduling while retaining the shared in-memory fake behavior.
final class _ControlledFormRepository implements ExpenseRepository {
  _ControlledFormRepository(this.delegate);

  final FakeExpenseRepository delegate;
  Completer<void>? writeGate;
  Object? writeError;
  int createCalls = 0;
  final List<int> updateIds = <int>[];

  Future<void> _beforeWrite() async {
    final gate = writeGate;
    if (gate != null) await gate.future;
    final error = writeError;
    if (error != null) throw error;
  }

  @override
  Future<Expense> create(ExpenseDraft draft) async {
    createCalls++;
    await _beforeWrite();
    return delegate.create(draft);
  }

  @override
  Future<Expense> update({required int id, required ExpenseDraft draft}) async {
    updateIds.add(id);
    await _beforeWrite();
    return delegate.update(id: id, draft: draft);
  }

  @override
  Stream<ExpenseChange> get changes => delegate.changes;

  @override
  Future<List<Expense>> getAll() => delegate.getAll();

  @override
  Future<HomeSummary> getHomeSummary({
    required ExpenseMonth month,
    int latestLimit = 5,
  }) => delegate.getHomeSummary(month: month, latestLimit: latestLimit);

  @override
  Future<void> delete(int id) => delegate.delete(id);
}
