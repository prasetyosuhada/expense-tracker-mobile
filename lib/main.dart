import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:expensetracker/app/app_bootstrap.dart';
import 'package:expensetracker/core/clock/app_clock.dart';
import 'package:expensetracker/core/l10n/generated/app_localizations.dart';
import 'package:expensetracker/features/expenses/domain/expense_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = AppBootstrap();
  runApp(MainApp(clock: bootstrap.clock, repository: bootstrap.repository));
}

/// Receives app dependencies explicitly so tests can supply in-memory fakes.
class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.clock, required this.repository});

  final AppClock clock;
  final ExpenseRepository repository;

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      locale: Locale('id', 'ID'),
      supportedLocales: [Locale('id', 'ID')],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(),
    );
  }
}
