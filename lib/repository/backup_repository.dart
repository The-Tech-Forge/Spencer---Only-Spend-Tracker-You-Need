import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../core/constants/app_constants.dart';
import 'category_repository.dart';
import 'expense_repository.dart';
import 'user_repository.dart';

/// Handles backup (export) and restore (import) logic in standard JSON format.
class BackupRepository {
  final AppDatabase _db;
  final UserRepository _userRepo;
  final CategoryRepository _categoryRepo;
  final ExpenseRepository _expenseRepo;

  const BackupRepository({
    required AppDatabase db,
    required UserRepository userRepo,
    required CategoryRepository categoryRepo,
    required ExpenseRepository expenseRepo,
  })  : _db = db,
        _userRepo = userRepo,
        _categoryRepo = categoryRepo,
        _expenseRepo = expenseRepo;

  /// Packs all user, category, and spend data into a JSON file at [targetPath].
  Future<void> exportBackup(String targetPath) async {
    final user = await _userRepo.getUser();
    final categories = await _categoryRepo.getAllCategories();
    final expenses = await _expenseRepo.getAllExpenses();

    final data = {
      'version': 2,
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': AppConstants.appVersion,
      'user': user == null
          ? null
          : {
              'firstname': user.firstname,
              'middlename': user.middlename,
              'lastname': user.lastname,
              'theme': user.theme,
              'dob': user.dob,
              'profilePicturePath': user.profilePicturePath,
            },
      'categories': categories
          .map((c) => {
                'id': c.id,
                'category': c.category,
                'emoji': c.emoji,
                'isDefault': c.isDefault,
              })
          .toList(),
      'expenses': expenses
          .map((e) => {
                'amount': e.amount,
                'categoryId': e.category.id,
                'categoryName': e.category.category,
                'date': e.date.toIso8601String(),
                'note': e.note,
                'isIncome': e.isIncome,
              })
          .toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final file = File(targetPath);
    await file.writeAsString(jsonStr);
  }

  /// Restores data from the JSON file at [sourcePath].
  /// Can either wipe and overwrite ([replaceExisting] = true) or merge without duplicates.
  Future<Map<String, int>> importBackup(
    String sourcePath, {
    required bool replaceExisting,
  }) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('Backup file does not exist');
    }

    final jsonStr = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(jsonStr);

    if (data['version'] == null ||
        data['categories'] == null ||
        data['expenses'] == null) {
      throw Exception('Invalid backup file format');
    }

    int usersImported = 0;
    int categoriesImported = 0;
    int expensesImported = 0;

    if (replaceExisting) {
      // 1. Wipe existing database
      await _db.wipeDatabase();

      // 2. Import User
      if (data['user'] != null) {
        final u = data['user'];
        await _userRepo.insertUser(
          firstname: u['firstname'],
          middlename: u['middlename'],
          lastname: u['lastname'],
          theme: u['theme'] ?? 'system',
          dob: u['dob'],
          profilePicturePath: u['profilePicturePath'],
        );
        usersImported = 1;
      }

      // 3. Import Categories
      final Map<int, int> categoryIdMap = {};
      final List<dynamic> backupCats = data['categories'];
      for (final cat in backupCats) {
        final int backupId = cat['id'];
        final int newId = await _db.insertCategory(CategoriesCompanion.insert(
          category: cat['category'],
          emoji: cat['emoji'],
          isDefault: Value(cat['isDefault'] ?? false),
        ));
        categoryIdMap[backupId] = newId;
        categoriesImported++;
      }

      // 4. Import Expenses
      final List<dynamic> backupExpenses = data['expenses'];
      for (final exp in backupExpenses) {
        final int oldCatId = exp['categoryId'];
        final int? newCatId = categoryIdMap[oldCatId];
        if (newCatId == null) continue;

        await _expenseRepo.addExpense(
          amount: (exp['amount'] as num).toDouble(),
          categoryId: newCatId,
          date: DateTime.parse(exp['date']),
          note: exp['note'],
          isIncome: exp['isIncome'] ?? false,
        );
        expensesImported++;
      }
    } else {
      // Merge Strategy
      // 1. Import User if not already existing
      final currentUser = await _userRepo.getUser();
      if (currentUser == null && data['user'] != null) {
        final u = data['user'];
        await _userRepo.insertUser(
          firstname: u['firstname'],
          middlename: u['middlename'],
          lastname: u['lastname'],
          theme: u['theme'] ?? 'system',
          dob: u['dob'],
          profilePicturePath: u['profilePicturePath'],
        );
        usersImported = 1;
      }

      // 2. Import missing Categories and map their IDs
      final existingCats = await _categoryRepo.getAllCategories();
      final Map<int, int> categoryIdMap = {};
      final List<dynamic> backupCats = data['categories'];

      for (final cat in backupCats) {
        final int backupId = cat['id'];
        final String catName = cat['category'];

        final matched = existingCats
            .where((c) => c.category.toLowerCase() == catName.toLowerCase())
            .firstOrNull;

        if (matched != null) {
          categoryIdMap[backupId] = matched.id;
        } else {
          final int newId = await _categoryRepo.createCategory(
            name: catName,
            emoji: cat['emoji'],
          );
          categoryIdMap[backupId] = newId;
          categoriesImported++;
        }
      }

      // 3. Import missing Spends (deduplicate by amount, category, date, note)
      final existingExpenses = await _expenseRepo.getAllExpenses();
      final List<dynamic> backupExpenses = data['expenses'];

      for (final exp in backupExpenses) {
        final int oldCatId = exp['categoryId'];
        final int? newCatId = categoryIdMap[oldCatId];
        if (newCatId == null) continue;

        final double amount = (exp['amount'] as num).toDouble();
        final DateTime date = DateTime.parse(exp['date']);
        final String? note = exp['note'];
        final bool isIncome = exp['isIncome'] ?? false;

        final isDuplicate = existingExpenses.any((e) =>
            (e.amount - amount).abs() < 0.01 &&
            e.category.id == newCatId &&
            e.isIncome == isIncome &&
            (e.note == note || (e.note == null && note == null)) &&
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day);

        if (!isDuplicate) {
          await _expenseRepo.addExpense(
            amount: amount,
            categoryId: newCatId,
            date: date,
            note: note,
            isIncome: isIncome,
          );
          expensesImported++;
        }
      }
    }

    return {
      'users': usersImported,
      'categories': categoriesImported,
      'expenses': expensesImported,
    };
  }
}
