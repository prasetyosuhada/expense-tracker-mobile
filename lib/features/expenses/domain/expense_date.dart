/// An immutable calendar date without a time or timezone.
final class ExpenseDate {
  /// Creates a valid date whose year fits the four-digit ISO storage format.
  ///
  /// Throws [ArgumentError] for invalid dates instead of normalizing overflow.
  ExpenseDate(this.year, this.month, this.day) {
    if (year < 0 || year > 9999) {
      throw ArgumentError.value(year, 'year', 'Must contain four ISO digits');
    }

    // UTC avoids local daylight-saving transitions during calendar validation.
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw ArgumentError('Invalid calendar date: $year-$month-$day');
    }
  }

  /// Parses exactly YYYY-MM-DD, throwing [FormatException] for invalid input.
  factory ExpenseDate.fromIsoString(String iso) {
    if (iso.length != 10 || !_isoPattern.hasMatch(iso)) {
      throw FormatException('Expected YYYY-MM-DD', iso);
    }

    try {
      return ExpenseDate(
        int.parse(iso.substring(0, 4)),
        int.parse(iso.substring(5, 7)),
        int.parse(iso.substring(8, 10)),
      );
    } on ArgumentError {
      throw FormatException('Invalid calendar date', iso);
    }
  }

  /// Copies the supplied calendar components without timezone conversion.
  factory ExpenseDate.fromDateTime(DateTime date) {
    return ExpenseDate(date.year, date.month, date.day);
  }

  static final RegExp _isoPattern = RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$');

  /// The four-digit calendar year, from 0 through 9999.
  final int year;

  /// The calendar month, from 1 through 12.
  final int month;

  /// The valid day within [month].
  final int day;

  /// Serializes this date to canonical YYYY-MM-DD storage format.
  String toIsoString() {
    final isoYear = year.toString().padLeft(4, '0');
    final isoMonth = month.toString().padLeft(2, '0');
    final isoDay = day.toString().padLeft(2, '0');
    return '$isoYear-$isoMonth-$isoDay';
  }

  @override
  bool operator ==(Object other) {
    return other is ExpenseDate &&
        year == other.year &&
        month == other.month &&
        day == other.day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);
}
