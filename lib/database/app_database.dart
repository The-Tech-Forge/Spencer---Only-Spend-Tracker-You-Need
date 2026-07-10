import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/categories_table.dart';
import 'tables/spends_table.dart';
import 'tables/users_table.dart';

part 'app_database.g.dart';

/// Opens a connection to the SQLite database using the device's
/// application documents directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'spencer.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// The central Drift database class for Spencer.
/// Includes all tables and DAOs.
@DriftDatabase(tables: [Users, Categories, Spends])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(categories, categories.isDefault);
            await m.addColumn(users, users.profilePicturePath);
          }
        },
      );

  // ─── User queries ─────────────────────────────────────────────────────────

  /// Returns the first (and only) user in the database, or null.
  Future<User?> getUser() =>
      (select(users)..limit(1)).getSingleOrNull();

  /// Inserts a new user row and returns the generated id.
  Future<int> insertUser(UsersCompanion user) =>
      into(users).insert(user);

  /// Updates an existing user row.
  Future<bool> updateUser(UsersCompanion user) =>
      update(users).replace(user);

  // ─── Category queries ──────────────────────────────────────────────────────

  /// Returns all category rows ordered by default first (descending), then alphabetically.
  Future<List<Category>> getAllCategories() =>
      (select(categories)
            ..orderBy([
              (c) => OrderingTerm(expression: c.isDefault, mode: OrderingMode.desc),
              (c) => OrderingTerm(expression: c.category),
            ]))
          .get();

  /// Inserts a category only if it doesn't already exist (by name).
  Future<void> insertCategoryIfAbsent(CategoriesCompanion cat) async {
    await into(categories).insertOnConflictUpdate(cat);
  }

  /// Inserts a category and returns its database id.
  Future<int> insertCategory(CategoriesCompanion cat) =>
      into(categories).insert(cat);

  /// Updates an existing category row.
  Future<bool> updateCategory(CategoriesCompanion cat) =>
      update(categories).replace(cat);

  /// Deletes a category by id.
  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  /// Returns the count of categories currently stored.
  Future<int> getCategoryCount() async {
    final countExp = categories.id.count();
    final query = selectOnly(categories)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }


  // ─── Spend queries ─────────────────────────────────────────────────────────

  /// Returns all expense rows joined with their category, newest first.
  Future<List<SpendWithCategory>> getAllSpends() async {
    final query = select(spends).join([
      innerJoin(categories, categories.id.equalsExp(spends.categoryId)),
    ])
      ..orderBy([OrderingTerm.desc(spends.date)]);
    return query.map((row) {
      return SpendWithCategory(
        spend: row.readTable(spends),
        category: row.readTable(categories),
      );
    }).get();
  }

  /// Watches all spends as a reactive stream — newest first.
  Stream<List<SpendWithCategory>> watchAllSpends() {
    final query = select(spends).join([
      innerJoin(categories, categories.id.equalsExp(spends.categoryId)),
    ])
      ..orderBy([OrderingTerm.desc(spends.date)]);
    return query.map((row) {
      return SpendWithCategory(
        spend: row.readTable(spends),
        category: row.readTable(categories),
      );
    }).watch();
  }

  /// Inserts a new spend record and returns its id.
  Future<int> insertSpend(SpendsCompanion spend) =>
      into(spends).insert(spend);

  /// Updates an existing spend record.
  Future<bool> updateSpend(SpendsCompanion spend) =>
      update(spends).replace(spend);

  /// Deletes a spend by id.
  Future<int> deleteSpend(int id) =>
      (delete(spends)..where((s) => s.id.equals(id))).go();

  /// Returns all spends in a given date range (ISO-8601 date strings).
  Future<List<SpendWithCategory>> getSpendsBetween(
      String startDate, String endDate) async {
    final query = select(spends).join([
      innerJoin(categories, categories.id.equalsExp(spends.categoryId)),
    ])
      ..where(spends.date.isBetweenValues(startDate, endDate))
      ..orderBy([OrderingTerm.desc(spends.date)]);
    return query.map((row) => SpendWithCategory(
          spend: row.readTable(spends),
          category: row.readTable(categories),
        )).get();
  }

  /// Returns all spends for a specific category id.
  Future<List<SpendWithCategory>> getSpendsByCategory(int categoryId) async {
    final query = select(spends).join([
      innerJoin(categories, categories.id.equalsExp(spends.categoryId)),
    ])
      ..where(spends.categoryId.equals(categoryId))
      ..orderBy([OrderingTerm.desc(spends.date)]);
    return query.map((row) => SpendWithCategory(
          spend: row.readTable(spends),
          category: row.readTable(categories),
        )).get();
  }

  /// Migrates all spends from an old category to a new category.
  Future<int> migrateSpendCategory(int oldId, int newId) {
    return (update(spends)..where((s) => s.categoryId.equals(oldId)))
        .write(SpendsCompanion(categoryId: Value(newId)));
  }

  /// Wipes all tables from the database.
  Future<void> wipeDatabase() async {
    await transaction(() async {
      await delete(spends).go();
      await delete(categories).go();
      await delete(users).go();
    });
  }
}


/// A helper data class combining a [Spend] with its joined [Category].
class SpendWithCategory {
  final Spend spend;
  final Category category;

  const SpendWithCategory({required this.spend, required this.category});
}
