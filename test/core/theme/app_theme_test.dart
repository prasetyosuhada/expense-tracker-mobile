import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expensetracker/core/theme/app_colors.dart';
import 'package:expensetracker/core/theme/app_theme.dart';
import 'package:expensetracker/core/theme/category_colors.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';

void main() {
  group('semantic foundation', () {
    test('palette matches the specified RGB and rounded alpha values', () {
      final colors = <Color, int>{
        AppColors.primary: 0xFF9FE870,
        AppColors.onPrimary: 0xFF163300,
        AppColors.primaryHover: 0xFFCDFFAD,
        AppColors.primaryPressed: 0xFF8AD05E,
        AppColors.primarySubtle: 0xFFE2F6D5,
        AppColors.canvas: 0xFFFAFAFA,
        AppColors.backgroundMuted: 0xFFF5F6F4,
        AppColors.surface: 0xFFFFFFFF,
        AppColors.surfaceMuted: 0xFFE8EBE6,
        AppColors.surfaceActive: 0xFFE0E4DD,
        AppColors.textPrimary: 0xFF0E0F0C,
        AppColors.textSecondary: 0xFF454745,
        AppColors.textMuted: 0xFF686868,
        AppColors.link: 0xFF2D7A1A,
        AppColors.danger: 0xFFD03238,
        AppColors.dangerPressed: 0xFFB22A30,
        AppColors.success: 0xFF054D28,
        AppColors.borderDefault: 0x7A0E0F0C,
        AppColors.borderSubtle: 0x0F0E0F0C,
        AppColors.divider: 0x140E0F0C,
        AppColors.focusRing: 0x99163300,
        AppColors.overlay: 0x800E0F0C,
        AppColors.snackbar: 0xFF1E201C,
        AppColors.onSnackbar: 0xFFFCFCFC,
      };
      for (final entry in colors.entries) {
        expect(entry.key.toARGB32(), entry.value);
      }
    });

    test('Material 3 uses explicit semantic colors without a surface tint', () {
      final theme = AppTheme.light();
      final colors = theme.colorScheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(colors.primary, AppColors.primary);
      expect(colors.onPrimary, AppColors.onPrimary);
      expect(colors.primaryContainer, AppColors.primarySubtle);
      expect(colors.surface, AppColors.surface);
      expect(colors.surfaceContainer, AppColors.backgroundMuted);
      expect(colors.surfaceContainerHighest, AppColors.surfaceMuted);
      expect(colors.onSurface, AppColors.textPrimary);
      expect(colors.onSurfaceVariant, AppColors.textSecondary);
      expect(colors.outline, AppColors.borderDefault);
      expect(colors.outlineVariant, AppColors.divider);
      expect(colors.error, AppColors.danger);
      expect(colors.onError, AppColors.surface);
      expect(colors.scrim, AppColors.overlay);
      expect(colors.surfaceTint, AppColors.transparent);
      expect(theme.scaffoldBackgroundColor, AppColors.canvas);
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      expect(theme.visualDensity, VisualDensity.standard);
    });

    test(
      'font roles retain their local family, size, weight, and line height',
      () {
        final text = AppTheme.light().textTheme;
        final roles = <TextStyle?, (String, double, FontWeight, double)>{
          text.displaySmall: ('Geist', 40, FontWeight.w900, 1.1),
          text.headlineMedium: ('Geist', 26, FontWeight.w900, 1.1),
          text.headlineSmall: ('Geist', 26, FontWeight.w700, 1.1),
          text.titleMedium: ('Inter', 18, FontWeight.w600, 1.23),
          text.titleSmall: ('Inter', 16, FontWeight.w600, 1.23),
          text.bodyLarge: ('Inter', 16, FontWeight.w400, 1.44),
          text.bodyMedium: ('Inter', 14, FontWeight.w400, 1.55),
          text.labelLarge: ('Inter', 18, FontWeight.w600, 1),
          text.labelMedium: ('Inter', 14, FontWeight.w600, 1.55),
          text.bodySmall: ('Inter', 12, FontWeight.w400, 1.55),
        };
        for (final entry in roles.entries) {
          final style = entry.key!;
          expect(style.fontFamily, entry.value.$1);
          expect(style.fontSize, entry.value.$2);
          expect(style.fontWeight, entry.value.$3);
          expect(style.height, entry.value.$4);
        }
        expect(text.displaySmall!.fontFeatures, isNotEmpty);
        expect(text.titleSmall!.fontFeatures, isNotEmpty);
      },
    );

    test(
      'specified text pairs keep at least 4.5 to 1 contrast in button states',
      () {
        final scheme = AppTheme.light().colorScheme;
        final pairs = <(Color, Color)>[
          (AppColors.onPrimary, AppColors.primary),
          (AppColors.onPrimary, AppColors.primaryPressed),
          (AppColors.onPrimary, AppColors.primaryHover),
          (AppColors.textPrimary, AppColors.canvas),
          (AppColors.textPrimary, AppColors.surface),
          (AppColors.textSecondary, AppColors.surfaceMuted),
          (AppColors.textMuted, AppColors.surfaceMuted),
          (AppColors.surface, AppColors.danger),
          (AppColors.onSnackbar, AppColors.snackbar),
          (scheme.onErrorContainer, scheme.errorContainer),
        ];
        for (final pair in pairs) {
          expect(_contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
        }
        for (final category in ExpenseCategory.values) {
          expect(
            _contrast(
              CategoryColors.light.foregroundFor(category),
              CategoryColors.light.backgroundFor(category),
            ),
            greaterThanOrEqualTo(4.5),
          );
        }
      },
    );

    test(
      'primary button resolves pressed, hover, focus, and disabled states',
      () {
        final style = AppTheme.light().filledButtonTheme.style!;
        expect(
          style.backgroundColor!.resolve(<WidgetState>{}),
          AppColors.primary,
        );
        expect(
          style.backgroundColor!.resolve(<WidgetState>{WidgetState.pressed}),
          AppColors.primaryPressed,
        );
        expect(
          style.backgroundColor!.resolve(<WidgetState>{WidgetState.hovered}),
          AppColors.primaryHover,
        );
        expect(
          style.foregroundColor!.resolve(<WidgetState>{}),
          AppColors.onPrimary,
        );
        final focused = style.side!.resolve(<WidgetState>{
          WidgetState.focused,
        })!;
        expect(focused.color, AppColors.focusRing);
        expect(focused.width, 2);
        expect(style.side!.resolve(<WidgetState>{}), BorderSide.none);
        final disabled = <WidgetState>{
          WidgetState.disabled,
          WidgetState.pressed,
          WidgetState.focused,
        };
        expect(
          style.backgroundColor!.resolve(disabled),
          AppColors.surfaceMuted,
        );
        expect(style.foregroundColor!.resolve(disabled), AppColors.textMuted);
        expect(style.side!.resolve(disabled), BorderSide.none);
        expect(
          style.overlayColor!.resolve(<WidgetState>{WidgetState.pressed}),
          AppColors.transparent,
        );
      },
    );

    test('secondary and ghost button states share neutral surfaces and focus outlines', () {
      final theme = AppTheme.light();
      final secondary = theme.outlinedButtonTheme.style!;
      final ghost = theme.textButtonTheme.style!;
      expect(
        secondary.backgroundColor!.resolve(<WidgetState>{}),
        AppColors.surface,
      );
      expect(
        ghost.backgroundColor!.resolve(<WidgetState>{}),
        AppColors.transparent,
      );
      for (final style in <ButtonStyle>[secondary, ghost]) {
        expect(style.minimumSize!.resolve(<WidgetState>{})!.height, 48);
        expect(
          style.backgroundColor!.resolve(<WidgetState>{WidgetState.pressed}),
          AppColors.surfaceMuted,
        );
        expect(
          style.backgroundColor!.resolve(<WidgetState>{WidgetState.hovered}),
          AppColors.backgroundMuted,
        );
        expect(
          style.foregroundColor!.resolve(<WidgetState>{}),
          AppColors.textPrimary,
        );
        expect(
          style.foregroundColor!.resolve(<WidgetState>{WidgetState.disabled}),
          AppColors.textMuted,
        );
        expect(
          style.backgroundColor!.resolve(<WidgetState>{WidgetState.disabled}),
          AppColors.surfaceMuted,
        );
        expect(
          style.side!.resolve(<WidgetState>{WidgetState.focused})!.color,
          AppColors.focusRing,
        );
      }
      expect(secondary.side!.resolve(<WidgetState>{})!.width, 2);
      expect(
        secondary.side!.resolve(<WidgetState>{WidgetState.disabled})!.color,
        AppColors.divider,
      );
      expect(ghost.side!.resolve(<WidgetState>{}), BorderSide.none);
    });

    test(
      'input theme specifies minimum size, radius, border, and field states',
      () {
        final input = AppTheme.light().inputDecorationTheme;
        expect(input.constraints!.minHeight, 52);
        expect(input.contentPadding, const EdgeInsets.all(12));
        final borders = <InputBorder?, Color>{
          input.enabledBorder: AppColors.borderDefault,
          input.focusedBorder: AppColors.primary,
          input.disabledBorder: AppColors.divider,
          input.errorBorder: AppColors.danger,
          input.focusedErrorBorder: AppColors.danger,
        };
        for (final entry in borders.entries) {
          final border = entry.key! as OutlineInputBorder;
          expect(border.borderRadius, BorderRadius.circular(10));
          expect(border.borderSide.width, 2);
          expect(border.borderSide.color, entry.value);
        }
        expect(input.errorStyle!.color, AppColors.danger);
        expect(input.counterStyle!.fontSize, 12);
        expect(
          WidgetStateProperty.resolveAs(input.fillColor!, <WidgetState>{
            WidgetState.disabled,
          }),
          AppColors.surfaceMuted,
        );
      },
    );
  });

  group('rendered Material components', () {
    testWidgets('primary button renders a lime pill at 56dp with Inter label', (
      tester,
    ) async {
      await _pump(
        tester,
        FilledButton(onPressed: () {}, child: const Text('Simpan')),
      );
      final material = _material(tester, find.byType(FilledButton));
      expect(material.color, AppColors.primary);
      expect(material.shape, isA<StadiumBorder>());
      expect(tester.getSize(find.byType(FilledButton)).height, 56);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Simpan'),
      );
      expect(paragraph.text.style!.fontFamily, 'Inter');
      expect(paragraph.text.style!.fontSize, 18);
      expect(paragraph.text.style!.fontWeight, FontWeight.w600);
      expect(paragraph.text.style!.color, AppColors.onPrimary);
    });

    testWidgets('primary press renders the reviewed pressed color', (
      tester,
    ) async {
      await _pump(
        tester,
        FilledButton(onPressed: () {}, child: const Text('Simpan')),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FilledButton)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        _material(tester, find.byType(FilledButton)).color,
        AppColors.primaryPressed,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        _material(tester, find.byType(FilledButton)).color,
        AppColors.primary,
      );
    });

    testWidgets('disabled primary stays readable and ignores taps', (
      tester,
    ) async {
      await _pump(
        tester,
        const FilledButton(onPressed: null, child: Text('Simpan')),
      );
      expect(
        _material(tester, find.byType(FilledButton)).color,
        AppColors.surfaceMuted,
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Simpan'),
      );
      expect(paragraph.text.style!.color, AppColors.textMuted);
      await tester.tap(find.byType(FilledButton));
      expect(tester.takeException(), isNull);
    });

    testWidgets('keyboard focus draws a visible dark green ring', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final previousHighlight = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousHighlight,
      );
      await _pump(
        tester,
        FilledButton(
          focusNode: focus,
          onPressed: () {},
          child: const Text('Simpan'),
        ),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      final shape =
          _material(tester, find.byType(FilledButton)).shape! as StadiumBorder;
      expect(shape.side.color, AppColors.focusRing);
      expect(shape.side.width, 2);
    });

    testWidgets('secondary and ghost keep pill shapes and 48dp targets', (
      tester,
    ) async {
      await _pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            OutlinedButton(onPressed: () {}, child: const Text('Batal')),
            TextButton(onPressed: () {}, child: const Text('Kembali')),
          ],
        ),
      );
      for (final finder in <Finder>[
        find.byType(OutlinedButton),
        find.byType(TextButton),
      ]) {
        expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
        expect(_material(tester, finder).shape, isA<StadiumBorder>());
      }
      final outline =
          _material(tester, find.byType(OutlinedButton)).shape!
              as StadiumBorder;
      expect(outline.side.width, 2);
    });

    testWidgets(
      'input inherits 10dp corners and switches to lime when focused',
      (tester) async {
        await _pump(
          tester,
          const TextField(decoration: InputDecoration(hintText: 'Nominal')),
        );
        var decorator = tester.widget<InputDecorator>(
          find.byType(InputDecorator),
        );
        expect(
          decorator.decoration.enabledBorder!.borderSide.color,
          AppColors.borderDefault,
        );
        expect(
          tester.getSize(find.byType(TextField)).height,
          greaterThanOrEqualTo(52),
        );
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        decorator = tester.widget<InputDecorator>(find.byType(InputDecorator));
        expect(decorator.isFocused, isTrue);
        final border =
            decorator.decoration.focusedBorder! as OutlineInputBorder;
        expect(border.borderRadius, BorderRadius.circular(10));
        expect(
          border.borderSide,
          const BorderSide(color: AppColors.primary, width: 2),
        );
      },
    );

    testWidgets('error input retains the danger border while focused', (
      tester,
    ) async {
      await _pump(
        tester,
        const TextField(
          decoration: InputDecoration(errorText: 'Nominal wajib diisi'),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      expect(decorator.isFocused, isTrue);
      expect(
        decorator.decoration.focusedErrorBorder!.borderSide.color,
        AppColors.danger,
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Nominal wajib diisi'),
      );
      expect(paragraph.text.style!.color, AppColors.danger);
    });

    testWidgets(
      'card renders a flat white surface with 30dp corners and subtle outline',
      (tester) async {
        await _pump(
          tester,
          const Card(child: SizedBox(width: 200, height: 100)),
        );
        final material = _material(tester, find.byType(Card));
        final shape = material.shape! as RoundedRectangleBorder;
        expect(material.color, AppColors.surface);
        expect(material.elevation, 0);
        expect(material.surfaceTintColor, AppColors.transparent);
        expect(shape.borderRadius, BorderRadius.circular(30));
        expect(shape.side.color, AppColors.borderSubtle);
        expect(shape.side.width, 1);
      },
    );

    testWidgets(
      'dialog uses 40dp corners, Geist title, and the specified scrim',
      (tester) async {
        late BuildContext context;
        await _pump(
          tester,
          Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        );
        final closing = showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Konfirmasi'),
            content: Text('Contoh'),
          ),
        );
        await tester.pumpAndSettle();
        final material = _material(tester, find.byType(AlertDialog));
        expect(
          (material.shape! as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(40),
        );
        expect(material.color, AppColors.surface);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Konfirmasi'),
        );
        expect(paragraph.text.style!.fontFamily, 'Geist');
        expect(paragraph.text.style!.fontWeight, FontWeight.w700);
        expect(
          tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
          AppColors.overlay,
        );
        Navigator.of(context).pop();
        await closing;
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'modal sheet inherits white surface, top-only 40dp corners, and scrim',
      (tester) async {
        late BuildContext context;
        await _pump(
          tester,
          Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        );
        final closing = showModalBottomSheet<void>(
          context: context,
          useSafeArea: true,
          builder: (_) => const SizedBox(height: 120),
        );
        await tester.pumpAndSettle();
        final material = _material(tester, find.byType(BottomSheet));
        expect(material.color, AppColors.surface);
        final shape = material.shape! as RoundedRectangleBorder;
        expect(
          shape.borderRadius,
          const BorderRadius.vertical(top: Radius.circular(40)),
        );
        expect(
          tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
          AppColors.overlay,
        );
        Navigator.of(context).pop();
        await closing;
        await tester.pumpAndSettle();
      },
    );

    testWidgets('navigation renders a lime pill with dark selected content', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(),
        navigation: NavigationBar(
          destinations: const <Widget>[
            NavigationDestination(icon: Icon(Icons.home), label: 'Beranda'),
            NavigationDestination(
              icon: Icon(Icons.receipt_long),
              label: 'Transaksi',
            ),
          ],
        ),
      );
      final indicator = tester.widget<NavigationIndicator>(
        find.byType(NavigationIndicator).first,
      );
      expect(indicator.color, AppColors.primary);
      expect(indicator.shape, isA<StadiumBorder>());
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.home))).color,
        AppColors.onPrimary,
      );
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.receipt_long))).color,
        AppColors.textSecondary,
      );
      expect(
        _material(tester, find.byType(NavigationBar)).color,
        AppColors.surface,
      );
    });

    testWidgets('snackbar renders near-black, light text, and 16dp corners', (
      tester,
    ) async {
      late BuildContext context;
      await _pump(
        tester,
        Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tersimpan'), duration: Duration(days: 1)),
      );
      await tester.pumpAndSettle();
      final material = _material(tester, find.byType(SnackBar));
      expect(material.color, AppColors.snackbar);
      expect(
        (material.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(16),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Tersimpan'),
      );
      expect(paragraph.text.style!.color, AppColors.onSnackbar);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'extended FAB and progress indicator inherit their primary context colors',
      (tester) async {
        await _pump(
          tester,
          const CircularProgressIndicator(value: 0.5),
          fab: FloatingActionButton.extended(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Tambah'),
          ),
        );
        final material = _material(tester, find.byType(FloatingActionButton));
        expect(material.color, AppColors.primary);
        expect(material.shape, isA<StadiumBorder>());
        expect(
          tester.getSize(find.byType(FloatingActionButton)).height,
          greaterThanOrEqualTo(56),
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Tambah'),
        );
        expect(paragraph.text.style!.color, AppColors.onPrimary);
        expect(
          Theme.of(tester.element(find.byType(CircularProgressIndicator)))
              .progressIndicatorTheme
              .color,
          AppColors.onPrimary,
        );
      },
    );

    testWidgets(
      'large text grows primary height instead of clipping its label',
      (tester) async {
        await _pump(
          tester,
          FilledButton(onPressed: () {}, child: const Text('Simpan')),
          scale: 2,
        );
        expect(
          tester.getSize(find.byType(FilledButton)).height,
          greaterThan(56),
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Simpan'),
        );
        expect(paragraph.textScaler, const TextScaler.linear(2));
        expect(tester.takeException(), isNull);
      },
    );
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Widget? navigation,
  Widget? fab,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Center(child: SizedBox(width: 280, child: child)),
        bottomNavigationBar: navigation,
        floatingActionButton: fab,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Material _material(WidgetTester tester, Finder component) =>
    tester.widget<Material>(
      find.descendant(of: component, matching: find.byType(Material)).first,
    );

double _contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final light = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final dark = firstLuminance < secondLuminance
      ? firstLuminance
      : secondLuminance;
  return (light + 0.05) / (dark + 0.05);
}
