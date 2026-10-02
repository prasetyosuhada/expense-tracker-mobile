import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:expensetracker/app/app_shell.dart';
import 'package:expensetracker/core/clock/app_clock.dart';
import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/core/theme/app_theme.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';

/// Configures the app theme, Indonesian localization, and navigation shell.
class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.clock, required this.repository});

  final AppClock clock;
  final ExpenseRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light(),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AppShell(clock: clock, repository: repository),
    );
  }
}
