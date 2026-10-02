import 'package:flutter/material.dart';

import 'package:expensetracker/app/app.dart';
import 'package:expensetracker/app/app_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = AppBootstrap();
  runApp(MainApp(clock: bootstrap.clock, repository: bootstrap.repository));
}
