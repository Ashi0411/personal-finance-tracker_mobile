import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/export_helper.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/category_icon_helper.dart';
import '../../widgets/hover_lift_card.dart';
import '../../widgets/month_year_picker_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _touchedIndex = -1;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      final txProvider = Provider.of<TransactionProvider>(context, listen: false);
      reportProvider.fetchReport(fallbackTransactions: txProvider.transactions);
    });
  }

  void _showExportOptions(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Export Financial Records',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Download printable PDF statement or CSV spreadsheet',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.expense, size: 22),
                ),
                title: const Text('Download PDF Statement', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Complete formatted financial overview with tables and KPIs', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ExportHelper.exportPdfReport(
                    report: reportProvider.report,
                    transactions: txProvider.transactions,
                    user: authProvider.currentUser,
                    currencySymbol: themeProvider.currencySymbol,
                  );
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: AppColors.income, size: 22),
                ),
                title: const Text('Export CSV (Excel / Sheets)', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Raw transactions data spreadsheet', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ExportHelper.exportCsvReport(
                    txProvider.transactions,
                    themeProvider.currencySymbol,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final reportProvider = Provider.of<ReportProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    final report = reportProvider.report;
    final categories = report.categoryBreakdowns;
    final cashflows = report.cashflows;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, size: 22),
            tooltip: 'Export PDF / CSV',
            onPressed: () => _showExportOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => reportProvider.fetchReport(),
          ),
        ],
      ),
      body: reportProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 90),
              children: [
                // Quick Export Banner Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEEF2FF), Color(0xFFFAF5FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Export Financial Statement',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E1B4B)),
                            ),
                            Text(
                              'Download official PDF & CSV records',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showExportOptions(context),
                        icon: const Icon(Icons.download_rounded, size: 14),
                        label: const Text('Export', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Period Selector Bar
                Align(
                  alignment: Alignment.centerRight,
                  child: MonthYearPickerBar(
                    selectedDate: _selectedDate,
                    isDark: isDark,
                    primaryColor: const Color(0xFF6366F1),
                    onDateChanged: (newDate) {
                      setState(() => _selectedDate = newDate);
                      reportProvider.setYear(newDate.year);
                      reportProvider.setMonth(newDate.month);
                      reportProvider.fetchReport(fallbackTransactions: txProvider.transactions);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                // Period Toggle (Monthly vs Yearly)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => reportProvider.setPeriodType('monthly'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: reportProvider.periodType == 'monthly' ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Monthly Report',
                              style: TextStyle(
                                color: reportProvider.periodType == 'monthly' ? Colors.white : null,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => reportProvider.setPeriodType('yearly'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: reportProvider.periodType == 'yearly' ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Annual Report',
                              style: TextStyle(
                                color: reportProvider.periodType == 'yearly' ? Colors.white : null,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 4-Tier Financial Summary Card
                HoverLiftCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  glowColor: AppColors.primary,
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem(
                            'Total Income',
                            Formatters.currency(report.totalIncome, symbol: themeProvider.currencySymbol),
                            AppColors.income,
                            isDark,
                          ),
                          _buildSummaryItem(
                            'Total Expenses',
                            Formatters.currency(report.totalExpense, symbol: themeProvider.currencySymbol),
                            AppColors.expense,
                            isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem(
                            'Net Savings',
                            Formatters.currency(report.netSavings, symbol: themeProvider.currencySymbol),
                            AppColors.balance,
                            isDark,
                          ),
                          _buildSummaryItem(
                            'Savings Rate',
                            Formatters.percentage(report.savingsRate),
                            AppColors.savings,
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Cash Flow Bar Chart
                Text(
                  'Cash Flow Trend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                HoverLiftCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  glowColor: AppColors.income,
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  child: SizedBox(
                    height: 190,
                    child: cashflows.isEmpty
                        ? const Center(child: Text('No cash flow records yet. Add income & expenses to see charts!'))
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: cashflows.fold<double>(0.0, (max, cf) => cf.income > max ? cf.income : (cf.expense > max ? cf.expense : max)) * 1.2,
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final cf = cashflows[groupIndex];
                                    final isIncomeRod = rodIndex == 0;
                                    return BarTooltipItem(
                                      '${cf.month}\n${isIncomeRod ? 'Income: ' : 'Expense: '}${Formatters.currency(rod.toY, symbol: themeProvider.currencySymbol)}',
                                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (val, meta) {
                                      final index = val.toInt();
                                      if (index >= 0 && index < cashflows.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            cashflows[index].month,
                                            style: TextStyle(
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: cashflows.asMap().entries.map((entry) {
                                final index = entry.key;
                                final cf = entry.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: cf.income,
                                      color: AppColors.income,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    BarChartRodData(
                                      toY: cf.expense,
                                      color: AppColors.expense,
                                      width: 10,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // Category Spending Breakdown Doughnut Chart
                Text(
                  'Spending by Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                HoverLiftCard(
                  padding: const EdgeInsets.all(18),
                  borderRadius: 20,
                  glowColor: AppColors.expense,
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  child: categories.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No spending data logged for this period')))
                      : Column(
                          children: [
                            SizedBox(
                              height: 180,
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 3,
                                  centerSpaceRadius: 46,
                                  sections: categories.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final cat = entry.value;
                                    final isTouched = i == _touchedIndex;
                                    final radius = isTouched ? 42.0 : 34.0;
                                    final color = CategoryIconHelper.parseColor(cat.color);

                                    return PieChartSectionData(
                                      color: color,
                                      value: cat.totalAmount,
                                      title: '${cat.percentage.toStringAsFixed(0)}%',
                                      radius: radius,
                                      titleStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Category legend list
                            ...categories.map((c) {
                              final catColor = CategoryIconHelper.parseColor(c.color);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        c.categoryName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      '${c.percentage.toStringAsFixed(1)}% ',
                                      style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 12),
                                    ),
                                    Text(
                                      Formatters.currency(c.totalAmount, symbol: themeProvider.currencySymbol),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
