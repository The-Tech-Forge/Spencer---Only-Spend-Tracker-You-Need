import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/expense_model.dart';
import '../repository/expense_repository.dart';
import 'database_provider.dart';

/// Repository provider.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(databaseProvider));
});

/// Live stream provider of all expenses.
/// Automatically triggers a UI rebuild when data changes in the database.
final expensesStreamProvider = StreamProvider<List<ExpenseModel>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAllExpenses();
});

/// Holds the current search query text.
class ExpenseSearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String query) => state = query;
}
final expenseSearchQueryProvider = NotifierProvider<ExpenseSearchQuery, String>(ExpenseSearchQuery.new);

/// Holds the selected category filter id (null = no filter).
class ExpenseCategoryFilter extends Notifier<int?> {
  @override
  int? build() => null;
  void updateFilter(int? filter) => state = filter;
}
final expenseCategoryFilterProvider = NotifierProvider<ExpenseCategoryFilter, int?>(ExpenseCategoryFilter.new);

/// Sort options for the expense list.
enum ExpenseSortOrder { dateDesc, dateAsc, amountDesc, amountAsc }

/// Holds the current sort order.
class ExpenseSortOrderNotifier extends Notifier<ExpenseSortOrder> {
  @override
  ExpenseSortOrder build() => ExpenseSortOrder.dateDesc;
  void updateOrder(ExpenseSortOrder order) => state = order;
}
final expenseSortOrderProvider =
    NotifierProvider<ExpenseSortOrderNotifier, ExpenseSortOrder>(ExpenseSortOrderNotifier.new);

/// Filtered, searched, and sorted expense list derived from the stream.
final filteredExpensesProvider = Provider<List<ExpenseModel>>((ref) {
  final asyncExpenses = ref.watch(expensesStreamProvider);
  final query = ref.watch(expenseSearchQueryProvider).toLowerCase();
  final categoryFilter = ref.watch(expenseCategoryFilterProvider);
  final sortOrder = ref.watch(expenseSortOrderProvider);

  return asyncExpenses.when(
    data: (expenses) {
      var filtered = expenses;

      // Apply category filter
      if (categoryFilter != null) {
        filtered = filtered
            .where((e) => e.category.id == categoryFilter)
            .toList();
      }

      // Apply search filter
      if (query.isNotEmpty) {
        filtered = filtered
            .where((e) =>
                e.category.category.toLowerCase().contains(query) ||
                (e.note?.toLowerCase().contains(query) ?? false))
            .toList();
      }

      // Apply sort
      switch (sortOrder) {
        case ExpenseSortOrder.dateDesc:
          filtered.sort((a, b) => b.date.compareTo(a.date));
        case ExpenseSortOrder.dateAsc:
          filtered.sort((a, b) => a.date.compareTo(b.date));
        case ExpenseSortOrder.amountDesc:
          filtered.sort((a, b) => b.amount.compareTo(a.amount));
        case ExpenseSortOrder.amountAsc:
          filtered.sort((a, b) => a.amount.compareTo(b.amount));
      }

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
