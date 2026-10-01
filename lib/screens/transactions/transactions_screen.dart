import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/export_helper.dart';
import '../../core/utils/formatters.dart';
import '../../models/report_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/category_icon_helper.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/hover_lift_card.dart';
import '../../widgets/month_year_picker_popup.dart';
import 'add_edit_transaction_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final txProvider = Provider.of<TransactionProvider>(context, listen: false);
      if (txProvider.transactions.isEmpty) {
        txProvider.fetchTransactions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTransactionSheet([TransactionModel? tx]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTransactionSheet(transactionToEdit: tx),
    );
  }

  void _showExportModal(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    DateTime exportDate = DateTime.now();
    String exportPeriodType = 'monthly';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filteredTxs = txProvider.transactions.where((tx) {
              if (exportPeriodType == 'monthly') {
                return tx.transactionDate.year == exportDate.year &&
                    tx.transactionDate.month == exportDate.month;
              } else {
                return tx.transactionDate.year == exportDate.year;
              }
            }).toList();

            double income = 0.0;
            double expense = 0.0;
            final Map<int, CategorySpendingSummary> catMap = {};

            for (final tx in filteredTxs) {
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

            final report = FinancialReportModel(
              periodType: exportPeriodType,
              periodValue: exportPeriodType == 'monthly'
                  ? '${exportDate.year}-${exportDate.month}'
                  : '${exportDate.year}',
              totalIncome: income,
              totalExpense: expense,
              netSavings: income - expense,
              savingsRate: income > 0 ? (((income - expense) / income) * 100).clamp(0.0, 100.0) : 0.0,
              categoryBreakdowns: catList,
              cashflows: [],
            );

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
                              'Export PDF statement or CSV for any month',
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
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
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
                                '${DateFormat('MMMM yyyy').format(exportDate)} Statement',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
                    ),
                    const SizedBox(height: 16),
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
                        'Download PDF (${DateFormat('MMM yyyy').format(exportDate)})',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      subtitle: const Text('Complete financial PDF statement', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ExportHelper.exportPdfReport(
                          report: report,
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
                      title: const Text('Export CSV Spreadsheet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      subtitle: Text('${filteredTxs.length} transactions for ${DateFormat('MMM yyyy').format(exportDate)}', style: const TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ExportHelper.exportCsvReport(
                          filteredTxs,
                          themeProvider.currencySymbol,
                          ExportHelper.getStatementTitle(report),
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

    final filteredList = txProvider.filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, size: 22),
            tooltip: 'Export Statement',
            onPressed: () => _showExportModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => txProvider.fetchTransactions(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTransactionSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => txProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search transactions, note, category...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              txProvider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip('all', 'All', txProvider),
                    const SizedBox(width: 8),
                    _buildFilterChip('income', 'Income', txProvider, AppColors.income),
                    const SizedBox(width: 8),
                    _buildFilterChip('expense', 'Expenses', txProvider, AppColors.expense),
                  ],
                ),
              ],
            ),
          ),
          // Transactions List
          Expanded(
            child: txProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? EmptyStateView(
                        title: 'No Transactions Found',
                        description: 'Try modifying your search filter or add a new transaction.',
                        buttonText: 'Add First Record',
                        onButtonPressed: () => _openAddTransactionSheet(),
                      )
                    : RefreshIndicator(
                        onRefresh: () => txProvider.fetchTransactions(),
                        child: ListView.separated(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 90, top: 8),
                          itemCount: filteredList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final tx = filteredList[index];
                            final isIncome = tx.type.toLowerCase() == 'income';
                            final catColor = CategoryIconHelper.parseColor(tx.categoryColor);

                            return Dismissible(
                              key: ValueKey('tx_${tx.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.expense,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Transaction'),
                                    content: Text('Delete "${tx.description}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) {
                                txProvider.deleteTransaction(tx.id);
                              },
                                child: HoverLiftCard(
                                  liftOffset: -3,
                                  borderRadius: 18,
                                  glowColor: catColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                  onTap: () => _openAddTransactionSheet(tx),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          CategoryIconHelper.getIcon(tx.categoryIcon),
                                          color: catColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tx.description,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${tx.categoryName} • ${Formatters.dateShort(tx.transactionDate)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${isIncome ? '+' : '-'}${Formatters.currency(tx.amount, symbol: themeProvider.currencySymbol)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: isIncome ? const Color(0xFF059669) : const Color(0xFFE11D48),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () => _openAddTransactionSheet(tx),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(3),
                                                  child: Icon(Icons.edit_rounded, size: 15, color: isDark ? Colors.white60 : const Color(0xFF6366F1)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: const Text('Delete Transaction', style: TextStyle(fontWeight: FontWeight.w800)),
                                                      content: Text('Are you sure you want to delete "${tx.description}"?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(ctx, false),
                                                          child: const Text('Cancel'),
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBE123C)),
                                                          onPressed: () => Navigator.pop(ctx, true),
                                                          child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirm == true) {
                                                    await txProvider.deleteTransaction(tx.id);
                                                  }
                                                },
                                                borderRadius: BorderRadius.circular(6),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(3),
                                                  child: Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFE11D48)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label, TransactionProvider provider, [Color? activeColor]) {
    final isSelected = provider.filterType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activeColor ?? const Color(0xFF6366F1);

    return Expanded(
      child: HoverLiftCard(
        liftOffset: -2,
        borderRadius: 14,
        glowColor: color,
        onTap: () => provider.setFilterType(type),
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: isSelected ? color : (isDark ? const Color(0xFF1E293B) : Colors.white),
        border: Border.all(
          color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1.0,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
