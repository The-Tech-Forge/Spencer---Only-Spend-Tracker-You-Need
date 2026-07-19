import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/summary_card.dart';
import '../../model/category_model.dart';
import '../../provider/analytics_provider.dart';
import '../../provider/category_provider.dart';

/// Analytics screen with 8 charts powered by fl_chart.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedWeek = ref.watch(selectedWeekProvider);
    final monthNotifier = ref.read(selectedMonthProvider.notifier);
    final weekNotifier = ref.read(selectedWeekProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── Month Selector ────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252A3A) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: isDark
                  ? null
                  : Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => monthNotifier.previousMonth(),
                  color: const Color(0xFF00BCD4),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: colorScheme.copyWith(
                            primary: const Color(0xFF00BCD4),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) monthNotifier.setMonth(picked);
                  },
                  child: Text(
                    DateFormatter.toMonthYear(selectedMonth),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: monthNotifier.isCurrentMonth
                      ? null
                      : () => monthNotifier.nextMonth(),
                  color: monthNotifier.isCurrentMonth
                      ? colorScheme.onSurface.withValues(alpha: 0.3)
                      : const Color(0xFF00BCD4),
                ),
              ],
            ),
          ),

          // ── Monthly Summary Cards ─────────────────────────────────────────
          _SectionHeader('Monthly Summary'),
          _MonthlySummarySection(),
          const Gap(24),

          // ── Week Selector + Weekly Bar Chart ──────────────────────────────
          _SectionHeader('Weekly Spending'),
          // Week navigation
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252A3A) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: isDark
                  ? null
                  : Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => weekNotifier.previousWeek(),
                  color: const Color(0xFF00BCD4),
                ),
                Text(
                  '${DateFormatter.toDayMonth(selectedWeek.start)} – ${DateFormatter.toDayMonth(selectedWeek.end)}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => weekNotifier.nextWeek(),
                  color: const Color(0xFF00BCD4),
                ),
              ],
            ),
          ),
          _WeeklyBarChart(),
          const Gap(24),

          // ── Day-Wise Line Chart ───────────────────────────────────────────
          _SectionHeader('Daily Spend (This Month)'),
          _DayWiseLineChart(),
          const Gap(24),

          // ── Overall Category Spend (Month) ────────────────────────────────
          _SectionHeader('Category Monthly Spend'),
          const _CategoryMonthlySpendSection(),
          const Gap(24),

          // ── Category Pie Chart ────────────────────────────────────────────
          _SectionHeader('Spend by Category'),
          _CategoryPieChart(),
          const Gap(24),

          // ── Top Categories Horizontal Bar ─────────────────────────────────
          _SectionHeader('Top Categories'),
          _TopCategoriesChart(),
          const Gap(24),

          // ── Monthly Trend Line Chart ──────────────────────────────────────
          _SectionHeader('Monthly Trend (6 Months)'),
          _MonthlyTrendChart(),
          const Gap(24),

          // ── Category Across Days Multi-Line ──────────────────────────────
          _SectionHeader('Category Trend (This Week)'),
          _CategoryAcrossDaysChart(),
          const Gap(24),

          // ── Per-Day Category Bar Chart ────────────────────────────────────
          _SectionHeader('Daily Category Breakdown'),
          _PerDayCategoryChart(),
          const Gap(24),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

