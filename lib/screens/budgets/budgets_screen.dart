import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/category_icon_helper.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/hover_lift_card.dart';
import '../../widgets/month_year_picker_bar.dart';
import 'add_edit_budget_dialog.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final txProvider = Provider.of<TransactionProvider>(context, listen: false);
      if (txProvider.transactions.isEmpty) {
        txProvider.fetchTransactions();
      }
      budgetProvider.fetchBudgets(fallbackTransactions: txProvider.transactions);
    });
  }

  void _openBudgetDialog([BudgetModel? budget]) {
    final selectedMonthYear = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
    showDialog(
      context: context,
      builder: (_) => AddEditBudgetDialog(
        budgetToEdit: budget,
        monthYear: budget?.monthYear.isNotEmpty == true ? budget!.monthYear : selectedMonthYear,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'exceeded':
        return AppColors.expense;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.income;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    final selectedMonthYear = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';

    // Strictly filter budgets for the selected month and compute real-time spent for that month
    final budgets = budgetProvider.budgets
        .where((b) => b.monthYear == selectedMonthYear)
        .map((b) {
      final catNameLower = b.categoryName.trim().toLowerCase();
      final liveSpent = txProvider.transactions
          .where((tx) =>
              tx.type.toLowerCase() == 'expense' &&
              tx.transactionDate.year == _selectedDate.year &&
              tx.transactionDate.month == _selectedDate.month &&
              (tx.categoryId == b.categoryId ||
               tx.categoryName.trim().toLowerCase() == catNameLower))
          .fold(0.0, (sum, tx) => sum + tx.amount);
      return b.copyWith(spentAmount: liveSpent);
    }).toList();

    final totalAllocated = budgets.fold(0.0, (sum, b) => sum + b.allocatedAmount);
    final totalSpent = budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
    final overallPct = totalAllocated > 0 ? ((totalSpent / totalAllocated) * 100) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('monthly_budgets')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              txProvider.fetchTransactions();
              budgetProvider.fetchBudgets(fallbackTransactions: txProvider.transactions);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBudgetDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(context.tr('add_budget'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: budgetProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await txProvider.fetchTransactions();
                await budgetProvider.fetchBudgets(fallbackTransactions: txProvider.transactions);
              },
              child: ListView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 90),
                children: [
                  // Period Selector Bar
                  Align(
                    alignment: Alignment.centerRight,
                    child: MonthYearPickerBar(
                      selectedDate: _selectedDate,
                      isDark: isDark,
                      primaryColor: const Color(0xFF10B981),
                      onDateChanged: (newDate) {
                        setState(() => _selectedDate = newDate);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Overall Budget Overview Card with 3D Elevation & Mint/Emerald Gradient
                  HoverLiftCard(
                    liftOffset: -4,
                    padding: const EdgeInsets.all(22),
                    borderRadius: 24,
                    glowColor: const Color(0xFF10B981),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('budget_overview'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${overallPct.toStringAsFixed(1)}% Used',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          Formatters.currency(totalSpent, symbol: themeProvider.currencySymbol),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Spent this month',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                            ),
                            Text(
                              'Total Budget: ${Formatters.currency(totalAllocated, symbol: themeProvider.currencySymbol)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (overallPct / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Category Limits',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${budgets.length} Categories',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (budgets.isEmpty)
                    EmptyStateView(
                      title: 'No Budgets for ${DateFormat('MMMM yyyy').format(_selectedDate)}',
                      description: 'You have not set any spending limits for ${DateFormat('MMMM yyyy').format(_selectedDate)} yet.',
                      buttonText: 'Set ${DateFormat('MMMM').format(_selectedDate)} Budget',
                      onButtonPressed: () => _openBudgetDialog(),
                    )
                  else
                    ...budgets.map((b) {
                      final statusColor = _getStatusColor(b.status);
                      final catColor = CategoryIconHelper.parseColor(b.categoryColor);
                      final progress = (b.percentageSpent / 100).clamp(0.0, 1.0);

                      return HoverLiftCard(
                        liftOffset: -3,
                        borderRadius: 18,
                        glowColor: catColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    CategoryIconHelper.getIcon(b.categoryIcon),
                                    color: catColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.categoryName,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Remaining: ${Formatters.currency(b.remainingAmount, symbol: themeProvider.currencySymbol)}',
                                        style: TextStyle(
                                          color: b.remainingAmount <= 0
                                              ? AppColors.expense
                                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                          fontSize: 12,
                                          fontWeight: b.remainingAmount <= 0 ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    b.status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Edit Button (Soft Indigo)
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF6366F1)),
                                  tooltip: 'Edit Budget',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _openBudgetDialog(b),
                                ),
                                const SizedBox(width: 6),
                                // Delete Button (Soft Rose Red)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFBE123C)),
                                  tooltip: 'Delete Budget',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Budget Limit', style: TextStyle(fontWeight: FontWeight.w800)),
                                        content: Text('Remove spending budget for "${b.categoryName}"?'),
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
                                      await budgetProvider.deleteBudget(b.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${Formatters.currency(b.spentAmount, symbol: themeProvider.currencySymbol)} spent',
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'of ${Formatters.currency(b.allocatedAmount, symbol: themeProvider.currencySymbol)} (${b.percentageSpent.toStringAsFixed(0)}%)',
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
