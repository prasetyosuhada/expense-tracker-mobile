/// Base type for application failures exposed across layer boundaries.
sealed class AppFailure implements Exception {
  /// Creates an application failure subtype.
  const AppFailure();
}

/// Indicates that a specific input field failed validation.
final class ValidationFailure extends AppFailure {
  /// Identifies the invalid [field] and its ARB message key.
  const ValidationFailure(this.field, this.message);

  /// The domain field that needs correction.
  final String field;

  /// The ARB key to resolve in the presentation layer.
  final String message;
}

/// Indicates that local storage failed while opening, reading, or writing.
final class StorageFailure extends AppFailure {
  /// Retains the technical [cause] for internal handling.
  const StorageFailure(this.cause);

  /// The underlying exception, if one is available.
  final Object? cause;
}

/// Indicates that the expense with [id] no longer exists.
final class NotFoundFailure extends AppFailure {
  /// Identifies the missing expense.
  const NotFoundFailure(this.id);

  /// The expense identifier that could not be found.
  final int id;
}

/// Indicates that stored data does not satisfy the domain contract.
final class CorruptDataFailure extends AppFailure {
  /// Describes the invalid stored value for internal handling.
  const CorruptDataFailure(this.detail);

  /// A technical description of the corrupt data.
  final String detail;
}

/// Indicates an error not covered by a more specific failure type.
final class UnexpectedFailure extends AppFailure {
  /// Retains the technical [cause] for internal handling.
  const UnexpectedFailure(this.cause);

  /// The underlying exception, if one is available.
  final Object? cause;
}
