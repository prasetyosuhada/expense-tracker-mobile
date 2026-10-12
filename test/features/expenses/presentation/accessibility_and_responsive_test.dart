import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/app/app.dart';
import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_spacing.dart';
import 'package:expensetracker/core/theme/app_theme.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/domain/expense_draft.dart';
import 'package:expensetracker/features/expenses/presentation/expense_form/expense_form_screen.dart';
import 'package:expensetracker/features/expenses/presentation/expense_form/expense_form_view_model.dart';
import 'package:expensetracker/features/expenses/presentation/home/home_screen.dart';
import 'package:expensetracker/features/expenses/presentation/home/home_view_model.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/delete_expense_dialog.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_screen.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_view_model.dart';
import 'package:expensetracker/features/expenses/presentation/widgets/expense_list_item.dart';

import '../../../helpers/fake_app_clock.dart';
import '../../../helpers/fake_expense_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAppClock clock;
  late FakeExpenseRepository repository;

  setUp(() {
    clock = FakeAppClock(DateTime(2026, 10, 2, 12));
    repository = FakeExpenseRepository(clock: clock);
  });

  tearDown(() async {
    await repository.dispose();
  });

  Widget wrapWithTheme(
    Widget child, {
    double textScale = 1.0,
    Size size = const Size(360, 800),
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        theme: AppTheme.light().copyWith(platform: TargetPlatform.android),
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: child,
      ),
    );
  }

  Expense makeExpense({
    int id = 1,
    int amount = 25000,
    ExpenseCategory category = ExpenseCategory.food,
    ExpenseDate? date,
    String? note = 'Makan siang enak',
  }) {
    return Expense(
      id: id,
      amount: amount,
      category: category,
      transactionDate: date ?? ExpenseDate(2026, 10, 2),
      note: note,
      createdAt: DateTime.utc(2026, 10, 2, 12),
      updatedAt: DateTime.utc(2026, 10, 2, 12),
    );
  }

  group('P3-012: Tap targets >= 48x48dp', () {
    testWidgets('FAB and NavigationBar touch targets meet or exceed 48dp', (
      tester,
    ) async {
      await tester.pumpWidget(MainApp(clock: clock, repository: repository));
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      final fabSize = tester.getSize(fabFinder);
      expect(
        fabSize.width,
        greaterThanOrEqualTo(AppSpacing.touchTarget),
        reason: 'FAB width should be >= 48dp',
      );
      expect(
        fabSize.height,
        greaterThanOrEqualTo(AppSpacing.touchTarget),
        reason: 'FAB height should be >= 48dp',
      );

      final navBarFinder = find.byType(NavigationBar);
      expect(navBarFinder, findsOneWidget);
      final navBarSize = tester.getSize(navBarFinder);
      expect(navBarSize.height, greaterThanOrEqualTo(AppSpacing.touchTarget));

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Transaksi'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'ExpenseListItem three-dots button strictly guarantees 48x48dp',
      (tester) async {
        final expense = makeExpense();
        await tester.pumpWidget(
          wrapWithTheme(
            Scaffold(
              body: ExpenseListItem(
                expense: expense,
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final popupFinder = find.byType(PopupMenuButton<ExpenseListItemAction>);
        expect(popupFinder, findsOneWidget);
        final popupSize = tester.getSize(popupFinder);
        expect(
          popupSize.width,
          greaterThanOrEqualTo(AppSpacing.touchTarget),
          reason: 'Menu button width should be >= 48dp',
        );
        expect(
          popupSize.height,
          greaterThanOrEqualTo(AppSpacing.touchTarget),
          reason: 'Menu button height should be >= 48dp',
        );
      },
    );

    testWidgets('Home screen action buttons meet or exceed 48dp touch target', (
      tester,
    ) async {
      final vm = HomeViewModel(repository, clock)..onPause();
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        wrapWithTheme(
          HomeScreen(viewModel: vm, onViewAll: () {}, onAddExpense: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final viewAllFinder = find.widgetWithText(TextButton, 'Lihat semua');
      expect(viewAllFinder, findsOneWidget);
      final viewAllSize = tester.getSize(viewAllFinder);
      expect(
        viewAllSize.height,
        greaterThanOrEqualTo(AppSpacing.touchTarget),
        reason: 'Lihat semua button height should be >= 48dp',
      );

      final emptyCtaFinder = find.widgetWithText(
        FilledButton,
        'Tambah Pengeluaran',
      );
      expect(emptyCtaFinder, findsOneWidget);
      final emptyCtaSize = tester.getSize(emptyCtaFinder);
      expect(
        emptyCtaSize.height,
        greaterThanOrEqualTo(AppSpacing.touchTarget),
        reason: 'Empty state CTA button height should be >= 48dp',
      );
    });

    testWidgets('Transactions screen action buttons meet or exceed 48dp', (
      tester,
    ) async {
      final vm = TransactionsViewModel(repository);
      addTearDown(vm.dispose);

      await tester.pumpWidget(
        wrapWithTheme(TransactionsScreen(viewModel: vm, onAddExpense: () {})),
      );
      await tester.pumpAndSettle();

      final emptyCtaFinder = find.widgetWithText(
        FilledButton,
        'Tambah Pengeluaran',
      );
      expect(emptyCtaFinder, findsOneWidget);
      final emptyCtaSize = tester.getSize(emptyCtaFinder);
      expect(
        emptyCtaSize.height,
        greaterThanOrEqualTo(AppSpacing.touchTarget),
        reason: 'Empty CTA button height should be >= 48dp',
      );
    });

    testWidgets(
      'ExpenseFormScreen input fields and buttons have touch target >= 48dp',
      (tester) async {
        final vm = ExpenseFormViewModel(repository, clock);
        addTearDown(vm.dispose);

        await tester.pumpWidget(
          wrapWithTheme(ExpenseFormScreen(viewModel: vm)),
        );
        await tester.pumpAndSettle();

        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);
        final backSize = tester.getSize(backButton);
        expect(backSize.width, greaterThanOrEqualTo(AppSpacing.touchTarget));
        expect(backSize.height, greaterThanOrEqualTo(AppSpacing.touchTarget));

        final amountField = find.byKey(const Key('expense_form_amount_field'));
        expect(amountField, findsOneWidget);
        final amountSize = tester.getSize(amountField);
        expect(amountSize.height, greaterThanOrEqualTo(AppSpacing.touchTarget));

        final categoryField = find.byKey(
          const Key('expense_form_category_field'),
        );
        expect(categoryField, findsOneWidget);
        final catSize = tester.getSize(categoryField);
        expect(catSize.height, greaterThanOrEqualTo(AppSpacing.touchTarget));

        final dateField = find.byKey(const Key('expense_form_date_field'));
        expect(dateField, findsOneWidget);
        final dateSize = tester.getSize(dateField);
        expect(dateSize.height, greaterThanOrEqualTo(AppSpacing.touchTarget));

        final submitBtn = find.byKey(const Key('expense_form_submit_button'));
        expect(submitBtn, findsOneWidget);
        final submitSize = tester.getSize(submitBtn);
        expect(
          submitSize.height,
          greaterThanOrEqualTo(AppSpacing.primaryButtonHeight),
          reason: 'Primary CTA submit button should be at least 56dp height',
        );
      },
    );

    testWidgets(
      'DeleteExpenseDialog action buttons guarantee >= 48dp touch target',
      (tester) async {
        final expense = makeExpense();
        final txVm = TransactionsViewModel(repository);
        addTearDown(txVm.dispose);

        await tester.pumpWidget(
          wrapWithTheme(
            Scaffold(
              body: DeleteExpenseDialog(expense: expense, viewModel: txVm),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final cancelFinder = find.byKey(
          const Key('delete_dialog_cancel_button'),
        );
        expect(cancelFinder, findsOneWidget);
        final cancelSize = tester.getSize(cancelFinder);
        expect(cancelSize.height, greaterThanOrEqualTo(AppSpacing.touchTarget));

        final confirmFinder = find.byKey(
          const Key('delete_dialog_confirm_button'),
        );
        expect(confirmFinder, findsOneWidget);
        final confirmSize = tester.getSize(confirmFinder);
        expect(
          confirmSize.height,
          greaterThanOrEqualTo(AppSpacing.touchTarget),
        );
      },
    );

    testWidgets('CategoryPickerSheet options guarantee >= 48dp touch target', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(const Scaffold(body: CategoryPickerSheet())),
      );
      await tester.pumpAndSettle();

      final listTiles = find.byType(ListTile);
      expect(listTiles, findsNWidgets(CategoryPickerSheet.categories.length));
      for (final tile in listTiles.evaluate()) {
        final size = tester.getSize(find.byWidget(tile.widget));
        expect(
          size.height,
          greaterThanOrEqualTo(AppSpacing.touchTarget),
          reason: 'Category tile height should be >= 48dp',
        );
      }
    });
  });

  group('P3-012: Semantics, Tooltips, Live Regions, and ExcludeSemantics', () {
    testWidgets('FAB semantic label and tooltip is "Tambah pengeluaran"', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(MainApp(clock: clock, repository: repository));
        await tester.pumpAndSettle();

        final fabSemanticFinder = find.bySemanticsLabel('Tambah pengeluaran');
        expect(fabSemanticFinder, findsOneWidget);

        final fabTooltipFinder = find.byTooltip('Tambah pengeluaran');
        expect(fabTooltipFinder, findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      'Three dots menu has semantic label "Tindakan transaksi <Kategori> <Nominal>"',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final expense = makeExpense(
            amount: 25000,
            category: ExpenseCategory.food,
          );
          await tester.pumpWidget(
            wrapWithTheme(
              Scaffold(
                body: ExpenseListItem(
                  expense: expense,
                  onEdit: () {},
                  onDelete: () {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          const expectedLabel = 'Tindakan transaksi Makanan Rp25.000';
          final menuFinder = find.bySemanticsLabel(expectedLabel);
          expect(menuFinder, findsOneWidget);

          final tooltipFinder = find.byTooltip(expectedLabel);
          expect(tooltipFinder, findsOneWidget);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'ExpenseFormScreen category and date fields expose semantic hints for errors',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final vm = ExpenseFormViewModel(repository, clock);
          addTearDown(vm.dispose);

          await tester.pumpWidget(
            wrapWithTheme(ExpenseFormScreen(viewModel: vm)),
          );
          await tester.pumpAndSettle();

          // Tap submit without filling anything to trigger validation errors
          await tester.tap(find.byKey(const Key('expense_form_submit_button')));
          await tester.pumpAndSettle();

          // Check category semantics has hint "Kategori wajib dipilih"
          final catSemantics = tester.getSemantics(
            find.byKey(const Key('expense_form_category_field')),
          );
          expect(
            catSemantics.getSemanticsData().hint.contains(
              'Kategori wajib dipilih',
            ),
            isTrue,
          );

          // Verify the error text is rendered in the widget tree and linked
          expect(find.text('Kategori wajib dipilih'), findsOneWidget);
          expect(find.text('Nominal wajib diisi'), findsOneWidget);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'SnackBars have liveRegion enabled for screen reader announcements',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MainApp(clock: clock, repository: repository),
          );
          await tester.pumpAndSettle();

          // Tap FAB to open form
          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle();

          // Fill valid data
          await tester.enterText(
            find.byKey(const Key('expense_form_amount_field')),
            '35000',
          );
          await tester.tap(
            find.byKey(const Key('expense_form_category_field')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Transportasi'));
          await tester.pumpAndSettle();

          // Save
          await tester.tap(find.byKey(const Key('expense_form_submit_button')));
          await tester.pumpAndSettle();

          // Expect snackbar appears
          const successText = 'Pengeluaran berhasil ditambahkan';
          expect(find.text(successText), findsOneWidget);

          // Find the Semantics widget containing the message
          final snackBarSemantics = find.ancestor(
            of: find.text(successText),
            matching: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.liveRegion == true,
            ),
          );
          expect(
            snackBarSemantics,
            findsAtLeastNWidgets(1),
            reason: 'Success SnackBar text must be wrapped in Semantics(liveRegion: true)',
          );

          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('Decorative icons are excluded from semantics', (tester) async {
      final expense = makeExpense();
      await tester.pumpWidget(
        wrapWithTheme(
          Scaffold(
            body: ExpenseListItem(
              expense: expense,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Category icon in ExpenseListItem is inside ExcludeSemantics
      final categoryCircleFinder = find.byWidgetPredicate(
        (w) =>
            w is ExcludeSemantics &&
            w.child is Container &&
            (w.child as Container).decoration is BoxDecoration,
      );
      expect(categoryCircleFinder, findsOneWidget);

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<ExpenseListItemAction>));
      await tester.pumpAndSettle();

      // Edit and delete icons inside popup menu are wrapped in ExcludeSemantics
      final editIconExcluded = find.ancestor(
        of: find.byIcon(Icons.edit_outlined),
        matching: find.byType(ExcludeSemantics),
      );
      expect(editIconExcluded, findsOneWidget);

      final deleteIconExcluded = find.ancestor(
        of: find.byIcon(Icons.delete_outline),
        matching: find.byType(ExcludeSemantics),
      );
      expect(deleteIconExcluded, findsOneWidget);
    });
  });

  group('P3-012: Responsive layout on 320dp width & 2.0 text scale', () {
    testWidgets(
      'HomeScreen renders without horizontal overflow on 320dp with 2.0 text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await repository.create(
          ExpenseDraft(
            amount: 150000,
            category: ExpenseCategory.food,
            transactionDate: ExpenseDate(2026, 10, 2),
            note: 'Makan malam romantis berdua di restoran',
          ),
        );

        final vm = HomeViewModel(repository, clock)..onPause();
        addTearDown(vm.dispose);

        await tester.pumpWidget(
          wrapWithTheme(
            HomeScreen(viewModel: vm, onViewAll: () {}, onAddExpense: () {}),
            textScale: 2.0,
            size: const Size(320, 640),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Pengeluaran'), findsOneWidget);
        expect(find.text('Total pengeluaran'), findsOneWidget);

        await tester.scrollUntilVisible(find.text('Lihat semua'), 100);
        expect(find.text('Lihat semua'), findsOneWidget);
      },
    );

    testWidgets(
      'TransactionsScreen with maximum amount (Rp999.999.999.999) has no overflow on 320dp',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await repository.create(
          ExpenseDraft(
            amount: 999999999999,
            category: ExpenseCategory.transportation,
            transactionDate: ExpenseDate(2026, 10, 2),
            note: 'Beli kendaraan operasional kantor',
          ),
        );

        final vm = TransactionsViewModel(repository);
        addTearDown(vm.dispose);

        await tester.pumpWidget(
          wrapWithTheme(
            TransactionsScreen(viewModel: vm, onAddExpense: () {}),
            textScale: 2.0,
            size: const Size(320, 640),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Transportasi'), findsOneWidget);
        expect(find.text('Rp999.999.999.999'), findsOneWidget);

        // Verify the three dots menu is still visible and tappable
        final menuFinder = find.byType(PopupMenuButton<ExpenseListItemAction>);
        expect(menuFinder, findsOneWidget);
        await tester.tap(menuFinder);
        await tester.pumpAndSettle();

        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Hapus'), findsOneWidget);
      },
    );

    testWidgets(
      'ExpenseFormScreen renders without overflow on 320dp with 2.0 text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final vm = ExpenseFormViewModel(repository, clock);
        addTearDown(vm.dispose);

        await tester.pumpWidget(
          wrapWithTheme(
            ExpenseFormScreen(viewModel: vm),
            textScale: 2.0,
            size: const Size(320, 640),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final submitBtn = find.byKey(const Key('expense_form_submit_button'));
        expect(submitBtn, findsOneWidget);

        // Ensure submit button is scrolled into view and tapped
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Nominal wajib diisi'), findsOneWidget);
      },
    );

    testWidgets(
      'CategoryPickerSheet renders scrollable without overflow on small screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithTheme(
            const Scaffold(
              body: CategoryPickerSheet(selectedCategory: ExpenseCategory.food),
            ),
            textScale: 2.0,
            size: const Size(320, 480),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Pilih Kategori'), findsOneWidget);

        // Select category
        await tester.tap(find.text('Belanja'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'DeleteExpenseDialog renders without overflow on 320dp with 2.0 text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final expense = makeExpense(
          amount: 50000000,
          category: ExpenseCategory.bills,
        );
        final txVm = TransactionsViewModel(repository);
        addTearDown(txVm.dispose);

        await tester.pumpWidget(
          wrapWithTheme(
            Scaffold(
              body: DeleteExpenseDialog(expense: expense, viewModel: txVm),
            ),
            textScale: 2.0,
            size: const Size(320, 640),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Hapus pengeluaran?'), findsOneWidget);

        final cancelFinder = find.byKey(
          const Key('delete_dialog_cancel_button'),
        );
        expect(cancelFinder, findsOneWidget);
        final confirmFinder = find.byKey(
          const Key('delete_dialog_confirm_button'),
        );
        expect(confirmFinder, findsOneWidget);
      },
    );
  });
}
