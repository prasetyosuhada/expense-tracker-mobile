import 'package:expensetracker/core/clock/app_clock.dart';
import 'package:expensetracker/core/clock/system_clock.dart';
import 'package:expensetracker/features/expenses/data/expense_database.dart';
import 'package:expensetracker/features/expenses/data/sqlite_expense_repository.dart';

/// Creates the production dependencies without opening local storage.
final class AppBootstrap {
  factory AppBootstrap() {
    const clock = SystemClock();
    final database = ExpenseDatabase();
    final repository = SqliteExpenseRepository(
      database: database,
      clock: clock,
    );
    return AppBootstrap._(
      clock: clock,
      database: database,
      repository: repository,
    );
  }

  const AppBootstrap._({
    required this.clock,
    required this.database,
    required this.repository,
  });

  final AppClock clock;
  final ExpenseDatabase database;
  final SqliteExpenseRepository repository;
}
