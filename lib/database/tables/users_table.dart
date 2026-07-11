import 'package:drift/drift.dart';

/// Drift table definition for the [User] entity.
/// Stores user profile and preference data locally.
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firstname => text().withLength(min: 1, max: 50)();
  TextColumn get middlename => text().withLength(max: 50).nullable()();
  TextColumn get lastname => text().withLength(min: 1, max: 50)();
  /// Stores theme preference: 'system' | 'light' | 'dark'
  TextColumn get theme => text().withDefault(const Constant('system'))();
  /// Date of birth stored as ISO-8601 string (yyyy-MM-dd)
  TextColumn get dob => text()();
  /// Path to user's local cropped profile image file
  TextColumn get profilePicturePath => text().nullable()();
}

