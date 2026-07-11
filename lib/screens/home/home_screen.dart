import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes/app_router.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/expense_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/summary_card.dart';
import '../../provider/analytics_provider.dart';
import '../../provider/expense_provider.dart';
import '../../provider/user_provider.dart';

/// Home dashboard showing welcome message, summary cards, and recent expenses.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final todayAsync = ref.watch(todayExpenseProvider);
    final monthlyAsync = ref.watch(monthlyExpenseProvider);
    final highestCatAsync = ref.watch(highestCategoryProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    userAsync.when(
                      data: (user) => Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_greeting()} 👋',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  user?.firstname ?? 'Friend',
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Date chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF212638)
                                  : const Color(0xFFE8F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              DateFormatter.toDayMonthYear(DateTime.now()),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF00BCD4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(16),

                  // ── Summary cards ──────────────────────────────────────
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 0,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      SummaryCard(
                        title: "TODAY'S SPEND",
                        value: todayAsync.when(
                          data: (v) => CurrencyFormatter.compact(v),
                          loading: () => '—',
                          error: (_, __) => '—',
                        ),
                        subtitle: DateFormatter.toDayMonthYear(DateTime.now()),
                        icon: Icons.today_rounded,
                        accentColor: const Color(0xFF00BCD4),
                        animationIndex: 0,
                      ),
                      SummaryCard(
                        title: 'THIS MONTH',
                        value: monthlyAsync.when(
                          data: (v) => CurrencyFormatter.compact(v),
                          loading: () => '—',
                          error: (_, __) => '—',
                        ),
                        subtitle: DateFormatter.toMonthYear(DateTime.now()),
                        icon: Icons.calendar_month_rounded,
                        accentColor: const Color(0xFFA29BFE),
                        animationIndex: 1,
                      ),
                      highestCatAsync.when(
                        data: (cat) => SummaryCard(
                          title: 'TOP CATEGORY',
                          value: cat?.emoji ?? '—',
                          subtitle: cat?.category ?? 'No data yet',
                          icon: Icons.star_rounded,
                          accentColor: const Color(0xFFFF9F43),
                          animationIndex: 2,
                        ),
                        loading: () => SummaryCard(
                          title: 'TOP CATEGORY',
                          value: '—',
                          subtitle: 'Loading...',
                          icon: Icons.star_rounded,
                          accentColor: const Color(0xFFFF9F43),
                          animationIndex: 2,
                        ),
                        error: (_, __) => SummaryCard(
                          title: 'TOP CATEGORY',
                          value: '—',
                          subtitle: 'No data yet',
                          icon: Icons.star_rounded,
                          accentColor: const Color(0xFFFF9F43),
                          animationIndex: 2,
                        ),
                      ),
                      SummaryCard(
                        title: 'EXPENSES',
                        value: expensesAsync.when(
                          data: (list) =>
                              list.where((e) => !e.isIncome).length.toString(),
                          loading: () => '—',
                          error: (_, __) => '—',
                        ),
                        subtitle: 'Total records',
                        icon: Icons.receipt_long_rounded,
                        accentColor: const Color(0xFFFF6B6B),
                        animationIndex: 3,
                      ),
                    ],
                  ),

                  const Gap(28),

                  // ── Recent Expenses ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Expenses',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.expense),
                        child: Text(
                          'See All',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00BCD4),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Gap(4),

                  expensesAsync.when(
                    data: (expenses) {
                      final recent = expenses
                          .where((e) => !e.isIncome)
                          .take(5)
                          .toList();
                      if (recent.isEmpty) {
                        return EmptyState(
                          title: 'No expenses yet',
                          subtitle: 'Tap the + button to add your first expense',
                          emoji: '💸',
                          action: ElevatedButton.icon(
                            onPressed: () => context.push(AppRoutes.addExpense),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Expense'),
                          ),
                        );
                      }
                      return Column(
                        children: recent.asMap().entries.map((entry) {
                          return ExpenseCard(
                            expense: entry.value,
                            animationIndex: entry.key,
                            onTap: () => context.push(
                              '${AppRoutes.editExpense}/${entry.value.id}',
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addExpense),
        tooltip: 'Add Expense',
        child: const Icon(Icons.add_rounded),
      )
          .animate()
          .scale(delay: 600.ms, duration: 400.ms, curve: Curves.easeOutBack)
          .fadeIn(delay: 600.ms, duration: 400.ms),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
