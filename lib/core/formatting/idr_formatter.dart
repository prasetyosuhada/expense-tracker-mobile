import 'package:intl/intl.dart';

/// Formats whole-Rupiah amounts for display in the Indonesian locale.
final class IdrFormatter {
  /// Creates a formatter with one cached locale-specific number formatter.
  IdrFormatter() : _number = NumberFormat.decimalPattern('id_ID');

  final NumberFormat _number;

  /// Returns an amount with the Rp prefix, grouping dots, and no decimals.
  String formatDisplay(int amount) => 'Rp${_number.format(amount)}';
}
