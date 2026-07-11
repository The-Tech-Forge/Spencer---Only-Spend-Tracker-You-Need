import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes/app_router.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/expense_card.dart';
import '../../model/expense_model.dart';
import '../../provider/category_provider.dart';
import '../../provider/expense_provider.dart';

/// Expense list screen with search, sort, and category filter.
class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showSortFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SortFilterSheet(),
    );
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    await ref.read(expenseRepositoryProvider).deleteExpense(expense.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${expense.category.category} expense deleted',
            style: GoogleFonts.outfit(),
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await ref.read(expenseRepositoryProvider).addExpense(
                    amount: expense.amount,
                    categoryId: expense.category.id,
                    date: expense.date,
                    note: expense.note,
                    isIncome: expense.isIncome,
                  );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(filteredExpensesProvider);
    final categoryFilter = ref.watch(expenseCategoryFilterProvider);
    final sortOrder = ref.watch(expenseSortOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          // Active filter badge
          if (categoryFilter != null || sortOrder != ExpenseSortOrder.dateDesc)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Filtered',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF00BCD4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Sort & Filter',
            onPressed: _showSortFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  ref.read(expenseSearchQueryProvider.notifier).updateQuery(v),
              decoration: InputDecoration(
                hintText: 'Search by category or note…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(expenseSearchQueryProvider.notifier)
                              .updateQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // ── List ───────────────────────────────────────────────────────
          Expanded(
            child: expenses.isEmpty
                ? EmptyState(
                    title: 'No expenses found',
                    subtitle: _searchCtrl.text.isNotEmpty
                        ? 'Try a different search term'
                        : 'Add your first expense with the + button',
                    emoji: '🧾',
                    action: _searchCtrl.text.isEmpty
                        ? ElevatedButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.addExpense),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Expense'),
                          )
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: expenses.length,
                    itemBuilder: (ctx, i) {
                      final expense = expenses[i];
                      return Dismissible(
                        key: ValueKey(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white, size: 26),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: Text('Delete Expense',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700)),
                              content: Text(
                                  'Are you sure you want to delete this expense?',
                                  style: GoogleFonts.outfit()),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade400),
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Delete')),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => _deleteExpense(expense),
                        child: ExpenseCard(
                          expense: expense,
                          animationIndex: i,
                          onTap: () => context.push(
                              '${AppRoutes.editExpense}/${expense.id}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addExpense),
        tooltip: 'Add Expense',
        child: const Icon(Icons.add_rounded),
      ).animate().scale(
          delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}

// ─── Sort & Filter Bottom Sheet ───────────────────────────────────────────────

class _SortFilterSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSort = ref.watch(expenseSortOrderProvider);
    final currentCat = ref.watch(expenseCategoryFilterProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Gap(20),
          Text('Sort & Filter',
              style: GoogleFonts.outfit(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const Gap(20),
          Text('SORT BY',
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00BCD4),
                  letterSpacing: 1)),
          const Gap(10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseSortOrder.values.map((order) {
              final label = switch (order) {
                ExpenseSortOrder.dateDesc => 'Newest First',
                ExpenseSortOrder.dateAsc => 'Oldest First',
                ExpenseSortOrder.amountDesc => 'Highest Amount',
                ExpenseSortOrder.amountAsc => 'Lowest Amount',
              };
              final isSelected = currentSort == order;
              return FilterChip(
                label: Text(label, style: GoogleFonts.outfit(fontSize: 13)),
                selected: isSelected,
                onSelected: (_) => ref
                    .read(expenseSortOrderProvider.notifier)
                    .updateOrder(order),
                backgroundColor: isDark
                    ? const Color(0xFF252A3A)
                    : const Color(0xFFF2F5F8),
                selectedColor: const Color(0xFF00BCD4).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF00BCD4),
              );
            }).toList(),
          ),
          const Gap(20),
          Text('FILTER BY CATEGORY',
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00BCD4),
                  letterSpacing: 1)),
          const Gap(10),
          categoriesAsync.when(
            data: (cats) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label:
                      Text('All', style: GoogleFonts.outfit(fontSize: 13)),
                  selected: currentCat == null,
                  onSelected: (_) => ref
                      .read(expenseCategoryFilterProvider.notifier)
                      .updateFilter(null),
                  backgroundColor: isDark
                      ? const Color(0xFF252A3A)
                      : const Color(0xFFF2F5F8),
                  selectedColor:
                      const Color(0xFF00BCD4).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF00BCD4),
                ),
                ...cats.map((cat) {
                  final isSelected = currentCat == cat.id;
                  return FilterChip(
                    label: Text('${cat.emoji} ${cat.category}',
                        style: GoogleFonts.outfit(fontSize: 13)),
                    selected: isSelected,
                    onSelected: (_) => ref
                        .read(expenseCategoryFilterProvider.notifier)
                        .updateFilter(isSelected ? null : cat.id),
                    backgroundColor: isDark
                        ? const Color(0xFF252A3A)
                        : const Color(0xFFF2F5F8),
                    selectedColor:
                        const Color(0xFF00BCD4).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFF00BCD4),
                  );
                }),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Error loading categories'),
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                ref.read(expenseSortOrderProvider.notifier).updateOrder(
                    ExpenseSortOrder.dateDesc);
                ref.read(expenseCategoryFilterProvider.notifier).updateFilter(
                    null);
                Navigator.pop(context);
              },
              child: Text('Reset All Filters',
                  style: GoogleFonts.outfit(
                      color: Colors.redAccent, fontWeight: FontWeight.w600)),
            ),
          ),
          Gap(MediaQuery.of(context).viewInsets.bottom + 8),
        ],
      ),
    );
  }
}
