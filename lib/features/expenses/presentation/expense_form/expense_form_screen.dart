import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_colors.dart';
import 'package:expensetracker/core/theme/app_shapes.dart';
import 'package:expensetracker/core/theme/app_spacing.dart';
import 'package:expensetracker/core/theme/app_typography.dart';
import 'package:expensetracker/core/theme/category_colors.dart';
import 'package:expensetracker/features/expenses/domain/expense_category.dart';
import 'package:expensetracker/features/expenses/presentation/expense_form/expense_form_view_model.dart';
import 'package:expensetracker/features/expenses/presentation/widgets/expense_list_item.dart';

/// Formats typed digits with Indonesian dot-thousand separators and sends
/// raw digits back to the controller so [ExpenseFormViewModel.updateAmount]
/// always receives an unformatted integer string (e.g. `'25000'`).
///
/// Cursor position is recalculated after formatting so it stays aligned with
/// the digit the user just typed or deleted rather than jumping to the end.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final RegExp _nonDigit = RegExp(r'[^0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digit characters to obtain raw digits.
    final rawDigits = newValue.text.replaceAll(_nonDigit, '');

    // Empty input: let the field show blank without any prefix.
    if (rawDigits.isEmpty) {
      return const TextEditingValue();
    }

    // Remove leading zeros so "007" becomes "7".
    final trimmed = rawDigits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final digits = trimmed.isEmpty ? rawDigits : trimmed;

    // Format with dot-thousand separators.
    final formatted = _formatWithSeparators(digits);

    // Infer new cursor position: count how many digits were to the left of the
    // old cursor in the new raw string, then find the matching position in the
    // formatted string by counting the same number of digits from the left.
    final cursorOffset = newValue.selection.baseOffset;
    final rawBeforeCursor = newValue.text
        .substring(0, min(cursorOffset, newValue.text.length))
        .replaceAll(_nonDigit, '');
    final digitsBeforeCursor = rawBeforeCursor.length;

    var newCursor = 0;
    var counted = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (counted >= digitsBeforeCursor) {
        newCursor = i;
        break;
      }
      if (_isDigit(formatted[i])) {
        counted++;
      }
      newCursor = i + 1;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  String _formatWithSeparators(String digits) {
    final reversed = digits.split('').reversed.toList();
    final buf = StringBuffer();
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buf.write('.');
      }
      buf.write(reversed[i]);
    }
    return buf.toString().split('').reversed.join();
  }

  bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
}

