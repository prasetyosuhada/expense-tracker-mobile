import 'package:expensetracker/core/clock/app_clock.dart';

/// A controllable clock for deterministic unit and widget tests.
final class FakeAppClock implements AppClock {
  /// Starts at [currentTime] and keeps returning it until changed by a test.
  FakeAppClock(this.currentTime);

  /// The time returned by [now]; tests may set this between operations.
  DateTime currentTime;

  @override
  DateTime now() => currentTime;
}