// ─── Chart Card Wrapper ───────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final Widget child;
  final double height;

  const _ChartCard({required this.child, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(height: height, child: child),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ─── 8. Monthly Summary Cards ─────────────────────────────────────────────────

class _MonthlySummarySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyExp = ref.watch(monthlyExpenseProvider);
    final monthlyInc = ref.watch(monthlyIncomeProvider);
    final avgDaily = ref.watch(avgDailySpendProvider);
    final highCat = ref.watch(highestCategoryProvider);
    final lowCat = ref.watch(lowestCategoryProvider);

    final expense = monthlyExp.value ?? 0;
    final income = monthlyInc.value ?? 0;
    final savings = income - expense;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 0,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        SummaryCard(
          title: 'EXPENSE',
          value: CurrencyFormatter.compact(expense),
          icon: Icons.arrow_upward_rounded,
          accentColor: const Color(0xFFFF6B6B),
          animationIndex: 0,
        ),
        SummaryCard(
          title: 'INCOME',
          value: CurrencyFormatter.compact(income),
          icon: Icons.arrow_downward_rounded,
          accentColor: const Color(0xFF10B981),
          animationIndex: 1,
        ),
        SummaryCard(
          title: 'SAVINGS',
          value: CurrencyFormatter.compact(savings.abs()),
          subtitle: savings >= 0 ? 'Surplus' : 'Deficit',
          icon: Icons.savings_rounded,
          accentColor: savings >= 0
              ? const Color(0xFF00BCD4)
              : const Color(0xFFFF9F43),
          animationIndex: 2,
        ),
        SummaryCard(
          title: 'AVG DAILY',
          value: CurrencyFormatter.compact(avgDaily.value ?? 0),
          icon: Icons.show_chart_rounded,
          accentColor: const Color(0xFFA29BFE),
          animationIndex: 3,
        ),
        highCat.when(
          data: (cat) => SummaryCard(
            title: 'HIGHEST',
            value: cat?.emoji ?? '—',
            subtitle: cat?.category ?? 'No data',
            icon: Icons.trending_up_rounded,
            accentColor: const Color(0xFFFF9F43),
            animationIndex: 4,
          ),
          loading: () => SummaryCard(
            title: 'HIGHEST',
            value: '—',
            icon: Icons.trending_up_rounded,
            accentColor: const Color(0xFFFF9F43),
            animationIndex: 4,
          ),
          error: (_, __) => SummaryCard(
            title: 'HIGHEST',
            value: '—',
            icon: Icons.trending_up_rounded,
            accentColor: const Color(0xFFFF9F43),
            animationIndex: 4,
          ),
        ),
        lowCat.when(
          data: (cat) => SummaryCard(
            title: 'LOWEST',
            value: cat?.emoji ?? '—',
            subtitle: cat?.category ?? 'No data',
            icon: Icons.trending_down_rounded,
            accentColor: const Color(0xFF54A0FF),
            animationIndex: 5,
          ),
          loading: () => SummaryCard(
            title: 'LOWEST',
            value: '—',
            icon: Icons.trending_down_rounded,
            accentColor: const Color(0xFF54A0FF),
            animationIndex: 5,
          ),
          error: (_, __) => SummaryCard(
            title: 'LOWEST',
            value: '—',
            icon: Icons.trending_down_rounded,
            accentColor: const Color(0xFF54A0FF),
            animationIndex: 5,
          ),
        ),
      ],
    );
  }
}

// ─── 7. Weekly Bar Chart ──────────────────────────────────────────────────────

