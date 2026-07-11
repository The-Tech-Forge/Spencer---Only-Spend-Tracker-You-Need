import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/category_model.dart';
import '../repository/category_repository.dart';
import 'database_provider.dart';

/// Repository provider.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider));
});

/// Async provider that returns all categories from the database.
/// Categories are seeded on first launch by [AppInitializer].
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.watch(categoryRepositoryProvider).getAllCategories();
});

/// Notifier for managing category CRUD operations reactively.
class CategoryNotifier extends Notifier<AsyncValue<List<CategoryModel>>> {
  @override
  AsyncValue<List<CategoryModel>> build() {
    _load();
    return const AsyncLoading();
  }

  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  Future<void> _load() async {
    try {
      final cats = await _repo.getAllCategories();
      state = AsyncData(cats);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    await _load();
    // Refresh the global categoriesProvider too
    ref.invalidate(categoriesProvider);
  }

  Future<bool> createCategory({required String name, required String emoji}) async {
    try {
      await _repo.createCategory(name: name, emoji: emoji);
      await reload();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCategory(CategoryModel category) async {
    try {
      await _repo.updateCategory(category);
      await reload();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if deletion succeeded.
  /// Returns null if linked expenses exist (caller should prompt migration).
  Future<bool?> deleteCategory(CategoryModel category) async {
    final hasLinked = await _repo.hasLinkedExpenses(category.id);
    if (hasLinked) return null; // caller must handle migration
    await _repo.deleteCategory(category.id);
    await reload();
    return true;
  }

  /// Migrates all expenses to [targetId] then deletes [category].
  Future<void> migrateThenDelete(CategoryModel category, int targetId) async {
    await _repo.migrateExpenses(category.id, targetId);
    await _repo.deleteCategory(category.id);
    await reload();
  }
}

final categoryNotifierProvider =
    NotifierProvider<CategoryNotifier, AsyncValue<List<CategoryModel>>>(
  CategoryNotifier.new,
);
