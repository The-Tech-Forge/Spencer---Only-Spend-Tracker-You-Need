import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/user_model.dart';
import '../repository/user_repository.dart';
import 'database_provider.dart';

/// Repository provider.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(databaseProvider));
});

/// Async provider that fetches the current user from the database.
final userProvider = FutureProvider<UserModel?>((ref) async {
  return ref.watch(userRepositoryProvider).getUser();
});