class _WeeklyBarChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklyExpenseProvider);
    return async.when(
      data: (data) {
        if (data.isEmpty || data.values.every((v) => v == 0)) {
          return _ChartCard(
            child: Center(
              child: Text(
                'No data',
                style: GoogleFonts.outfit(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          );
        }
        final entries = data.entries.toList();
        final maxY = entries.map((e) => e.value).reduce(max);

        return _ChartCard(
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      CurrencyFormatter.compact(rod.toY),
                      GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormatter.toDayName(entries[idx].key),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          CurrencyFormatter.compact(value),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              barGroups: entries.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.value,
                      color: const Color(0xFF00BCD4),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY * 1.2,
                        color: const Color(0xFF00BCD4).withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
          ),
        );
      },
      loading: () =>
          const _ChartCard(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ChartCard(child: Center(child: Text('Error: $e'))),
    );
  }
}

// ─── 1. Day-Wise Spend Line Chart ─────────────────────────────────────────────

class _DayWiseLineChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(monthlyDailyExpenseProvider);

    return async.when(
      data: (data) {
        if (data.isEmpty || data.values.every((v) => v == 0)) {
          return _ChartCard(
            child: Center(
              child: Text(
                'No data',
                style: GoogleFonts.outfit(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          );
        }
        final entries = data.entries.toList();
        final maxY = entries.map((e) => e.value).reduce(max);
        final chartMax = maxY == 0 ? 100.0 : maxY * 1.2;
        final interval = max(1.0, chartMax / 4);

        return _ChartCard(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY * 1.2,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((spot) {
                    final idx = spot.x.toInt();
                    final date = idx < entries.length ? entries[idx].key : null;
                    return LineTooltipItem(
                      '${date != null ? DateFormatter.toDayMonth(date) : ''}\n${CurrencyFormatter.compact(spot.y)}',
                      GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    );
                  }).toList(),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 7,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormatter.toDayMonth(entries[idx].key),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      // Don't draw labels outside the chart range
                      if (value < 0 || value > chartMax) {
                        return const SizedBox.shrink();
                      }

                      return SideTitleWidget(
                        meta: meta,
                        space: 8,
                        child: Text(
                          CurrencyFormatter.compact(value),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: entries.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.value);
                  }).toList(),
                  isCurved: true,
                  color: const Color(0xFF00BCD4),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00BCD4).withValues(alpha: 0.2),
                        const Color(0xFF00BCD4).withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
          ),
        );
      },
      loading: () =>
          const _ChartCard(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ChartCard(child: Center(child: Text('Error: $e'))),
    );
  }
}

// ─── 2. Category Pie Chart ────────────────────────────────────────────────────

class _CategoryPieChart extends ConsumerWidget {
  final _colors = const [
    Color(0xFF00BCD4),
    Color(0xFFA29BFE),
    Color(0xFFFF6B6B),
    Color(0xFFFF9F43),
    Color(0xFF10B981),
    Color(0xFF54A0FF),
    Color(0xFFFFD32A),
    Color(0xFFEE5A24),
    Color(0xFF0BE881),
    Color(0xFF00D2D3),
    Color(0xFF778CA3),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expensesByCategoryProvider);

    return async.when(
      data: (data) {
        if (data.isEmpty) {
          return _ChartCard(
            height: 280,
            child: Center(
              child: Text(
                'No data',
                style: GoogleFonts.outfit(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          );
        }
        final entries = data.entries.toList();
        final total = entries.fold(0.0, (s, e) => s + e.value);

        return _ChartCard(
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 52,
                    pieTouchData: PieTouchData(enabled: true),
                    sections: entries.asMap().entries.map((e) {
                      final pct = (e.value.value / total * 100);
                      final color = _colors[e.key % _colors.length];
                      return PieChartSectionData(
                        value: e.value.value,
                        color: color,
                        radius: 60,
                        title: '${pct.toStringAsFixed(0)}%',
                        titleStyle: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        showTitle: pct >= 5,
                      );
                    }).toList(),
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                ),
              ),
              const Gap(12),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: entries.asMap().entries.map((e) {
                  final color = _colors[e.key % _colors.length];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '${e.value.key.emoji} ${e.value.key.category}',
                        style: GoogleFonts.outfit(fontSize: 11),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const _ChartCard(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          _ChartCard(height: 280, child: Center(child: Text('Error: $e'))),
    );
  }
}

// ─── 6. Top Categories Horizontal Bar ────────────────────────────────────────

class _TopCategoriesChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return async.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('No data', style: GoogleFonts.outfit()),
              ),
            ),
          );
        }
        final maxValue = entries.first.value;

