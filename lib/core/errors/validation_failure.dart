/// A field validation exception with a localization key for its message.
final class ValidationFailure implements Exception {
  /// Identifies the invalid [field] and its ARB message key.
  const ValidationFailure(this.field, this.message);

  /// The domain field that needs correction.
  final String field;

  /// The ARB key to resolve in the presentation layer.
  final String message;
}
