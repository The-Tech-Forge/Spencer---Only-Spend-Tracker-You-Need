import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/backup_repository.dart';
import 'category_provider.dart';
import 'database_provider.dart';
import 'expense_provider.dart';
import 'user_provider.dart';

/// Repository provider for backup operations.
final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(
    db: ref.watch(databaseProvider),
    userRepo: ref.watch(userRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    expenseRepo: ref.watch(expenseRepositoryProvider),
  );
});

/// Tracks the export and import state.
///
/// State type is [Map<String, int>?] — null when idle, populated after import.
class BackupNotifier extends AsyncNotifier<Map<String, int>?> {
  @override
  Future<Map<String, int>?> build() async => null;

  Future<void> exportBackup(String path) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(backupRepositoryProvider)
          .exportBackup(path)
          .then((_) => null),
    );
  }

  Future<void> importBackup(
    String path, {
    required bool replaceExisting,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final summary = await ref
          .read(backupRepositoryProvider)
          .importBackup(path, replaceExisting: replaceExisting);

      // Invalidate caches so UI refreshes after restore
      ref.invalidate(userProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(expensesStreamProvider);

      return summary;
    });
  }
}

final backupProvider =
    AsyncNotifierProvider<BackupNotifier, Map<String, int>?>(
  BackupNotifier.new,
);
