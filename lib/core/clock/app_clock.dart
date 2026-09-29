/// Supplies the current time so application logic can use a controlled clock.
abstract interface class AppClock {
  /// Returns the current local date and time.
  DateTime now();
}
