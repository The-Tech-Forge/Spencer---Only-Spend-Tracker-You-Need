import '../model/category_model.dart';
import '../model/expense_model.dart';
import '../core/utils/date_formatter.dart';
import 'expense_repository.dart';

/// Exposes analytics-ready aggregations derived from raw expense data.
/// All calculations happen here — the UI receives ready-to-render data.
class AnalyticsRepository {
  final ExpenseRepository _expenseRepo;

  const AnalyticsRepository(this._expenseRepo);

  DateTime _getMonthEnd(DateTime start) {
    return DateTime(start.year, start.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
  }

  // ─── Single values ────────────────────────────────────────────────────────

  /// Total expense amount for today (expenses only, not income).
  Future<double> getTodayExpense() async {
    final today = DateFormatter.todayStart;
    final expenses = await _expenseRepo.getExpensesBetween(today, today);
    return _sumExpenses(expenses);
  }

  /// Total expense amount for a given month.
  Future<double> getMonthlyExpense({DateTime? month}) async {
    final start = month ?? DateFormatter.monthStart;
    final end = _getMonthEnd(start);
    final expenses = await _expenseRepo.getExpensesBetween(start, end);
    return _sumExpenses(expenses);
  }

  /// Total income for a given month.
  Future<double> getMonthlyIncome({DateTime? month}) async {
    final start = month ?? DateFormatter.monthStart;
    final end = _getMonthEnd(start);
    final expenses = await _expenseRepo.getExpensesBetween(start, end);
    return _sumIncome(expenses);
  }

  // ─── Category aggregations ────────────────────────────────────────────────

  /// Returns expense totals grouped by category (expenses only) for a given month.
  Future<Map<CategoryModel, double>> getExpensesByCategory({DateTime? month}) async {
    final start = month ?? DateFormatter.monthStart;
    final end = _getMonthEnd(start);
    final expenses = await _expenseRepo.getExpensesBetween(start, end);
    final only = expenses.where((e) => !e.isIncome).toList();
    return _groupByCategory(only);
  }

  /// Returns the category with the highest total spend in a given month.
  Future<CategoryModel?> getHighestCategory({DateTime? month}) async {
    final byCat = await getExpensesByCategory(month: month);
    if (byCat.isEmpty) return null;
    return byCat.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// Returns the category with the lowest (non-zero) total spend in a given month.
  Future<CategoryModel?> getLowestCategory({DateTime? month}) async {
    final byCat = await getExpensesByCategory(month: month);
    final nonZero = Map.fromEntries(
        byCat.entries.where((e) => e.value > 0));
    if (nonZero.isEmpty) return null;
    return nonZero.entries
        .reduce((a, b) => a.value <= b.value ? a : b)
        .key;
  }

  /// Returns top N categories sorted by total spend (descending) in a given month.
  Future<List<MapEntry<CategoryModel, double>>> getTopCategories(
      {DateTime? month, int limit = 6}) async {
    final byCat = await getExpensesByCategory(month: month);
    final sorted = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  // ─── Time-series ──────────────────────────────────────────────────────────

  /// Returns day → total expense map for a given calendar month.
  Future<Map<DateTime, double>> getExpensesByDayForMonth({required DateTime month}) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final daysInMonth = end.day;
    final dates = List.generate(daysInMonth, (i) => DateTime(month.year, month.month, i + 1));
    final expenses = await _expenseRepo.getExpensesBetween(start, end);
    final only = expenses.where((e) => !e.isIncome).toList();
    return _groupByDay(only, dates);
  }

  /// Returns day → total expense map for a custom date range.
  Future<Map<DateTime, double>> getExpensesByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final daysDiff = end.difference(start).inDays + 1;
    final dates = List.generate(daysDiff, (i) => start.add(Duration(days: i)));
    final expenses = await _expenseRepo.getExpensesBetween(start, end);
    final only = expenses.where((e) => !e.isIncome).toList();
    return _groupByDay(only, dates);
  }

  /// Returns month → total expense for the last [months] months.
  Future<Map<DateTime, double>> getExpenseTrend({int months = 6}) async {
    final result = <DateTime, double>{};
    final now = DateTime.now();
    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final expenses =
          await _expenseRepo.getExpensesBetween(month, monthEnd);
      result[month] = _sumExpenses(expenses);
    }
    return result;
  }

  /// Returns category → (day → total) map for a custom date range.
  Future<Map<CategoryModel, Map<DateTime, double>>>
      getCategorySpendAcrossDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final daysDiff = end.difference(start).inDays + 1;
    final dates = List.generate(daysDiff, (i) => start.add(Duration(days: i)));
    final expenses = await _expenseRepo.getExpensesBetween(start, end);
    final only = expenses.where((e) => !e.isIncome).toList();

    final result = <CategoryModel, Map<DateTime, double>>{};
    for (final e in only) {
      final cat = e.category;
      final day = DateFormatter.startOfDay(e.date);
      result.putIfAbsent(cat, () => {for (final d in dates) d: 0.0});
      if (result[cat]!.containsKey(day)) {
        result[cat]![day] = (result[cat]![day] ?? 0) + e.amount;
      }
    }
    return result;
  }

  /// Average daily spend for a given month.
  Future<double> getAverageDailySpend({DateTime? month}) async {
    final m = month ?? DateTime.now();
    final monthly = await getMonthlyExpense(month: m);
    final now = DateTime.now();
    final isCurrentMonth = m.year == now.year && m.month == now.month;
    final days = isCurrentMonth ? now.day : DateTime(m.year, m.month + 1, 0).day;
    return days > 0 ? monthly / days : 0;
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  double _sumExpenses(List<ExpenseModel> list) => list
      .where((e) => !e.isIncome)
      .fold(0.0, (sum, e) => sum + e.amount);

  double _sumIncome(List<ExpenseModel> list) => list
      .where((e) => e.isIncome)
      .fold(0.0, (sum, e) => sum + e.amount);

  Map<CategoryModel, double> _groupByCategory(List<ExpenseModel> list) {
    final map = <CategoryModel, double>{};
    for (final e in list) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  Map<DateTime, double> _groupByDay(
      List<ExpenseModel> list, List<DateTime> dates) {
    final map = {for (final d in dates) d: 0.0};
    for (final e in list) {
      final day = DateFormatter.startOfDay(e.date);
      if (map.containsKey(day)) {
        map[day] = map[day]! + e.amount;
      }
    }
    return map;
  }
}
