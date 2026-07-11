import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../model/category_model.dart';
import '../core/constants/app_constants.dart';

/// Handles all database operations related to [Category].
class CategoryRepository {
  final AppDatabase _db;

  const CategoryRepository(this._db);

  /// Returns all categories as domain models.
  Future<List<CategoryModel>> getAllCategories() async {
    final rows = await _db.getAllCategories();
    return rows
        .map((r) => CategoryModel(
              id: r.id,
              category: r.category,
              emoji: r.emoji,
              isDefault: r.isDefault,
            ))
        .toList();
  }

  /// Seeds the default categories if they haven't been inserted yet.
  /// Uses insert-on-conflict-update so it is safe to call multiple times.
  Future<void> seedDefaultCategories() async {
    for (final cat in AppConstants.defaultCategories) {
      await _db.insertCategoryIfAbsent(CategoriesCompanion.insert(
        category: cat['category']!,
        emoji: cat['emoji']!,
        isDefault: const Value(true),
      ));
    }
  }

  /// Whether any categories exist (used to gate seeding).
  Future<bool> hasCategories() async {
    final count = await _db.getCategoryCount();
    return count > 0;
  }

  /// Inserts a new custom category.
  Future<int> createCategory({required String name, required String emoji}) {
    return _db.insertCategory(CategoriesCompanion.insert(
      category: name,
      emoji: emoji,
      isDefault: const Value(false),
    ));
  }

  /// Updates an existing category.
  Future<bool> updateCategory(CategoryModel category) {
    return _db.updateCategory(CategoriesCompanion(
      id: Value(category.id),
      category: Value(category.category),
      emoji: Value(category.emoji),
      isDefault: Value(category.isDefault),
    ));
  }

  /// Deletes a category by id.
  Future<int> deleteCategory(int id) => _db.deleteCategory(id);

  /// Checks if any expenses are linked to the given category.
  Future<bool> hasLinkedExpenses(int categoryId) async {
    final spends = await _db.getSpendsByCategory(categoryId);
    return spends.isNotEmpty;
  }

  /// Migrates all spends from an old category to a new category.
  Future<void> migrateExpenses(int oldCategoryId, int newCategoryId) =>
      _db.migrateSpendCategory(oldCategoryId, newCategoryId);
}

