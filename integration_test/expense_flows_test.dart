// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:expensetracker/app/app.dart';
import 'package:expensetracker/core/clock/app_clock.dart';
import 'package:expensetracker/core/errors/app_failure.dart';
import 'package:expensetracker/features/expenses/data/expense_database.dart';
import 'package:expensetracker/features/expenses/data/sqlite_expense_repository.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_change.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/domain/expense_month.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';
import 'package:expensetracker/features/expenses/domain/home_summary.dart';
import 'package:expensetracker/features/expenses/presentation/widgets/expense_list_item.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;

  late String testPath;
  late _FlowTestClock clock;
  late ExpenseDatabase database;
  late SqliteExpenseRepository repository;

  setUp(() async {
    final databasesPath = await getDatabasesPath();
    final uniqueName = 'flow_test_${DateTime.now().microsecondsSinceEpoch}.db';
    testPath = p.join(databasesPath, uniqueName);
    clock = _FlowTestClock(DateTime(2026, 10, 12, 10, 0, 0));
    database = ExpenseDatabase(databasePath: testPath);
    repository = SqliteExpenseRepository(database: database, clock: clock);
  });

  tearDown(() async {
    await repository.dispose();
    await database.close();
    if (await databaseExists(testPath)) {
      await deleteDatabase(testPath);
    }
  });

  /// Pumps frames and checks if [finder] is present, repeating until found or [timeout] expires.
  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await Future<void>.delayed(pollInterval);
      await tester.pump();
    }
    throw TimeoutException('Timed out waiting for $finder');
  }

  /// Advances frames by [milliseconds] in real time to allow transitions to complete.
  Future<void> settle(WidgetTester tester, [int milliseconds = 400]) async {
    await Future<void>.delayed(Duration(milliseconds: milliseconds));
    await tester.pump();
  }

  Future<void> waitForDisappear(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      if (finder.evaluate().isEmpty) {
        return;
      }
      await Future<void>.delayed(pollInterval);
      await tester.pump();
    }
    throw TimeoutException('Timed out waiting for $finder to disappear');
  }

  Future<void> openHomeTab(WidgetTester tester) async {
    final scaffold = find.byType(Scaffold);
    if (scaffold.evaluate().isNotEmpty) {
      ScaffoldMessenger.of(tester.element(scaffold.first)).clearSnackBars();
    }
    await settle(tester, 100);
    final destination = find.byIcon(Icons.home_outlined);
    if (destination.evaluate().isNotEmpty) {
      await tester.tap(destination.first);
    } else {
      await tester.tap(find.byIcon(Icons.home).first);
    }
    await settle(tester, 300);
  }

  Future<void> openTransactionsTab(WidgetTester tester) async {
    final scaffold = find.byType(Scaffold);
    if (scaffold.evaluate().isNotEmpty) {
      ScaffoldMessenger.of(tester.element(scaffold.first)).clearSnackBars();
    }
    await settle(tester, 100);
    final destination = find.byIcon(Icons.receipt_long_outlined);
    if (destination.evaluate().isNotEmpty) {
      await tester.tap(destination.first);
    } else {
      await tester.tap(find.byIcon(Icons.receipt_long).first);
    }
    await settle(tester, 300);
  }

  Future<void> fillAndSubmitAddForm(
    WidgetTester tester, {
    required String amount,
    required String categoryLabel,
    String? note,
  }) async {
    print('  [FORM] 1: tap FAB');
    await tester.tap(find.byType(FloatingActionButton));
    await waitFor(tester, find.byKey(const Key('expense_form_amount_field')));

    print('  [FORM] 2: enter amount $amount');
    final amountField = find.byKey(const Key('expense_form_amount_field'));
    await tester.enterText(amountField, amount);
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester, 200);

    print('  [FORM] 3: tap category field');
    final categoryField = find.byKey(const Key('expense_form_category_field'));
    await tester.ensureVisible(categoryField);
    await tester.tap(categoryField);
    await waitFor(tester, find.text(categoryLabel));
    await settle(tester, 500);

    print('  [FORM] 4: tap category $categoryLabel');
    final categoryItem = find.text(categoryLabel).last;
    await tester.ensureVisible(categoryItem);
    await tester.tap(categoryItem);
    await settle(tester, 500);

    if (note != null) {
      print('  [FORM] 5: enter note $note');
      final noteField = find.byKey(const Key('expense_form_note_field'));
      await tester.ensureVisible(noteField);
      await tester.enterText(noteField, note);
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester, 200);
    }

    print('  [FORM] 6: tap submit');
    final submitButton = find.byKey(const Key('expense_form_submit_button'));
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await waitForDisappear(tester, submitButton);
    print('  [FORM] 7: form completed');
  }

  // Pengujian integrasi menyeluruh yang mencakup 9 skenario Technical Design §20.4
  testWidgets(
    'Primary flows: CRUD, persistence, date change, delete, ordering, offline, and fault recovery',
    (tester) async {
      // -----------------------------------------------------------------------
      // Skenario 1: Tambah pengeluaran -> muncul di Home dan Transactions
      // -----------------------------------------------------------------------
      print('>>> [FLOW 1] Skenario 1: Tambah pengeluaran');
      await tester.pumpWidget(MainApp(clock: clock, repository: repository));
      await waitFor(tester, find.text('Rp0'));
      expect(find.text('Belum ada pengeluaran'), findsOneWidget);

      await fillAndSubmitAddForm(
        tester,
        amount: '25000',
        categoryLabel: 'Makanan',
        note: 'Makan siang',
      );

      // Verifikasi di Home
      await waitFor(tester, find.text('Pengeluaran berhasil ditambahkan'));
      await waitFor(tester, find.text('Rp25.000'));
      expect(find.text('Makanan'), findsOneWidget);
      expect(find.text('Makan siang'), findsOneWidget);

      // Verifikasi di Transactions
      await openTransactionsTab(tester);
      await waitFor(tester, find.byType(ExpenseListItem));
      expect(find.text('Makanan'), findsOneWidget);
      expect(find.text('Makan siang'), findsOneWidget);
      expect(find.text('Rp25.000'), findsOneWidget);

      // Verifikasi langsung ke data SQLite
      var allExpenses = await repository.getAll();
      expect(allExpenses.length, 1);
      expect(allExpenses.first.amount, 25000);
      expect(allExpenses.first.category, ExpenseCategory.food);
      expect(allExpenses.first.note, 'Makan siang');

      // -----------------------------------------------------------------------
      // Skenario 2: Tutup/restart aplikasi -> data masih ada di SQLite
      // -----------------------------------------------------------------------
      print('>>> [FLOW 2] Skenario 2: Restart aplikasi (persitensi)');
      final session2Repo = SqliteExpenseRepository(
        database: database,
        clock: clock,
      );
      await tester.pumpWidget(
        MainApp(key: UniqueKey(), clock: clock, repository: session2Repo),
      );
      await waitFor(tester, find.text('Rp25.000'));
      expect(find.text('Makanan'), findsOneWidget);
      expect(find.text('Makan siang'), findsOneWidget);

      // Verifikasi di Transactions sesi baru
      await openTransactionsTab(tester);
      await waitFor(tester, find.byType(ExpenseListItem));
      expect(find.text('Makanan'), findsOneWidget);
      expect(find.text('Makan siang'), findsOneWidget);

      // -----------------------------------------------------------------------
      // Skenario 3: Edit nominal/kategori/catatan -> perubahan tampil
      // -----------------------------------------------------------------------
      print('>>> [FLOW 3] Skenario 3: Edit pengeluaran');
      print('  [SC3] 1: tap popup menu');
      await tester.tap(find.byType(PopupMenuButton<ExpenseListItemAction>));
      print('  [SC3] 2: wait for Edit item');
      await waitFor(tester, find.text('Edit'));
      await settle(tester, 500);
      print('  [SC3] 3: tap Edit item');
      final editItem = find.text('Edit').last;
      await tester.ensureVisible(editItem);
      await tester.tap(editItem);
      print('  [SC3] 4: wait for Edit screen');
      await waitFor(tester, find.text('Edit Pengeluaran'));

      print('  [SC3] 5: enter amount 50000');
      final amountField = find.byKey(const Key('expense_form_amount_field'));
      await tester.enterText(amountField, '50000');
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester, 200);

      print('  [SC3] 6: tap category Transportasi');
      await tester.tap(find.byKey(const Key('expense_form_category_field')));
      await waitFor(tester, find.text('Transportasi'));
      await settle(tester, 500);
      final catTransport = find.text('Transportasi').last;
      await tester.ensureVisible(catTransport);
      await tester.tap(catTransport);
      await settle(tester, 500);

      print('  [SC3] 7: enter note Naik taksi');
      final noteField = find.byKey(const Key('expense_form_note_field'));
      await tester.enterText(noteField, 'Naik taksi');
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester, 200);

      print('  [SC3] 8: tap submit edit');
      final submitEditButton = find.byKey(
        const Key('expense_form_submit_button'),
      );
      await tester.ensureVisible(submitEditButton);
      await tester.tap(submitEditButton);
      await waitForDisappear(tester, submitEditButton);
      print('  [SC3] 9: wait for updated data');
      await waitFor(tester, find.text('Pengeluaran berhasil diperbarui'));
      await waitFor(tester, find.text('Rp50.000'));
      expect(find.text('Transportasi'), findsOneWidget);
      expect(find.text('Naik taksi'), findsOneWidget);

      await openHomeTab(tester);
      await waitFor(tester, find.text('Rp50.000'));
      expect(find.text('Transportasi'), findsOneWidget);
      expect(find.text('Naik taksi'), findsOneWidget);

      allExpenses = await session2Repo.getAll();
      expect(allExpenses.length, 1);
      expect(allExpenses.first.amount, 50000);
      expect(allExpenses.first.category, ExpenseCategory.transportation);
      expect(allExpenses.first.note, 'Naik taksi');
      print('  [SC3] 10: flow 3 finished');

      // -----------------------------------------------------------------------
      // Skenario 4: Edit tanggal ke bulan lain -> total bulanan berubah
      // -----------------------------------------------------------------------
      print('>>> [FLOW 4] Skenario 4: Edit tanggal ke bulan lain');
      print('  [SC4] 1: open transactions tab');
      await openTransactionsTab(tester);
      await waitFor(tester, find.text('Transportasi'));

      print('  [SC4] 2: tap item Transportasi');
      await tester.tap(find.text('Transportasi').first);
      await waitFor(tester, find.byKey(const Key('expense_form_date_field')));

      print('  [SC4] 3: tap date field');
      final dateField = find.byKey(const Key('expense_form_date_field'));
      await tester.ensureVisible(dateField);
      await tester.tap(dateField);
      await waitFor(tester, find.byType(DatePickerDialog));
      await settle(tester, 500);

      print('  [SC4] 4: locate DatePickerDialog');
      final datePicker = tester.element(find.byType(DatePickerDialog));
      final localizations = MaterialLocalizations.of(datePicker);

      print('  [SC4] 5: tap previous month tooltip');
      final prevMonth = find.byTooltip(localizations.previousMonthTooltip);
      await tester.ensureVisible(prevMonth);
      await tester.tap(prevMonth);
      await settle(tester, 500);

      print('  [SC4] 6: select day 15');
      final day15 = find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('15'),
      );
      await tester.ensureVisible(day15.first);
      await tester.tap(day15.first);
      await settle(tester, 300);

      print('  [SC4] 7: tap ok button');
      final okBtn = find.text(localizations.okButtonLabel);
      await tester.ensureVisible(okBtn);
      await tester.tap(okBtn);
      await waitFor(
        tester,
        find.byKey(const Key('expense_form_submit_button')),
      );
      await settle(tester, 500);

      print('  [SC4] 8: tap submit');
      final submitDateButton = find.byKey(
        const Key('expense_form_submit_button'),
      );
      await tester.ensureVisible(submitDateButton);
      await tester.tap(submitDateButton);
      await waitForDisappear(tester, submitDateButton);
      await waitFor(tester, find.text('Pengeluaran berhasil diperbarui'));
      print('  [SC4] 9: date updated successfully');

      await openHomeTab(tester);
      await waitFor(tester, find.text('Rp0'));
      expect(find.text('Transportasi'), findsOneWidget);

      await openTransactionsTab(tester);
      await waitFor(tester, find.text('15 Sep 2026'));
      expect(find.text('Transportasi'), findsOneWidget);

      allExpenses = await session2Repo.getAll();
      expect(allExpenses.first.transactionDate, ExpenseDate(2026, 9, 15));

      // -----------------------------------------------------------------------
      // Skenario 5: Hapus dengan Batal -> data tetap ada
      // -----------------------------------------------------------------------
      print('>>> [FLOW 5] Skenario 5: Batal hapus');
      print('  [SC5] 1: tap popup menu');
      await tester.tap(find.byType(PopupMenuButton<ExpenseListItemAction>));
      print('  [SC5] 2: wait for Hapus item');
      await waitFor(tester, find.text('Hapus'));
      await settle(tester, 500);
      print('  [SC5] 3: tap Hapus item');
      final deleteItem = find.text('Hapus').last;
      await tester.ensureVisible(deleteItem);
      await tester.tap(deleteItem);
      print('  [SC5] 4: wait for confirmation dialog');
      await waitFor(tester, find.text('Hapus pengeluaran?'));
      await settle(tester, 300);

      print('  [SC5] 5: tap cancel button');
      final cancelBtn = find.byKey(const Key('delete_dialog_cancel_button'));
      await tester.ensureVisible(cancelBtn);
      await tester.tap(cancelBtn);
      await waitForDisappear(tester, find.text('Hapus pengeluaran?'));

      expect(find.text('Hapus pengeluaran?'), findsNothing);
      expect(find.text('Transportasi'), findsOneWidget);
      allExpenses = await session2Repo.getAll();
      expect(allExpenses.length, 1);
      print('  [SC5] 6: flow 5 finished');

      // -----------------------------------------------------------------------
      // Skenario 6: Hapus dengan konfirmasi -> data dan total berubah
      // -----------------------------------------------------------------------
      print('>>> [FLOW 6] Skenario 6: Konfirmasi hapus');
      print('  [SC6] 1: tap popup menu');
      await tester.tap(find.byType(PopupMenuButton<ExpenseListItemAction>));
      print('  [SC6] 2: wait for Hapus item');
      await waitFor(tester, find.text('Hapus'));
      await settle(tester, 500);
      print('  [SC6] 3: tap Hapus item');
      final confirmDeleteItem = find.text('Hapus').last;
      await tester.ensureVisible(confirmDeleteItem);
      await tester.tap(confirmDeleteItem);
      print('  [SC6] 4: wait for confirmation dialog');
      await waitFor(tester, find.text('Hapus pengeluaran?'));
      await settle(tester, 300);

      print('  [SC6] 5: tap confirm delete');
      final confirmBtn = find.byKey(const Key('delete_dialog_confirm_button'));
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await waitForDisappear(tester, find.text('Hapus pengeluaran?'));
      await waitFor(tester, find.text('Pengeluaran berhasil dihapus'));
      await waitFor(tester, find.text('Belum ada transaksi'));

      await openHomeTab(tester);
      await waitFor(tester, find.text('Belum ada pengeluaran'));
      expect(find.text('Rp0'), findsWidgets);

      allExpenses = await session2Repo.getAll();
      expect(allExpenses, isEmpty);
      print('  [SC6] 6: flow 6 finished');

      // -----------------------------------------------------------------------
      // Skenario 7: Dua transaksi tanggal sama -> urutan canonical (createdAt DESC, id DESC)
      // -----------------------------------------------------------------------
      print('>>> [FLOW 7] Skenario 7: Canonical ordering');
      print('[SC7] 1: fill form 1 (10:00)');
      clock.value = DateTime(2026, 10, 12, 10, 0, 0);
      await fillAndSubmitAddForm(
        tester,
        amount: '15000',
        categoryLabel: 'Makanan',
        note: 'Transaksi Pertama',
      );
      print('[SC7] 2: fill form 2 (10:05)');
      clock.value = DateTime(2026, 10, 12, 10, 5, 0);
      await fillAndSubmitAddForm(
        tester,
        amount: '35000',
        categoryLabel: 'Belanja',
        note: 'Transaksi Kedua',
      );
      print('[SC7] 3: open transactions');
      await openTransactionsTab(tester);
      await waitFor(tester, find.text('Transaksi Kedua'));
      await waitFor(tester, find.text('Transaksi Pertama'));

      print('[SC7] 4: verify items order');
      final items = tester
          .widgetList<ExpenseListItem>(find.byType(ExpenseListItem))
          .toList();
      expect(items.length, 2);
      expect(items[0].expense.note, 'Transaksi Kedua');
      expect(items[0].expense.amount, 35000);
      expect(items[1].expense.note, 'Transaksi Pertama');
      expect(items[1].expense.amount, 15000);

      allExpenses = await session2Repo.getAll();
      expect(allExpenses[0].note, 'Transaksi Kedua');
      expect(allExpenses[1].note, 'Transaksi Pertama');
      print('[SC7] 5: flow 7 finished');

      // -----------------------------------------------------------------------
      // Skenario 8: Semua alur tanpa koneksi (offline-first, zero network)
      // -----------------------------------------------------------------------
      print('>>> [FLOW 8] Skenario 8: Alur offline');
      await openHomeTab(tester);
      await fillAndSubmitAddForm(
        tester,
        amount: '20000',
        categoryLabel: 'Tagihan',
        note: 'Operasi offline',
      );
      await waitFor(tester, find.text('Pengeluaran berhasil ditambahkan'));
      await waitFor(tester, find.text('Rp20.000'));

      // -----------------------------------------------------------------------
      // Skenario 9: Kegagalan database yang disimulasikan -> error state + retry
      // -----------------------------------------------------------------------
      print('>>> [FLOW 9] Skenario 9: Fault injection and recovery');

      final faultRepo = _FaultInjectionRepository(session2Repo);
      faultRepo.shouldFail = true;

      await tester.pumpWidget(
        MainApp(key: UniqueKey(), clock: clock, repository: faultRepo),
      );
      print('  [SC9] 1: wait for error state');
      await waitFor(tester, find.text('Coba Lagi'));

      print('  [SC9] 2: switch to transactions tab');
      await openTransactionsTab(tester);
      await waitFor(tester, find.widgetWithText(FilledButton, 'Coba Lagi'));

      print('  [SC9] 3: heal repository and retry on transactions');
      faultRepo.shouldFail = false;

      // In IndexedStack, both HomeScreen and TransactionsScreen have 'Coba Lagi'.
      // The last one corresponds to TransactionsScreen (index 1).
      final retryButtonsOnTransactions = find.widgetWithText(
        FilledButton,
        'Coba Lagi',
      );
      await tester.tap(retryButtonsOnTransactions.last);
      await waitFor(tester, find.byType(ExpenseListItem));

      print('  [SC9] 4: switch to home and retry on home');
      await openHomeTab(tester);
      final retryButtonsOnHome = find.widgetWithText(FilledButton, 'Coba Lagi');
      await tester.tap(retryButtonsOnHome.first);
      await waitFor(tester, find.text('Operasi offline'));

      expect(find.text('Coba Lagi'), findsNothing);

      await session2Repo.dispose();
      print('>>> [ALL FLOWS COMPLETED SUCCESSFULLY!]');
    },
  );
}

