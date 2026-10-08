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

  ExpenseFormViewModel buildEditViewModel({
    required int amount,
    ExpenseCategory category = ExpenseCategory.food,
    ExpenseDate? transactionDate,
    String? note,
  }) {
    final clock = buildClock();
    final expense = Expense(
      id: 1,
      amount: amount,
      category: category,
      transactionDate: transactionDate ?? ExpenseDate(2026, 9, 20),
      note: note,
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

  final amountFieldFinder = find.byKey(const Key('expense_form_amount_field'));
  final categoryFieldFinder = find.byKey(
    const Key('expense_form_category_field'),
  );
  final dateFieldFinder = find.byKey(const Key('expense_form_date_field'));
  final noteFieldFinder = find.byKey(const Key('expense_form_note_field'));

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

  group('GraphemeLengthLimitingTextInputFormatter', () {
    const formatter = GraphemeLengthLimitingTextInputFormatter(5);

    TextEditingValue applyFormat(String text) {
      return formatter.formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
    }

    test('accepts text within grapheme limit', () {
      expect(applyFormat('hello').text, 'hello');
    });

    test('truncates text exceeding limit to max graphemes', () {
      expect(applyFormat('helloworld').text, 'hello');
    });

    test('treats compound emoji as single grapheme', () {
      expect(applyFormat('👨‍👩‍👧‍👦abcd').text, '👨‍👩‍👧‍👦abcd');
      expect(applyFormat('👨‍👩‍👧‍👦abcde').text, '👨‍👩‍👧‍👦abcd');
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

      final field = tester.widget<TextField>(amountFieldFinder);
      expect(field.controller?.text, '');
    });

    testWidgets('typing 25000 displays 25.000', (tester) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.enterText(amountFieldFinder, '25000');
      await tester.pump();

      expect(find.text('25.000'), findsOneWidget);
    });

    testWidgets('typing letters is ignored', (tester) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.enterText(amountFieldFinder, 'abc');
      await tester.pump();

      final field = tester.widget<TextField>(amountFieldFinder);
      expect(field.controller?.text, '');
    });

    testWidgets('typing mixed alphanumeric keeps only digits formatted', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.enterText(amountFieldFinder, 'abc5000xyz');
      await tester.pump();

      // Field should show only formatted digits.
      final field = tester.widget<TextField>(amountFieldFinder);
      expect(field.controller?.text, '5.000');
    });

    testWidgets('viewModel.state.amountText receives raw digits', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.enterText(amountFieldFinder, '75000');
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

      await tester.enterText(amountFieldFinder, '999999999999');
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

      final field = tester.widget<TextField>(amountFieldFinder);
      expect(field.controller?.text, '35.000');
    });

    testWidgets('pre-selects category in edit mode', (tester) async {
      final vm = buildEditViewModel(
        amount: 35000,
        category: ExpenseCategory.transportation,
      );
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      expect(find.text('Transportasi'), findsOneWidget);
    });

    testWidgets('pre-fills date and note in edit mode', (tester) async {
      final vm = buildEditViewModel(
        amount: 35000,
        transactionDate: ExpenseDate(2026, 8, 15),
        note: 'Catatan makan siang',
      );
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      expect(find.text('15 Agustus 2026'), findsOneWidget);
      expect(find.text('Catatan makan siang'), findsOneWidget);
      expect(find.text('19/100'), findsOneWidget);
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

        await tester.enterText(amountFieldFinder, '0');
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

        await tester.enterText(amountFieldFinder, '1000000000000');
        await tester.pump();

        await vm.submit();
        await tester.pump();

        expect(find.text('Nominal terlalu besar'), findsOneWidget);
      },
    );
  });

  group('ExpenseFormScreen — category field & bottom sheet', () {
    testWidgets('shows "Pilih kategori" placeholder initially in add mode', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      expect(find.text('Pilih kategori'), findsOneWidget);
      expect(vm.state.selectedCategory, isNull);
    });

    testWidgets(
      'tapping category field opens bottom sheet with 5 categories in order',
      (tester) async {
        final vm = buildAddViewModel();
        addTearDown(vm.dispose);
        await tester.pumpWidget(buildTestWidget(vm));

        await tester.tap(categoryFieldFinder);
        await tester.pumpAndSettle();

        // Modal bottom sheet header
        expect(find.text('Pilih Kategori'), findsOneWidget);

        // Verify all 5 categories are present
        expect(find.text('Makanan'), findsOneWidget);
        expect(find.text('Transportasi'), findsOneWidget);
        expect(find.text('Belanja'), findsOneWidget);
        expect(find.text('Tagihan'), findsOneWidget);
        expect(find.text('Lainnya'), findsOneWidget);

        // Verify vertical order (top to bottom)
        final foodY = tester.getTopLeft(find.text('Makanan')).dy;
        final transY = tester.getTopLeft(find.text('Transportasi')).dy;
        final shopY = tester.getTopLeft(find.text('Belanja')).dy;
        final billsY = tester.getTopLeft(find.text('Tagihan')).dy;
        final otherY = tester.getTopLeft(find.text('Lainnya')).dy;

        expect(foodY < transY, isTrue);
        expect(transY < shopY, isTrue);
        expect(shopY < billsY, isTrue);
        expect(billsY < otherY, isTrue);
      },
    );

    testWidgets('selecting "Makanan" closes sheet and updates field', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.tap(categoryFieldFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Makanan'));
      await tester.pumpAndSettle();

      // Bottom sheet closed
      expect(find.text('Pilih Kategori'), findsNothing);
      // Field displays selected category
      expect(find.text('Makanan'), findsOneWidget);
      expect(vm.state.selectedCategory, ExpenseCategory.food);
    });

    testWidgets('all 5 categories can be selected', (tester) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      const cases = [
        (ExpenseCategory.food, 'Makanan'),
        (ExpenseCategory.transportation, 'Transportasi'),
        (ExpenseCategory.shopping, 'Belanja'),
        (ExpenseCategory.bills, 'Tagihan'),
        (ExpenseCategory.other, 'Lainnya'),
      ];

      for (final (category, label) in cases) {
        await tester.tap(categoryFieldFinder);
        await tester.pumpAndSettle();

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(find.text(label), findsOneWidget);
        expect(vm.state.selectedCategory, category);
      }
    });

    testWidgets(
      'submitting without category displays "Kategori wajib dipilih"',
      (tester) async {
        final vm = buildAddViewModel();
        addTearDown(vm.dispose);
        await tester.pumpWidget(buildTestWidget(vm));

        await vm.submit();
        await tester.pump();

        expect(find.text('Kategori wajib dipilih'), findsOneWidget);
      },
    );

    testWidgets('selecting a category clears "Kategori wajib dipilih" error', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await vm.submit();
      await tester.pump();

      expect(find.text('Kategori wajib dipilih'), findsOneWidget);

      await tester.tap(categoryFieldFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Makanan'));
      await tester.pumpAndSettle();

      expect(find.text('Kategori wajib dipilih'), findsNothing);
      expect(find.text('Makanan'), findsOneWidget);
    });

    testWidgets(
      'bottom sheet shows active check indicator for selected category',
      (tester) async {
        final vm = buildEditViewModel(
          amount: 50000,
          category: ExpenseCategory.bills,
        );
        addTearDown(vm.dispose);
        await tester.pumpWidget(buildTestWidget(vm));

        await tester.tap(categoryFieldFinder);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsOneWidget);
      },
    );

    testWidgets(
      'dismissing bottom sheet retains previously selected category',
      (tester) async {
        final vm = buildEditViewModel(
          amount: 50000,
          category: ExpenseCategory.shopping,
        );
        addTearDown(vm.dispose);
        await tester.pumpWidget(buildTestWidget(vm));

        await tester.tap(categoryFieldFinder);
        await tester.pumpAndSettle();

        // Dismiss by tapping barrier (scrim)
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        expect(find.text('Belanja'), findsOneWidget);
        expect(vm.state.selectedCategory, ExpenseCategory.shopping);
      },
    );
  });

  group('ExpenseFormScreen — date field & picker', () {
    testWidgets('displays initial date formatted in Indonesian', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      // Built with fake clock at 2026-09-20
      expect(find.text('20 September 2026'), findsOneWidget);
    });

    testWidgets('tap date field opens Material date picker dialog', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.tap(dateFieldFinder);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('cancelling date picker retains previous date', (tester) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.tap(dateFieldFinder);
      await tester.pumpAndSettle();

      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );
      await tester.tap(find.text(localizations.cancelButtonLabel));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.text('20 September 2026'), findsOneWidget);
      expect(vm.state.selectedDate, ExpenseDate(2026, 9, 20));
    });

    testWidgets('selecting date in picker updates field and view model', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.tap(dateFieldFinder);
      await tester.pumpAndSettle();

      // Pick day '25'
      await tester.tap(find.text('25'));
      await tester.pumpAndSettle();

      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );
      await tester.tap(find.text(localizations.okButtonLabel));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.text('25 September 2026'), findsOneWidget);
      expect(vm.state.selectedDate, ExpenseDate(2026, 9, 25));
    });
  });

  group('ExpenseFormScreen — note field & counter', () {
    testWidgets('starts empty with 0/100 counter and placeholder', (
      tester,
    ) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      expect(find.text('0/100'), findsOneWidget);
      expect(find.text('Contoh: Makan siang bersama teman'), findsOneWidget);
    });

    testWidgets('typing 50 characters shows 50/100', (tester) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      final text50 = 'a' * 50;
      await tester.enterText(noteFieldFinder, text50);
      await tester.pump();

      expect(find.text('50/100'), findsOneWidget);
      expect(vm.state.noteText, text50);
    });

    testWidgets(
      'typing 100 characters shows 100/100; 101st character is blocked',
      (tester) async {
        final vm = buildAddViewModel();
        addTearDown(vm.dispose);
        await tester.pumpWidget(buildTestWidget(vm));

        final text105 = 'b' * 105;
        await tester.enterText(noteFieldFinder, text105);
        await tester.pump();

        expect(find.text('100/100'), findsOneWidget);
        final field = tester.widget<TextField>(noteFieldFinder);
        expect(field.controller?.text.length, 100);
        expect(vm.state.noteText.length, 100);
      },
    );

    testWidgets('compound emoji is counted as 1 by counter', (tester) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      // 👨‍👩‍👧‍👦 is a multi-code-point emoji (ZWH sequence) but 1 grapheme
      await tester.enterText(noteFieldFinder, '👨‍👩‍👧‍👦');
      await tester.pump();

      expect(find.text('1/100'), findsOneWidget);

      await tester.enterText(noteFieldFinder, '👨‍👩‍👧‍👦ab');
      await tester.pump();

      expect(find.text('3/100'), findsOneWidget);
    });

    testWidgets('newline is counted as 1 character by counter', (tester) async {
      final vm = buildAddViewModel();
      addTearDown(vm.dispose);
      await tester.pumpWidget(buildTestWidget(vm));

      await tester.enterText(noteFieldFinder, 'a\nb');
      await tester.pump();

      expect(find.text('3/100'), findsOneWidget);
    });
  });
}
