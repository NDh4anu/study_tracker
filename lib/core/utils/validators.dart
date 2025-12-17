/// Form validation utilities untuk StudyTracker
///
/// Contains reusable validation functions untuk:
/// - Text input (required, min/max length)
/// - Date validation (not in past)
/// - Selection validation (dropdown, radio)
class Validators {
  Validators._();

  /// Validate required field
  /// Returns error message if empty, null if valid
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : 'This field is required';
    }
    return null;
  }

  /// Validate minimum length
  /// Returns error message if too short, null if valid
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return null; // Will be caught by required validator
    }

    if (value.trim().length < minLength) {
      return fieldName != null
          ? '$fieldName must be at least $minLength characters'
          : 'Must be at least $minLength characters';
    }
    return null;
  }

  /// Validate maximum length
  /// Returns error message if too long, null if valid
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return null; // Will be caught by required validator
    }

    if (value.trim().length > maxLength) {
      return fieldName != null
          ? '$fieldName must not exceed $maxLength characters'
          : 'Must not exceed $maxLength characters';
    }
    return null;
  }

  /// Combine multiple validators
  /// Returns first error found, null if all valid
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  /// Validate task title
  /// - Required
  /// - Min 3 characters
  /// - Max 50 characters
  static String? taskTitle(String? value) {
    return combine(value, [
      (v) => required(v, fieldName: 'Title'),
      (v) => minLength(v, 3, fieldName: 'Title'),
      (v) => maxLength(v, 50, fieldName: 'Title'),
    ]);
  }

  /// Validate task description
  /// - Required
  /// - Min 10 characters
  /// - Max 500 characters
  static String? taskDescription(String? value) {
    return combine(value, [
      (v) => required(v, fieldName: 'Description'),
      (v) => minLength(v, 10, fieldName: 'Description'),
      (v) => maxLength(v, 500, fieldName: 'Description'),
    ]);
  }
}
