import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/core/formatting/id_date_formatter.dart';
import 'package:expensetracker/core/formatting/idr_formatter.dart';
import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_colors.dart';
import 'package:expensetracker/core/theme/app_shapes.dart';
import 'package:expensetracker/core/theme/app_spacing.dart';
import 'package:expensetracker/core/theme/app_theme.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/domain/expense_date.dart';
import 'package:expensetracker/features/expenses/presentation/widgets/expense_list_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Expense createExpense({
    int id = 1,
    int amount = 25000,
    ExpenseCategory category = ExpenseCategory.food,
    ExpenseDate? transactionDate,
    String? note = 'Makan siang',
  }) {
    return Expense(
      id: id,
      amount: amount,
      category: category,
      transactionDate: transactionDate ?? ExpenseDate(2026, 9, 20),
      note: note,
      createdAt: DateTime.utc(2026, 9, 20, 12),
      updatedAt: DateTime.utc(2026, 9, 20, 12),
    );
  }

  Widget buildTestWidget({
    required Expense expense,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    IdrFormatter? amountFormatter,
    IdDateFormatter? dateFormatter,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: AppTheme.light().copyWith(platform: TargetPlatform.android),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: Center(child: child!)),
      ),
      home: ExpenseListItem(
        expense: expense,
        onTap: onTap,
        onEdit: onEdit,
        onDelete: onDelete,
        amountFormatter: amountFormatter,
        dateFormatter: dateFormatter,
      ),
    );
  }

  void setViewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  group('ExpenseListItem visual elements', () {
    testWidgets(
      'renders category icon and 40dp colored circle for each category',
      (tester) async {
        const categoryCases = <(ExpenseCategory, IconData, Color, Color)>[
          (
            ExpenseCategory.food,
            Icons.restaurant,
            AppColors.foodBackground,
            AppColors.foodForeground,
          ),
          (
            ExpenseCategory.transportation,
            Icons.directions_car,
            AppColors.transportationBackground,
            AppColors.transportationForeground,
          ),
          (
            ExpenseCategory.shopping,
            Icons.shopping_bag,
            AppColors.shoppingBackground,
            AppColors.shoppingForeground,
          ),
          (
            ExpenseCategory.bills,
            Icons.receipt_long,
            AppColors.billsBackground,
            AppColors.billsForeground,
          ),
          (
            ExpenseCategory.other,
            Icons.more_horiz,
            AppColors.otherBackground,
            AppColors.otherForeground,
          ),
        ];

        for (final testCase in categoryCases) {
          final expense = createExpense(category: testCase.$1);
          await tester.pumpWidget(buildTestWidget(expense: expense));

          final iconFinder = find.byIcon(testCase.$2);
          expect(iconFinder, findsOneWidget);

          final iconWidget = tester.widget<Icon>(iconFinder);
          expect(iconWidget.color, equals(testCase.$4));

          final containerFinder = find.ancestor(
            of: iconFinder,
            matching: find.byType(Container),
          );
          expect(containerFinder, findsOneWidget);

          final containerWidget = tester.widget<Container>(containerFinder);
          expect(
            containerWidget.constraints?.maxWidth,
            equals(AppSpacing.categoryCircle),
          );
          expect(
            containerWidget.constraints?.maxHeight,
            equals(AppSpacing.categoryCircle),
          );

          final boxDecoration = containerWidget.decoration as BoxDecoration;
          expect(boxDecoration.shape, equals(BoxShape.circle));
          expect(boxDecoration.color, equals(testCase.$3));

          expect(
            find.ancestor(
              of: containerFinder,
              matching: find.byType(ExcludeSemantics),
            ),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets('renders localized category name, formatted date, and amount', (
      tester,
    ) async {
      final expense = createExpense(
        amount: 35000,
        category: ExpenseCategory.transportation,
        transactionDate: ExpenseDate(2026, 9, 7),
        note: null,
      );

      await tester.pumpWidget(buildTestWidget(expense: expense));

      expect(find.text('Transportasi'), findsOneWidget);
      expect(find.text('7 Sep 2026'), findsOneWidget);
      expect(find.text('Rp35.000'), findsOneWidget);
    });

    testWidgets('renders note with max 2 lines and ellipsis when present', (
      tester,
    ) async {
      const longNote =
          'Makan siang bersama tim di warung nasi padang langganan';
      final expense = createExpense(note: longNote);

      await tester.pumpWidget(buildTestWidget(expense: expense));

      final noteFinder = find.text(longNote);
      expect(noteFinder, findsOneWidget);

      final noteText = tester.widget<Text>(noteFinder);
      expect(noteText.maxLines, equals(2));
      expect(noteText.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('renders no note text or placeholder when note is null', (
      tester,
    ) async {
      final expense = createExpense(note: null);

      await tester.pumpWidget(buildTestWidget(expense: expense));

      expect(find.text('Makan siang'), findsNothing);
      expect(find.text('-'), findsNothing);
      expect(find.text(''), findsNothing);
    });

    testWidgets('renders card with cardRadius, subtle border, and InkWell', (
      tester,
    ) async {
      final expense = createExpense();
      await tester.pumpWidget(buildTestWidget(expense: expense, onTap: () {}));

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.clipBehavior, equals(Clip.antiAlias));

      final material = tester.widget<Material>(
        find
            .descendant(of: find.byType(Card), matching: find.byType(Material))
            .first,
      );
      final shape = material.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, equals(AppShapes.cardRadius));
      expect(shape.side.color, equals(AppColors.borderSubtle));

      final inkWell = tester.widget<InkWell>(
        find
            .descendant(of: find.byType(Card), matching: find.byType(InkWell))
            .first,
      );
      expect(inkWell.highlightColor, equals(AppColors.surfaceActive));
      expect(inkWell.splashColor, equals(AppColors.transparent));
    });
  });

  group('ExpenseListItem responsive & overflow', () {
    testWidgets(
      'long amount does not overflow on 320dp viewport with text scale 2.0',
      (tester) async {
        setViewport(tester, const Size(320, 640));

        final expense = Expense(
          id: 99,
          amount: 999999999999,
          category: ExpenseCategory.transportation,
          transactionDate: ExpenseDate(2026, 9, 20),
          note: List<String>.filled(15, 'catatan').join(' '),
          createdAt: DateTime.utc(2026, 9, 20, 12),
          updatedAt: DateTime.utc(2026, 9, 20, 12),
        );

        await tester.pumpWidget(
          buildTestWidget(expense: expense, textScale: 2.0),
        );
        await tester.pumpAndSettle();

        expect(find.text('Rp999.999.999.999'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('ExpenseListItem interactions & menu', () {
    testWidgets('tapping item triggers onTap callback', (tester) async {
      var tapped = false;
      final expense = createExpense();

      await tester.pumpWidget(
        buildTestWidget(expense: expense, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(ExpenseListItem));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('tapping ⋮ opens menu with Edit and Hapus', (tester) async {
      final expense = createExpense();

      await tester.pumpWidget(buildTestWidget(expense: expense));

      final menuButton = find.byType(PopupMenuButton<ExpenseListItemAction>);
      expect(menuButton, findsOneWidget);

      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      expect(find.text('Hapus'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      final deleteText = tester.widget<Text>(find.text('Hapus'));
      expect(deleteText.style?.color, equals(AppColors.danger));

      final deleteIcon = tester.widget<Icon>(find.byIcon(Icons.delete_outline));
      expect(deleteIcon.color, equals(AppColors.danger));
    });

    testWidgets('selecting Edit in menu triggers onEdit callback', (
      tester,
    ) async {
      var editCalled = false;
      var tapCalled = false;
      final expense = createExpense();

      await tester.pumpWidget(
        buildTestWidget(
          expense: expense,
          onTap: () => tapCalled = true,
          onEdit: () => editCalled = true,
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<ExpenseListItemAction>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(editCalled, isTrue);
      expect(tapCalled, isFalse);
    });

    testWidgets('selecting Hapus in menu triggers onDelete callback', (
      tester,
    ) async {
      var deleteCalled = false;
      var tapCalled = false;
      final expense = createExpense();

      await tester.pumpWidget(
        buildTestWidget(
          expense: expense,
          onTap: () => tapCalled = true,
          onDelete: () => deleteCalled = true,
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<ExpenseListItemAction>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
      expect(tapCalled, isFalse);
    });

    testWidgets('three dots menu has correct semantic label format', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final expense = createExpense(
          amount: 25000,
          category: ExpenseCategory.food,
        );

        await tester.pumpWidget(buildTestWidget(expense: expense));

        const expectedLabel = 'Tindakan transaksi Makanan Rp25.000';

        final menuFinder = find.bySemanticsLabel(expectedLabel);
        expect(menuFinder, findsOneWidget);

        final tooltipFinder = find.byTooltip(expectedLabel);
        expect(tooltipFinder, findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('custom formatters can be injected', (tester) async {
      final expense = createExpense(
        amount: 50000,
        transactionDate: ExpenseDate(2026, 9, 20),
      );

      await tester.pumpWidget(
        buildTestWidget(
          expense: expense,
          amountFormatter: IdrFormatter(),
          dateFormatter: IdDateFormatter(),
        ),
      );

      expect(find.text('Rp50.000'), findsOneWidget);
      expect(find.text('20 Sep 2026'), findsOneWidget);
    });
  });
}
