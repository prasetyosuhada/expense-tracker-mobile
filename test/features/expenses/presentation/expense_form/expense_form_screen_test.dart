import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_theme.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/presentation/expense_form/expense_form_screen.dart';
import 'package:expensetracker/features/expenses/presentation/expense_form/expense_form_view_model.dart';

import '../../../../helpers/fake_app_clock.dart';
import '../../../../helpers/fake_expense_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  FakeAppClock buildClock() => FakeAppClock(DateTime(2026, 9, 20));
  FakeExpenseRepository buildRepo([FakeAppClock? clock]) =>
      FakeExpenseRepository(clock: clock ?? buildClock());

  ExpenseFormViewModel buildAddViewModel() {
    final clock = buildClock();
    return ExpenseFormViewModel(buildRepo(clock), clock);
  }

  ExpenseFormViewModel buildEditViewModel({required int amount}) {
    final clock = buildClock();
    final expense = Expense(
      id: 1,
      amount: amount,
      category: ExpenseCategory.food,
      transactionDate: ExpenseDate(2026, 9, 20),
      note: null,
      createdAt: DateTime.utc(2026, 9, 20),
      updatedAt: DateTime.utc(2026, 9, 20),
    );
    return ExpenseFormViewModel(buildRepo(clock), clock, expense: expense);
  }

  Widget buildTestWidget(ExpenseFormViewModel viewModel) {
    return MaterialApp(
      theme: AppTheme.light().copyWith(platform: TargetPlatform.android),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ExpenseFormScreen(viewModel: viewModel),
    );
  }

  // ---------------------------------------------------------------------------
  // ThousandsSeparatorInputFormatter unit tests
  // ---------------------------------------------------------------------------

  group('ThousandsSeparatorInputFormatter', () {
    final formatter = ThousandsSeparatorInputFormatter();

    TextEditingValue applyFormat(String text) {
      return formatter.formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
    }

    test('formats 25000 as 25.000', () {
      expect(applyFormat('25000').text, '25.000');
    });

    test('formats 1000000 as 1.000.000', () {
      expect(applyFormat('1000000').text, '1.000.000');
    });

    test('formats 999999999999 as 999.999.999.999', () {
      expect(applyFormat('999999999999').text, '999.999.999.999');
    });

    test('ignores letters and returns only digits formatted', () {
      expect(applyFormat('abc25000xyz').text, '25.000');
    });

    test('returns empty for blank input', () {
      expect(applyFormat('').text, '');
    });

    test('strips leading zeros: 007 becomes 7', () {
      expect(applyFormat('007').text, '7');
    });

    test('strips leading zeros: 01000 becomes 1.000', () {
      expect(applyFormat('01000').text, '1.000');
    });

    test('single digit stays unchanged', () {
      expect(applyFormat('5').text, '5');
    });

    test('cursor stays after typed digit, not at end', () {
      // Simulate inserting '2' in the middle of '5.000'.
      // Old: '5.000', new: '52.000' (user typed '2' after '5').
      const oldValue = TextEditingValue(
        text: '5.000',
        selection: TextSelection.collapsed(offset: 1), // after '5'
      );
      const newValue = TextEditingValue(
        text: '52000', // before re-format
        selection: TextSelection.collapsed(offset: 2), // after '52'
      );
      final result = formatter.formatEditUpdate(oldValue, newValue);
      // Formatted: '52.000', cursor after '52' → offset 2
      expect(result.text, '52.000');
      expect(result.selection.baseOffset, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // ExpenseFormScreen widget tests
  // ---------------------------------------------------------------------------

  group('ExpenseFormScreen — add mode', () {
    testWidgets('shows "Tambah Pengeluaran" title', (tester) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));
      expect(find.text('Tambah Pengeluaran'), findsOneWidget);
    });

    testWidgets('amount field starts empty with "Rp" prefix', (tester) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      // Prefix text 'Rp ' is rendered by prefixText in InputDecoration.
      expect(find.text('Rp '), findsOneWidget);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, '');
    });

    testWidgets('typing 25000 displays 25.000', (tester) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.enterText(find.byType(TextField), '25000');
      await tester.pump();

      expect(find.text('25.000'), findsOneWidget);
    });

    testWidgets('typing letters is ignored', (tester) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, '');
    });

    testWidgets('typing mixed alphanumeric keeps only digits formatted', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.enterText(find.byType(TextField), 'abc5000xyz');
      await tester.pump();

      // Field should show only formatted digits.
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, '5.000');
    });

    testWidgets('viewModel.state.amountText receives raw digits', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.enterText(find.byType(TextField), '75000');
      await tester.pump();

      // ViewModel should hold raw digits, not formatted string.
      expect(vm.state.amountText, '75000');
    });

    testWidgets('999999999999 (max) is accepted — no error shown', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.enterText(find.byType(TextField), '999999999999');
      await tester.pump();

      expect(find.text('999.999.999.999'), findsOneWidget);
      expect(vm.state.amountText, '999999999999');
    });
  });

  group('ExpenseFormScreen — edit mode', () {
    testWidgets('shows "Edit Pengeluaran" title', (tester) async {
      final vm = buildEditViewModel(amount: 35000);
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));
      expect(find.text('Edit Pengeluaran'), findsOneWidget);
    });

    testWidgets('pre-fills amount field formatted for edit mode', (
      tester,
    ) async {
      final vm = buildEditViewModel(amount: 35000);
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, '35.000');
    });
  });

  group('ExpenseFormScreen — amount validation errors', () {
    testWidgets('empty amount after submit shows "Nominal wajib diisi"', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      // Trigger submit with empty amount to expose error.
      await vm.submit();
      await tester.pump();

      expect(find.text('Nominal wajib diisi'), findsOneWidget);
    });

    testWidgets(
      'amount 0 after submit shows "Nominal harus lebih besar dari 0"',
      (tester) async {
        final vm = buildAddViewModel();
        addTearDown(vm.dispose);
        await tester.pumpWidget(buildTestWidget(vm));

        await tester.enterText(find.byType(TextField), '0');
        await tester.pump();

        await vm.submit();
        await tester.pump();

        expect(find.text('Nominal harus lebih besar dari 0'), findsOneWidget);
      },
    );

    testWidgets(
      'amount 1000000000000 after submit shows "Nominal terlalu besar"',
      (tester) async {
        final vm = buildAddViewModel();
        addTearDown(vm.dispose);
        await tester.pumpWidget(buildTestWidget(vm));

        await tester.enterText(find.byType(TextField), '1000000000000');
        await tester.pump();

        await vm.submit();
        await tester.pump();

        expect(find.text('Nominal terlalu besar'), findsOneWidget);
      },
    );
  });
}