final class _FlowTestClock implements AppClock {
  _FlowTestClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

/// Decorator repository yang menyimulasikan kegagalan database untuk menguji
/// keandalan error state dan tombol retry tanpa merusak storage fisik.
final class _FaultInjectionRepository implements ExpenseRepository {
  _FaultInjectionRepository(this._delegate);

  final ExpenseRepository _delegate;
  bool shouldFail = false;

  @override
  Stream<ExpenseChange> get changes => _delegate.changes;

  @override
  Future<Expense> create(ExpenseDraft draft) {
    if (shouldFail) {
      throw const StorageFailure('Simulated database write error for testing');
    }
    return _delegate.create(draft);
  }

  @override
  Future<Expense> update({required int id, required ExpenseDraft draft}) {
    if (shouldFail) {
      throw const StorageFailure('Simulated database write error for testing');
    }
    return _delegate.update(id: id, draft: draft);
  }

  @override
  Future<void> delete(int id) {
    if (shouldFail) {
      throw const StorageFailure('Simulated database write error for testing');
    }
    return _delegate.delete(id);
  }

  @override
  Future<List<Expense>> getAll() {
    if (shouldFail) {
      throw const StorageFailure('Simulated database query error for testing');
    }
    return _delegate.getAll();
  }

  @override
  Future<HomeSummary> getHomeSummary({
    required ExpenseMonth month,
    int latestLimit = 5,
  }) {
    if (shouldFail) {
      throw const StorageFailure(
        'Simulated database summary error for testing',
      );
    }
    return _delegate.getHomeSummary(month: month, latestLimit: latestLimit);
  }
}