/// The add/edit expense form screen, built incrementally across P3-005 to
/// P3-008. This version (P3-006) wires up Amount and Category fields;
/// date, note, and the submit button are stubbed and will be completed by the
/// subsequent tasks.
class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, required this.viewModel});

  final ExpenseFormViewModel viewModel;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  late final TextEditingController _amountController;
  final FocusNode _amountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialise with a pre-formatted value for edit mode; blank for add mode.
    final initialRaw = widget.viewModel.state.amountText;
    final initialFormatted = _formatRaw(initialRaw);
    _amountController = TextEditingController(text: initialFormatted);
    // In add mode, open the keyboard immediately (UX §8.2).
    if (!widget.viewModel.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _amountFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Converts a raw digit string (e.g. `'25000'`) to the display form
  /// `'25.000'` so the controller can be pre-populated correctly.
  String _formatRaw(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final reversed = digits.split('').reversed.toList();
    final buf = StringBuffer();
    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write('.');
      buf.write(reversed[i]);
    }
    return buf.toString().split('').reversed.join();
  }

  /// Strips separators so only the raw digit string is forwarded to the VM.
  void _onAmountChanged(String formatted) {
    final raw = formatted.replaceAll('.', '');
    widget.viewModel.updateAmount(raw);
  }

  Future<void> _pickCategory(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppShapes.sheetRadius),
      builder: (sheetContext) => CategoryPickerSheet(
        selectedCategory: widget.viewModel.state.selectedCategory,
      ),
    );
    if (selected != null && mounted) {
      widget.viewModel.updateCategory(selected);
    }
  }

  String? _errorText(AppLocalizations l10n, String? key) {
    if (key == null) return null;
    return switch (key) {
      'formAmountRequired' => l10n.formAmountRequired,
      'formAmountZero' => l10n.formAmountZero,
      'formAmountInvalid' => l10n.formAmountInvalid,
      'formAmountTooLarge' => l10n.formAmountTooLarge,
      'formCategoryRequired' => l10n.formCategoryRequired,
      _ => key,
    };
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.viewModel.isEditing
        ? l10n.editExpenseTitle
        : l10n.addExpenseTitle;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              final state = widget.viewModel.state;
              final amountError = _errorText(l10n, state.fieldErrors['amount']);
              final categoryError = _errorText(
                l10n,
                state.fieldErrors['category'],
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AmountField(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    label: l10n.formAmountLabel,
                    prefix: l10n.formAmountPrefix,
                    errorText: amountError,
                    enabled: !state.isSubmitting,
                    onChanged: _onAmountChanged,
                  ),
                  const SizedBox(height: AppSpacing.fieldGap),
                  _CategoryField(
                    label: l10n.formCategoryLabel,
                    placeholder: l10n.formCategoryPlaceholder,
                    selectedCategory: state.selectedCategory,
                    errorText: categoryError,
                    enabled: !state.isSubmitting,
                    onTap: () => _pickCategory(context),
                  ),
                  // P3-007 — Date field placeholder
                  const SizedBox(height: AppSpacing.fieldGap),
                  // P3-007 — Note field placeholder
                  const SizedBox(height: AppSpacing.fieldGap),
                  // P3-008 — Submit button placeholder
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widget: Amount field
// ---------------------------------------------------------------------------

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.prefix,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String prefix;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: false,
        signed: false,
      ),
      textInputAction: TextInputAction.next,
      inputFormatters: [ThousandsSeparatorInputFormatter()],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixText: '$prefix ',
        errorText: errorText,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widget: Category field
// ---------------------------------------------------------------------------

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.selectedCategory,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final String placeholder;
  final VoidCallback onTap;
  final ExpenseCategory? selectedCategory;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasCategory = selectedCategory != null;
    final text = hasCategory
        ? ExpenseListItem.labelFor(l10n, selectedCategory!)
        : placeholder;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppShapes.inputRadius,
      child: InputDecorator(
        isEmpty: !hasCategory,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          errorText: errorText,
          enabled: enabled,
          suffixIcon: const Icon(Icons.keyboard_arrow_down),
        ),
        child: Text(
          text,
          style: hasCategory
              ? theme.textTheme.bodyLarge
              : AppTypography.supportingBody.copyWith(
                  color: AppColors.textMuted,
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Sheet: Category Picker
// ---------------------------------------------------------------------------

/// Modal bottom sheet allowing single selection from fixed expense categories.
class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({super.key, this.selectedCategory});

  final ExpenseCategory? selectedCategory;

  static const List<ExpenseCategory> categories = [
    ExpenseCategory.food,
    ExpenseCategory.transportation,
    ExpenseCategory.shopping,
    ExpenseCategory.bills,
    ExpenseCategory.other,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colors = theme.extension<CategoryColors>() ?? CategoryColors.light;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                l10n.formCategoryPickerTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final category in categories)
              _CategoryOptionTile(
                category: category,
                label: ExpenseListItem.labelFor(l10n, category),
                icon: ExpenseListItem.iconFor(category),
                backgroundColor: colors.backgroundFor(category),
                foregroundColor: colors.foregroundFor(category),
                isSelected: category == selectedCategory,
                onTap: () => Navigator.of(context).pop(category),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOptionTile extends StatelessWidget {
  const _CategoryOptionTile({
    required this.category,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.isSelected,
    required this.onTap,
  });

  final ExpenseCategory category;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: AppSpacing.categoryCircle,
        height: AppSpacing.categoryCircle,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: Icon(icon, color: foregroundColor, size: AppSpacing.iconSize),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.onPrimary)
          : null,
      selected: isSelected,
      onTap: onTap,
    );
  }
}
