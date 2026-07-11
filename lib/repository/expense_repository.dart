import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../model/category_model.dart';
import '../model/expense_model.dart';
import '../core/utils/date_formatter.dart';

/// Handles all database operations related to [Spend] records.
class ExpenseRepository {
  final AppDatabase _db;

  const ExpenseRepository(this._db);

  // ─── Conversions ──────────────────────────────────────────────────────────

  ExpenseModel _toModel(SpendWithCategory row) => ExpenseModel(
        id: row.spend.id,
        amount: row.spend.amount,
        category: CategoryModel(
          id: row.category.id,
          category: row.category.category,
          emoji: row.category.emoji,
        ),
        date: DateFormatter.fromIso(row.spend.date),
        note: row.spend.note,
        isIncome: row.spend.isIncome,
      );

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Returns all expenses/income, newest first.
  Future<List<ExpenseModel>> getAllExpenses() async {
    final rows = await _db.getAllSpends();
    return rows.map(_toModel).toList();
  }

  /// Live stream of all expenses — triggers UI rebuild on any change.
  Stream<List<ExpenseModel>> watchAllExpenses() {
    return _db.watchAllSpends().map((rows) => rows.map(_toModel).toList());
  }

  /// Returns expenses in a date range (inclusive).
  Future<List<ExpenseModel>> getExpensesBetween(
      DateTime start, DateTime end) async {
    final rows = await _db.getSpendsBetween(
      DateFormatter.toIso(start),
      DateFormatter.toIso(end),
    );
    return rows.map(_toModel).toList();
  }

  /// Returns expenses for a specific category.
  Future<List<ExpenseModel>> getExpensesByCategory(int categoryId) async {
    final rows = await _db.getSpendsByCategory(categoryId);
    return rows.map(_toModel).toList();
  }

  // ─── Write ────────────────────────────────────────────────────────────────

  /// Inserts a new expense and returns its id.
  Future<int> addExpense({
    required double amount,
    required int categoryId,
    required DateTime date,
    String? note,
    bool isIncome = false,
  }) {
    return _db.insertSpend(SpendsCompanion.insert(
      amount: amount,
      categoryId: categoryId,
      date: DateFormatter.toIso(date),
      note: Value(note),
      isIncome: Value(isIncome),
    ));
  }

  /// Updates an existing expense record.
  Future<bool> updateExpense(ExpenseModel expense) {
    return _db.updateSpend(SpendsCompanion(
      id: Value(expense.id),
      amount: Value(expense.amount),
      categoryId: Value(expense.category.id),
      date: Value(DateFormatter.toIso(expense.date)),
      note: Value(expense.note),
      isIncome: Value(expense.isIncome),
    ));
  }

  /// Deletes an expense by id. Returns the number of rows affected.
  Future<int> deleteExpense(int id) => _db.deleteSpend(id);
}
