/// Pure Dart model for a user, decoupled from Drift's generated types.
class UserModel {
  final int id;
  final String firstname;
  final String? middlename;
  final String lastname;
  final String theme; // 'system' | 'light' | 'dark'
  final String dob; // ISO-8601 yyyy-MM-dd
  final String? profilePicturePath;

  const UserModel({
    required this.id,
    required this.firstname,
    this.middlename,
    required this.lastname,
    required this.theme,
    required this.dob,
    this.profilePicturePath,
  });

  /// Full display name, omitting middlename when absent.
  String get fullName => [firstname, middlename, lastname]
      .where((part) => part != null && part.isNotEmpty)
      .join(' ');

  /// First + Last name (always available).
  String get displayName => '$firstname $lastname';

  UserModel copyWith({
    int? id,
    String? firstname,
    String? middlename,
    String? lastname,
    String? theme,
    String? dob,
    String? profilePicturePath,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstname: firstname ?? this.firstname,
      middlename: middlename ?? this.middlename,
      lastname: lastname ?? this.lastname,
      theme: theme ?? this.theme,
      dob: dob ?? this.dob,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
    );
  }
}

