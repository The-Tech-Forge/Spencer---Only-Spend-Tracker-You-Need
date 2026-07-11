import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../model/expense_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

/// A premium animated card for displaying a single expense in lists.
class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final int animationIndex;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categoryColor = expense.isIncome
        ? const Color(0xFF10B981)
        : _categoryColor(expense.category.category);

    return Animate(
      effects: [
        FadeEffect(
          duration: 300.ms,
          delay: Duration(milliseconds: animationIndex * 60),
        ),
        SlideEffect(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
          duration: 350.ms,
          delay: Duration(milliseconds: animationIndex * 60),
          curve: Curves.easeOutCubic,
        ),
      ],
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── Category emoji badge ──────────────────────────────────
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      expense.category.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const Gap(14),
                // ── Category & date ───────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.category.category,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (expense.note != null && expense.note!.isNotEmpty)
                        Text(
                          expense.note!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          DateFormatter.toDayMonthYear(expense.date),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                const Gap(8),
                // ── Amount ────────────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${expense.isIncome ? '+' : '-'} ${CurrencyFormatter.format(expense.amount)}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: expense.isIncome
                            ? const Color(0xFF10B981)
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      DateFormatter.toDayMonth(expense.date),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Maps category name to a distinct accent colour.
  Color _categoryColor(String category) {
    const map = {
      'Food': Color(0xFFFF6B6B),
      'Shopping': Color(0xFFFF9F43),
      'Travel': Color(0xFF54A0FF),
      'Fuel': Color(0xFFFF6348),
      'Medical': Color(0xFFEE5A24),
      'Entertainment': Color(0xFFA29BFE),
      'Bills': Color(0xFFFFD32A),
      'Education': Color(0xFF0BE881),
      'Investment': Color(0xFF00D2D3),
      'Salary': Color(0xFF10B981),
      'Others': Color(0xFF778CA3),
    };
    return map[category] ?? const Color(0xFF00BCD4);
  }
}