        return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: entries.asMap().entries.map((e) {
                    final idx = e.key;
                    final cat = e.value.key;
                    final amount = e.value.value;
                    final pct = maxValue > 0 ? amount / maxValue : 0.0;
                    final colors = [
                      const Color(0xFF00BCD4),
                      const Color(0xFFA29BFE),
                      const Color(0xFFFF6B6B),
                      const Color(0xFFFF9F43),
                      const Color(0xFF10B981),
                      const Color(0xFF54A0FF),
                    ];
                    final color = colors[idx % colors.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                cat.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  cat.category,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.compact(amount),
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const Gap(6),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: pct),
                            duration: Duration(milliseconds: 600 + idx * 100),
                            curve: Curves.easeOutCubic,
                            builder: (_, value, __) => ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor: isDark
                                    ? const Color(0xFF252A3A)
                                    : const Color(0xFFF2F5F8),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(
              begin: 0.1,
              end: 0,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

// ─── 5. Monthly Trend Line Chart ──────────────────────────────────────────────

class _MonthlyTrendChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expenseTrendProvider);

    return async.when(
      data: (data) {
        final entries = data.entries.toList();

        final maxY = entries.map((e) => e.value).fold(0.0, max);
        final chartMax = maxY == 0 ? 100.0 : maxY * 1.25;
        final interval = max(1.0, chartMax / 4);
        return _ChartCard(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: chartMax,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((spot) {
                    final idx = spot.x.toInt();
                    final date = idx < entries.length ? entries[idx].key : null;
                    return LineTooltipItem(
                      '${date != null ? DateFormatter.toShortMonth(date) : ''}\n${CurrencyFormatter.compact(spot.y)}',
                      GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    );
                  }).toList(),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormatter.toShortMonth(entries[idx].key),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > chartMax) {
                        return const SizedBox.shrink();
                      }

                      return SideTitleWidget(
                        meta: meta,
                        space: 2,
                        child: Text(
                          CurrencyFormatter.compact(value),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: entries.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.value);
                  }).toList(),
                  isCurved: true,
                  color: const Color(0xFFA29BFE),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFFA29BFE),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFA29BFE).withValues(alpha: 0.18),
                        const Color(0xFFA29BFE).withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
          ),
        );
      },
      loading: () =>
          const _ChartCard(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ChartCard(child: Center(child: Text('Error: $e'))),
    );
  }
}

// ─── 4. Category Across Days Multi-Line ──────────────────────────────────────

class _CategoryAcrossDaysChart extends ConsumerWidget {
  final _colors = const [
    Color(0xFF00BCD4),
    Color(0xFFA29BFE),
    Color(0xFFFF6B6B),
    Color(0xFFFF9F43),
    Color(0xFF10B981),
    Color(0xFF54A0FF),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoryAcrossDaysProvider);

    return async.when(
      data: (data) {
        if (data.isEmpty) {
          return _ChartCard(
            child: Center(child: Text('No data', style: GoogleFonts.outfit())),
          );
        }
        final categories = data.keys.toList();
        final days = data.values.first.keys.toList()..sort();
        final maxY = data.values.expand((m) => m.values).fold(0.0, max);
        final chartMax = maxY == 0 ? 100.0 : maxY * 1.25;
        final interval = max(1.0, chartMax / 4);

        return _ChartCard(
          height: 260,
          child: Column(
            children: [
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: chartMax,
                    lineTouchData: const LineTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= days.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormatter.toDayMonth(days[idx]),
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: interval,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value > chartMax) {
                              return const SizedBox.shrink();
                            }

                            return SideTitleWidget(
                              meta: meta,
                              space: 2,
                              child: Text(
                                CurrencyFormatter.compact(value),
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.06),
                        strokeWidth: 1,
                      ),
                      drawVerticalLine: false,
                    ),
                    lineBarsData: categories.asMap().entries.map((e) {
                      final idx = e.key;
                      final cat = e.value;
                      final dayMap = data[cat]!;
                      final color = _colors[idx % _colors.length];
                      return LineChartBarData(
                        spots: days.asMap().entries.map((d) {
                          return FlSpot(d.key.toDouble(), dayMap[d.value] ?? 0);
                        }).toList(),
                        isCurved: true,
                        color: color,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      );
                    }).toList(),
                  ),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                ),
              ),
              const Gap(8),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: categories.asMap().entries.map((e) {
                  final color = _colors[e.key % _colors.length];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 3,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '${e.value.emoji} ${e.value.category}',
                        style: GoogleFonts.outfit(fontSize: 10),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const _ChartCard(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ChartCard(child: Center(child: Text('Error: $e'))),
    );
  }
}

// ─── 3. Per-Day Category Grouped Bar Chart ────────────────────────────────────

class _PerDayCategoryChart extends ConsumerWidget {
  final _colors = const [
    Color(0xFF00BCD4),
    Color(0xFFA29BFE),
    Color(0xFFFF6B6B),
    Color(0xFFFF9F43),
    Color(0xFF10B981),
    Color(0xFF54A0FF),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoryAcrossDaysProvider);

