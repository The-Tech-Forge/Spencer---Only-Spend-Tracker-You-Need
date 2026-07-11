import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

/// Singleton provider for the Drift [AppDatabase].
/// All repositories depend on this provider.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
