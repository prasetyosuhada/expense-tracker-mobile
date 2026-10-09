import 'package:flutter/material.dart';

import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_colors.dart';
import 'package:expensetracker/core/theme/app_spacing.dart';
import 'package:expensetracker/features/expenses/domain/expense.dart';
import 'package:expensetracker/features/expenses/presentation/transactions/transactions_view_model.dart';

/// Displays confirmation dialog before permanently deleting an expense.
///
/// Returns:
/// - `true` if deletion committed successfully.
/// - `false` if deletion was attempted and failed.
/// - `null` if canceled or dismissed without attempting deletion.
Future<bool?> showDeleteExpenseDialog({
  required BuildContext context,
  required Expense expense,
  required TransactionsViewModel viewModel,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) =>
        DeleteExpenseDialog(expense: expense, viewModel: viewModel),
  );
}

/// Confirmation dialog for permanently deleting an expense item.
class DeleteExpenseDialog extends StatefulWidget {
  const DeleteExpenseDialog({
    super.key,
    required this.expense,
    required this.viewModel,
  });

  final Expense expense;
  final TransactionsViewModel viewModel;

  @override
  State<DeleteExpenseDialog> createState() => _DeleteExpenseDialogState();
}

class _DeleteExpenseDialogState extends State<DeleteExpenseDialog> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    final success = await widget.viewModel.deleteExpense(widget.expense.id);
    if (!mounted) return;
    Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDeleting =
        _isDeleting || widget.viewModel.isDeleting(widget.expense.id);

    return PopScope(
      canPop: !isDeleting,
      child: AlertDialog(
        title: Text(l10n.deleteDialogTitle),
        content: Text(l10n.deleteDialogMessage),
        actions: [
          TextButton(
            key: const Key('delete_dialog_cancel_button'),
            autofocus: true,
            onPressed: isDeleting
                ? null
                : () => Navigator.of(context).pop(null),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            key: const Key('delete_dialog_confirm_button'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.6),
              disabledForegroundColor: AppColors.surface.withValues(alpha: 0.8),
            ),
            onPressed: isDeleting ? null : _handleDelete,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDeleting) ...[
                  const SizedBox(
                    width: AppSpacing.sm,
                    height: AppSpacing.sm,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(l10n.deleteAction),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
