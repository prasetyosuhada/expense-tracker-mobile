/// The fixed expense categories with stable storage codes.
enum ExpenseCategory {
  food('food'),
  transportation('transportation'),
  shopping('shopping'),
  bills('bills'),
  other('other');

  const ExpenseCategory(this.persistenceCode);

  /// The lowercase ASCII database code, independent of UI labels and order.
  final String persistenceCode;
}
