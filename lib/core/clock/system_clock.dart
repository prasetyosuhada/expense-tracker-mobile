import 'package:expensetracker/core/clock/app_clock.dart';

/// Reads the device clock in production.
final class SystemClock implements AppClock {
  /// Creates a system clock.
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