    return async.when(
      data: (data) {
        if (data.isEmpty) {
          return _ChartCard(
            child: Center(child: Text('No data', style: GoogleFonts.outfit())),
          );
        }
        final categories = data.keys.take(5).toList();
        final days = data.values.first.keys.toList()..sort();
        final maxY = data.values.expand((m) => m.values).fold(0.0, max);
        final chartMax = maxY == 0 ? 100.0 : maxY * 1.2;
        final interval = max(1.0, chartMax / 4);
        return _ChartCard(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: chartMax,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gIdx, rod, rIdx) {
                    final cat = rIdx < categories.length
                        ? categories[rIdx]
                        : null;
                    return BarTooltipItem(
                      '${cat?.emoji ?? ''} ${CurrencyFormatter.compact(rod.toY)}',
                      GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= days.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormatter.toDayName(days[idx]),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > chartMax) {
                        return const SizedBox.shrink();
                      }

                      return SideTitleWidget(
                        meta: meta,
                        space: 2,
                        child: Text(
                          CurrencyFormatter.compact(value),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.06),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              barGroups: days.asMap().entries.map((d) {
                return BarChartGroupData(
                  x: d.key,
                  barRods: categories.asMap().entries.map((c) {
                    final amount = data[c.value]?[d.value] ?? 0;
                    final color = _colors[c.key % _colors.length];
                    return BarChartRodData(
                      toY: amount,
                      color: color,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
          ),
        );
      },
      loading: () =>
          const _ChartCard(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ChartCard(child: Center(child: Text('Error: $e'))),
    );
  }
}

// ─── 9. Category Monthly Spend Section ────────────────────────────────────────

class _CategoryMonthlySpendSection extends ConsumerStatefulWidget {
  const _CategoryMonthlySpendSection();

  @override
  ConsumerState<_CategoryMonthlySpendSection> createState() =>
      _CategoryMonthlySpendSectionState();
}

class _CategoryMonthlySpendSectionState
    extends ConsumerState<_CategoryMonthlySpendSection> {
  CategoryModel? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final expensesByCategoryAsync = ref.watch(expensesByCategoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return _ChartCard(
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          categoriesAsync.when(
            data: (cats) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2230) : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CategoryModel>(
                  value: _selectedCategory,
                  hint: Text(
                    'Select a category',
                    style: GoogleFonts.outfit(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  isExpanded: true,
                  items: cats.map((cat) {
                    return DropdownMenuItem<CategoryModel>(
                      value: cat,
                      child: Row(
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                          const Gap(8),
                          Text(cat.category, style: GoogleFonts.outfit()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (cat) => setState(() => _selectedCategory = cat),
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading categories',
                style: GoogleFonts.outfit(color: Colors.red)),
          ),
          const Gap(16),
          Expanded(
            child: expensesByCategoryAsync.when(
              data: (expensesMap) {
                if (_selectedCategory == null) {
                  return Center(
                    child: Text(
                      'Please select a category to view spend',
                      style: GoogleFonts.outfit(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                final spend = expensesMap.entries
                        .where((e) => e.key.id == _selectedCategory!.id)
                        .map((e) => e.value)
                        .firstOrNull ??
                    0.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total Spend',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Gap(4),
                    Text(
                      CurrencyFormatter.format(spend),
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error loading data',
                    style: GoogleFonts.outfit(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
