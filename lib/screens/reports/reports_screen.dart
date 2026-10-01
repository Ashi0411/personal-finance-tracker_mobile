import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../core/utils/export_helper.dart';
import '../../core/utils/formatters.dart';
import '../../models/report_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/category_icon_helper.dart';
import '../../widgets/hover_lift_card.dart';
import '../../widgets/month_year_picker_bar.dart';
import '../../widgets/month_year_picker_popup.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _touchedIndex = -1;
  DateTime _selectedDate = DateTime.now();
  String _periodType = 'monthly'; // 'monthly' or 'yearly'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final txProvider = Provider.of<TransactionProvider>(context, listen: false);
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      if (txProvider.transactions.isEmpty) {
        await txProvider.fetchTransactions();
      }
      reportProvider.setPeriodType(_periodType, fallbackTransactions: txProvider.transactions);
      reportProvider.setYear(_selectedDate.year, fallbackTransactions: txProvider.transactions);
      reportProvider.setMonth(_selectedDate.month, fallbackTransactions: txProvider.transactions);
      reportProvider.fetchReport(fallbackTransactions: txProvider.transactions);
    });
  }

  FinancialReportModel _computeReportFor(
    List<TransactionModel> transactions,
    DateTime date,
    String periodType,
  ) {
    final filtered = transactions.where((tx) {
      if (periodType == 'monthly') {
        return tx.transactionDate.year == date.year &&
            tx.transactionDate.month == date.month;
      } else {
        return tx.transactionDate.year == date.year;
      }
    }).toList();

    double income = 0.0;
    double expense = 0.0;
    final Map<int, CategorySpendingSummary> catMap = {};

    for (final tx in filtered) {
      if (tx.type.toLowerCase() == 'income') {
        income += tx.amount;
      } else {
        expense += tx.amount;
        if (catMap.containsKey(tx.categoryId)) {
          final existing = catMap[tx.categoryId]!;
          catMap[tx.categoryId] = CategorySpendingSummary(
            categoryName: existing.categoryName,
            totalAmount: existing.totalAmount + tx.amount,
            percentage: 0.0,
            color: existing.color,
            icon: existing.icon,
          );
        } else {
          catMap[tx.categoryId] = CategorySpendingSummary(
            categoryName: tx.categoryName,
            totalAmount: tx.amount,
            percentage: 0.0,
            color: tx.categoryColor,
            icon: tx.categoryIcon,
          );
        }
      }
    }

    final catList = catMap.values.map((cat) {
      final pct = expense > 0 ? (cat.totalAmount / expense) * 100 : 0.0;
      return CategorySpendingSummary(
        categoryName: cat.categoryName,
        totalAmount: cat.totalAmount,
        percentage: pct,
        color: cat.color,
        icon: cat.icon,
      );
    }).toList();

    // Generate 12 months of cashflow for the selected year
    final List<MonthlyCashflowSummary> cashflows = [];
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (int m = 1; m <= 12; m++) {
      double mIncome = 0;
      double mExpense = 0;
      for (final tx in transactions) {
        if (tx.transactionDate.year == date.year && tx.transactionDate.month == m) {
          if (tx.type.toLowerCase() == 'income') {
            mIncome += tx.amount;
          } else {
            mExpense += tx.amount;
          }
        }
      }
      cashflows.add(MonthlyCashflowSummary(
        month: monthNames[m - 1],
        income: mIncome,
        expense: mExpense,
      ));
    }

    return FinancialReportModel(
      periodType: periodType,
      periodValue: periodType == 'monthly'
          ? '${date.year}-${date.month}'
          : '${date.year}',
      totalIncome: income,
      totalExpense: expense,
      netSavings: income - expense,
      savingsRate: income > 0 ? (((income - expense) / income) * 100).clamp(0.0, 100.0) : 0.0,
      categoryBreakdowns: catList,
      cashflows: cashflows,
    );
  }

  FinancialReportModel _computeLiveReport(List<TransactionModel> transactions) {
    return _computeReportFor(transactions, _selectedDate, _periodType);
  }

  void _showExportOptions(BuildContext context, [FinancialReportModel? initialReport]) {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    DateTime exportDate = _selectedDate;
    String exportPeriodType = _periodType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            // Compute live report for whatever month/year is selected in this modal
            final currentReport = _computeReportFor(txProvider.transactions, exportDate, exportPeriodType);
            final filteredTxs = txProvider.transactions.where((tx) {
              if (exportPeriodType == 'monthly') {
                return tx.transactionDate.year == exportDate.year &&
                    tx.transactionDate.month == exportDate.month;
              } else {
                return tx.transactionDate.year == exportDate.year;
              }
            }).toList();

            final now = DateTime.now();
            final recentMonths = List.generate(6, (index) {
              return DateTime(now.year, now.month - index, 1);
            });

            return Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title & Description
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Export Financial Statement',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Choose any month or year to download statement',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Period Type Switcher (Monthly vs Annual)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() => exportPeriodType = 'monthly');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: exportPeriodType == 'monthly'
                                      ? const Color(0xFF6366F1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 15,
                                      color: exportPeriodType == 'monthly'
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Monthly Statement',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: exportPeriodType == 'monthly'
                                            ? Colors.white
                                            : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() => exportPeriodType = 'yearly');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: exportPeriodType == 'yearly'
                                      ? const Color(0xFF6366F1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bar_chart_rounded,
                                      size: 15,
                                      color: exportPeriodType == 'yearly'
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Full Year Overview',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: exportPeriodType == 'yearly'
                                            ? Colors.white
                                            : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Month Selection Chips (For Monthly mode)
                    if (exportPeriodType == 'monthly') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Month',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final picked = await MonthYearPickerPopup.show(ctx, exportDate);
                              if (picked != null) {
                                setModalState(() => exportDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.edit_calendar_rounded, size: 14, color: Color(0xFF6366F1)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Other Months...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: recentMonths.map((mDate) {
                            final isCurrentSelected = exportDate.year == mDate.year && exportDate.month == mDate.month;
                            final isThisMonth = now.year == mDate.year && now.month == mDate.month;
                            final monthLabel = DateFormat('MMM yyyy').format(mDate);

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  isThisMonth ? '$monthLabel (Current)' : monthLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isCurrentSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isCurrentSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                  ),
                                ),
                                selected: isCurrentSelected,
                                selectedColor: const Color(0xFF6366F1),
                                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isCurrentSelected
                                        ? Colors.transparent
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setModalState(() => exportDate = mDate);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ] else ...[
                      // Year Selection Chips (For Yearly mode)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Year',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [now.year, now.year - 1, now.year - 2].map((yr) {
                          final isCurrentSelected = exportDate.year == yr;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(
                                'Year $yr',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isCurrentSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isCurrentSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                ),
                              ),
                              selected: isCurrentSelected,
                              selectedColor: const Color(0xFF6366F1),
                              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isCurrentSelected
                                      ? Colors.transparent
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              onSelected: (sel) {
                                if (sel) {
                                  setModalState(() => exportDate = DateTime(yr, exportDate.month, 1));
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Statement Live Preview Summary Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      color: Color(0xFF6366F1),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    exportPeriodType == 'monthly'
                                        ? '${DateFormat('MMMM yyyy').format(exportDate)} Statement'
                                        : 'Full Year ${exportDate.year} Statement',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: filteredTxs.isNotEmpty
                                      ? AppColors.income.withValues(alpha: 0.15)
                                      : Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${filteredTxs.length} records',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: filteredTxs.isNotEmpty ? AppColors.income : Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Income',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    Formatters.currency(currentReport.totalIncome, symbol: themeProvider.currencySymbol),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.income,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Total Expense',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    Formatters.currency(currentReport.totalExpense, symbol: themeProvider.currencySymbol),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.expense,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Net Savings',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    Formatters.currency(currentReport.netSavings, symbol: themeProvider.currencySymbol),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: currentReport.netSavings >= 0 ? const Color(0xFF6366F1) : AppColors.expense,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Download Action Buttons
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.expense, size: 22),
                      ),
                      title: Text(
                        'Download PDF Statement (${exportPeriodType == 'monthly' ? DateFormat('MMM yyyy').format(exportDate) : exportDate.year})',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      subtitle: const Text('Executive formatted PDF report with tables, graphs & KPIs', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () async {
                        Navigator.pop(ctx);
                        // Also update main screen to this date if user chose a different date
                        if (mounted) {
                          setState(() {
                            _selectedDate = exportDate;
                            _periodType = exportPeriodType;
                          });
                        }
                        await ExportHelper.exportPdfReport(
                          report: currentReport,
                          transactions: txProvider.transactions,
                          user: authProvider.currentUser,
                          currencySymbol: themeProvider.currencySymbol,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.income.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.table_chart_rounded, color: AppColors.income, size: 22),
                      ),
                      title: Text(
                        'Export CSV (Excel / Sheets)',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      subtitle: Text(
                        'Spreadsheet file with ${filteredTxs.length} transactions for ${exportPeriodType == 'monthly' ? DateFormat('MMM yyyy').format(exportDate) : exportDate.year}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ExportHelper.exportCsvReport(
                          filteredTxs,
                          themeProvider.currencySymbol,
                          ExportHelper.getStatementTitle(currentReport),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    // Compute realtime financial report based on active period and selected date
    final report = _computeLiveReport(txProvider.transactions);
    final categories = report.categoryBreakdowns;
    final cashflows = report.cashflows;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset('assets/images/logo.png', height: 22, width: 22, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.tr('financial_analytics'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, size: 22),
            tooltip: context.tr('export_statement'),
            onPressed: () => _showExportOptions(context, report),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => txProvider.fetchTransactions(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 90),
        children: [
          // Header Logo Banner for Monthly & Annual Statements
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Image.asset('assets/images/logo.png', height: 24, width: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _periodType == 'monthly'
                            ? '${context.tr('monthly_report')} (${DateFormat('MMMM yyyy').format(_selectedDate)})'
                            : '${context.tr('annual_overview')} (${_selectedDate.year})',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'FinanceTracker Verified Statement',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Quick Export Banner Button
          HoverLiftCard(
            liftOffset: -3,
            borderRadius: 18,
            glowColor: const Color(0xFF6366F1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFC7D2FE)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF6366F1), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('export_statement'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                        ),
                      ),
                      Text(
                        context.tr('export_subtitle'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showExportOptions(context, report),
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const Text('Export', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Period Selector Bar & Toggle Container
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _periodType == 'monthly' ? context.tr('monthly_report') : context.tr('annual_overview'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: MonthYearPickerBar(
                        selectedDate: _selectedDate,
                        isDark: isDark,
                        primaryColor: const Color(0xFF6366F1),
                        isYearOnly: _periodType == 'yearly',
                        onDateChanged: (newDate) {
                          setState(() => _selectedDate = newDate);
                        },
                      ),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _periodType == 'monthly' ? context.tr('monthly_report') : context.tr('annual_overview'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  MonthYearPickerBar(
                    selectedDate: _selectedDate,
                    isDark: isDark,
                    primaryColor: const Color(0xFF6366F1),
                    isYearOnly: _periodType == 'yearly',
                    onDateChanged: (newDate) {
                      setState(() => _selectedDate = newDate);
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

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
                    onTap: () => setState(() => _periodType = 'monthly'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _periodType == 'monthly' ? const Color(0xFF6366F1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Monthly Report',
                        style: TextStyle(
                          color: _periodType == 'monthly' ? Colors.white : (isDark ? Colors.white70 : AppColors.lightTextPrimary),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _periodType = 'yearly'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _periodType == 'yearly' ? const Color(0xFF6366F1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Annual Report',
                        style: TextStyle(
                          color: _periodType == 'yearly' ? Colors.white : (isDark ? Colors.white70 : AppColors.lightTextPrimary),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4-Tier Financial Summary Card
          HoverLiftCard(
            liftOffset: -3,
            padding: const EdgeInsets.all(20),
            borderRadius: 24,
            glowColor: const Color(0xFF6366F1),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _periodType == 'monthly' ? context.tr('monthly_income') : context.tr('annual_income'),
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              Formatters.currency(report.totalIncome, symbol: themeProvider.currencySymbol),
                              style: const TextStyle(
                                color: AppColors.income,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _periodType == 'monthly' ? context.tr('monthly_expenses') : context.tr('annual_expenses'),
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            alignment: Alignment.centerRight,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              Formatters.currency(report.totalExpense, symbol: themeProvider.currencySymbol),
                              style: const TextStyle(
                                color: AppColors.expense,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('net_savings'),
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              Formatters.currency(report.netSavings, symbol: themeProvider.currencySymbol),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: report.netSavings >= 0 ? const Color(0xFF6366F1) : AppColors.expense,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Savings Rate',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            alignment: Alignment.centerRight,
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${report.savingsRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cash Flow Trend Title
          Text(
            'Cash Flow Trend (${_selectedDate.year})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Cash Flow Trend Bar Chart
          HoverLiftCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 20,
            glowColor: AppColors.income,
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: SizedBox(
              height: 200,
              child: cashflows.every((cf) => cf.income == 0 && cf.expense == 0)
                  ? const Center(child: Text('No cash flow records logged yet for this year.'))
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
                                '${cf.month} ${_selectedDate.year}\n${isIncomeRod ? 'Income: ' : 'Expense: '}${Formatters.currency(rod.toY, symbol: themeProvider.currencySymbol)}',
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
                                  final isCurrentMonth = _periodType == 'monthly' && (_selectedDate.month - 1 == index);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      cashflows[index].month,
                                      style: TextStyle(
                                        color: isCurrentMonth
                                            ? const Color(0xFF6366F1)
                                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                        fontSize: 11,
                                        fontWeight: isCurrentMonth ? FontWeight.w900 : FontWeight.w600,
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
                                width: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              BarChartRodData(
                                toY: cf.expense,
                                color: AppColors.expense,
                                width: 8,
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
            _periodType == 'monthly'
                ? 'Spending by Category (${DateFormat('MMMM yyyy').format(_selectedDate)})'
                : 'Spending by Category (${_selectedDate.year})',
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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _periodType == 'monthly'
                            ? 'No expenses recorded in ${DateFormat('MMMM yyyy').format(_selectedDate)}.'
                            : 'No expenses recorded in ${_selectedDate.year}.',
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  )
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
                            sectionsSpace: 4,
                            centerSpaceRadius: 46,
                            sections: categories.asMap().entries.map((entry) {
                              final index = entry.key;
                              final cat = entry.value;
                              final isTouched = index == _touchedIndex;
                              final radius = isTouched ? 48.0 : 38.0;
                              final color = CategoryIconHelper.parseColor(cat.color);

                              return PieChartSectionData(
                                color: color,
                                value: cat.totalAmount,
                                title: '${cat.percentage.toStringAsFixed(0)}%',
                                radius: radius,
                                titleStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Breakdown list items with icons & percentages
                      ...categories.map((c) {
                        final color = CategoryIconHelper.parseColor(c.color);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  CategoryIconHelper.getIcon(c.icon),
                                  size: 16,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.categoryName,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${c.percentage.toStringAsFixed(1)}% of total expenses',
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Formatters.currency(c.totalAmount, symbol: themeProvider.currencySymbol),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
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
}
