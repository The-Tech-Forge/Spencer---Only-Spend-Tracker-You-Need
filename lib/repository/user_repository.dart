import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../model/user_model.dart';

/// Handles all database operations related to [User].
/// The UI never calls the database directly — it goes through this repository.
class UserRepository {
  final AppDatabase _db;

  const UserRepository(this._db);

  /// Returns the stored user or null if none exists.
  Future<UserModel?> getUser() async {
    final row = await _db.getUser();
    if (row == null) return null;
    return UserModel(
      id: row.id,
      firstname: row.firstname,
      middlename: row.middlename,
      lastname: row.lastname,
      theme: row.theme,
      dob: row.dob,
      profilePicturePath: row.profilePicturePath,
    );
  }

  /// Inserts a new user and returns its database id.
  Future<int> insertUser({
    required String firstname,
    String? middlename,
    required String lastname,
    required String theme,
    required String dob,
    String? profilePicturePath,
  }) {
    return _db.insertUser(UsersCompanion.insert(
      firstname: firstname,
      middlename: Value(middlename),
      lastname: lastname,
      theme: Value(theme),
      dob: dob,
      profilePicturePath: Value(profilePicturePath),
    ));
  }

  /// Updates all fields of the stored user.
  Future<bool> updateUser(UserModel user) {
    return _db.updateUser(UsersCompanion(
      id: Value(user.id),
      firstname: Value(user.firstname),
      middlename: Value(user.middlename),
      lastname: Value(user.lastname),
      theme: Value(user.theme),
      dob: Value(user.dob),
      profilePicturePath: Value(user.profilePicturePath),
    ));
  }
}

