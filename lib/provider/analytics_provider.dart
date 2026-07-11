import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/category_model.dart';
import '../repository/analytics_repository.dart';
import 'expense_provider.dart';

/// Repository provider.
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(expenseRepositoryProvider));
});

// ─── Month & Week Selection State ─────────────────────────────────────────────

/// The currently selected month for analytics. Defaults to current month.
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void nextMonth() {
    final now = DateTime.now();
    final next = DateTime(state.year, state.month + 1, 1);
    // Don't go into the future
    if (next.isBefore(DateTime(now.year, now.month, 1)) ||
        (next.year == now.year && next.month == now.month)) {
      state = next;
    }
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return state.year == now.year && state.month == now.month;
  }
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);

/// The currently selected week range for weekly analytics.
class SelectedWeekNotifier extends Notifier<({DateTime start, DateTime end})> {
  @override
  ({DateTime start, DateTime end}) build() => _currentWeek();

  static ({DateTime start, DateTime end}) _currentWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 6));
    return (start: start, end: end);
  }

  void previousWeek() {
    state = (
      start: state.start.subtract(const Duration(days: 7)),
      end: state.end.subtract(const Duration(days: 7)),
    );
  }

  void nextWeek() {
    final next = (
      start: state.start.add(const Duration(days: 7)),
      end: state.end.add(const Duration(days: 7)),
    );
    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);
    if (!next.start.isAfter(nowDate)) {
      state = next;
    }
  }

  void setWeek(DateTime weekStart) {
    state = (
      start: weekStart,
      end: weekStart.add(const Duration(days: 6)),
    );
  }
}

final selectedWeekProvider = NotifierProvider<SelectedWeekNotifier,
    ({DateTime start, DateTime end})>(SelectedWeekNotifier.new);

// ─── Analytics Providers (month-aware) ────────────────────────────────────────

/// Today's total expense.
final todayExpenseProvider = FutureProvider<double>((ref) {
  ref.watch(expensesStreamProvider);
  return ref.watch(analyticsRepositoryProvider).getTodayExpense();
});

/// Selected month's total expense.
final monthlyExpenseProvider = FutureProvider<double>((ref) {
  ref.watch(expensesStreamProvider);
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(analyticsRepositoryProvider).getMonthlyExpense(month: month);
});

/// Selected month's total income.
final monthlyIncomeProvider = FutureProvider<double>((ref) {
  ref.watch(expensesStreamProvider);
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(analyticsRepositoryProvider).getMonthlyIncome(month: month);
});

/// Average daily spend for the selected month.
final avgDailySpendProvider = FutureProvider<double>((ref) {
  ref.watch(expensesStreamProvider);
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(analyticsRepositoryProvider).getAverageDailySpend(month: month);
});

/// Expense totals grouped by category for the selected month.
final expensesByCategoryProvider =
    FutureProvider<Map<CategoryModel, double>>((ref) {
  ref.watch(expensesStreamProvider);
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(analyticsRepositoryProvider).getExpensesByCategory(month: month);
});

/// The highest-spending category in the selected month.
final highestCategoryProvider = FutureProvider<CategoryModel?>((ref) {
  ref.watch(expensesStreamProvider);
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(analyticsRepositoryProvider).getHighestCategory(month: month);
});

/// The lowest-spending (non-zero) category in the selected month.
final lowestCategoryProvider = FutureProvider<CategoryModel?>((ref) {
  ref.watch(expensesStreamProvider);
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(analyticsRepositoryProvider).getLowestCategory(month: month);
});

/// Top categories sorted by spend for the selected month.
final topCategoriesProvider =
    FutureProvider<List<MapEntry<CategoryModel, double>>>((ref) {
  ref.watch(expensesStreamProvider);
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(analyticsRepositoryProvider).getTopCategories(month: month);
});

/// Day → amount map for the selected week.
final weeklyExpenseProvider = FutureProvider<Map<DateTime, double>>((ref) {
  ref.watch(expensesStreamProvider);
  final week = ref.watch(selectedWeekProvider);
  return ref
      .watch(analyticsRepositoryProvider)
      .getExpensesByDateRange(start: week.start, end: week.end);
});

/// Day → amount map for the selected month.
final monthlyDailyExpenseProvider = FutureProvider<Map<DateTime, double>>((ref) {
  ref.watch(expensesStreamProvider);
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(analyticsRepositoryProvider)
      .getExpensesByDayForMonth(month: month);
});

/// Month → amount map for the last 6 months.
final expenseTrendProvider = FutureProvider<Map<DateTime, double>>((ref) {
  ref.watch(expensesStreamProvider);
  return ref.watch(analyticsRepositoryProvider).getExpenseTrend();
});

/// Category → (day → amount) map for selected week.
final categoryAcrossDaysProvider =
    FutureProvider<Map<CategoryModel, Map<DateTime, double>>>((ref) {
  ref.watch(expensesStreamProvider);
  final week = ref.watch(selectedWeekProvider);
  return ref
      .watch(analyticsRepositoryProvider)
      .getCategorySpendAcrossDateRange(start: week.start, end: week.end);
});
