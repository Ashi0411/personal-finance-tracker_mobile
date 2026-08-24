import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/budget_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/category_icon_helper.dart';
import '../../widgets/empty_state_view.dart';
import 'add_edit_budget_dialog.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      if (budgetProvider.budgets.isEmpty) {
        budgetProvider.fetchBudgets();
      }
    });
  }

  void _openBudgetDialog([BudgetModel? budget]) {
    showDialog(
      context: context,
      builder: (_) => AddEditBudgetDialog(budgetToEdit: budget),
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

    final budgets = budgetProvider.budgets;
    final totalAllocated = budgetProvider.totalAllocated;
    final totalSpent = budgetProvider.totalSpent;
    final overallPct = budgetProvider.overallPercentage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Limits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => budgetProvider.fetchBudgets(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBudgetDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Budget', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: budgetProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => budgetProvider.fetchBudgets(),
              child: ListView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 90),
                children: [
                  // Overall Budget Overview Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Monthly Budget Overview',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${overallPct.toStringAsFixed(1)}% Used',
                                style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (overallPct / 100).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              overallPct >= 100
                                  ? AppColors.expense
                                  : (overallPct >= 75 ? AppColors.warning : AppColors.income),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Spent', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.currency(totalSpent, symbol: themeProvider.currencySymbol),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Total Budget', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.currency(totalAllocated, symbol: themeProvider.currencySymbol),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ],
                            ),
                          ],
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
                      title: 'No Budgets Configured',
                      description: 'Set category spending limits to keep your monthly expenses in check.',
                      buttonText: 'Create First Budget',
                      onButtonPressed: () => _openBudgetDialog(),
                    )
                  else
                    ...budgets.map((b) {
                      final statusColor = _getStatusColor(b.status);
                      final catColor = CategoryIconHelper.parseColor(b.categoryColor);
                      final progress = (b.percentageSpent / 100).clamp(0.0, 1.0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
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
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          fontSize: 12,
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
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _openBudgetDialog(b);
                                    } else if (val == 'delete') {
                                      budgetProvider.deleteBudget(b.id);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit Limit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete Budget')),
                                  ],
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
