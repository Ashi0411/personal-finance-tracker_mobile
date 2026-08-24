import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/category_icon_helper.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/user_avatar.dart';
import '../budgets/add_edit_budget_dialog.dart';
import '../goals/add_goal_dialog.dart';
import '../profile/server_settings_screen.dart';
import '../transactions/add_edit_transaction_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);

    await Future.wait([
      txProvider.fetchCategories(),
      txProvider.fetchTransactions(),
      budgetProvider.fetchBudgets(),
      goalProvider.fetchGoals(),
    ]);
  }

  void _openAddTransactionSheet([String type = 'expense']) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddEditTransactionSheet(
        transactionToEdit: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);
    final goalProvider = Provider.of<GoalProvider>(context);

    final user = authProvider.currentUser;
    final totalIncome = txProvider.totalIncome;
    final totalExpense = txProvider.totalExpense;
    final netBalance = txProvider.netBalance;
    final recentTx = txProvider.recentTransactions;
    final totalSavings = goalProvider.totalSavedAmount;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllData,
          child: ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
            children: [
              // Top Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(5); // Switch to profile tab
                          }
                        },
                        child: UserAvatar(
                          name: user?.fullName ?? 'User',
                          avatarUrl: user?.avatarUrl,
                          size: 46,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.fullName.split(' ').first ?? 'User'} 👋',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Here is your financial overview',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 4-Tier Hero Balance Card
              HeroBalanceCard(
                balance: netBalance,
                income: totalIncome,
                expense: totalExpense,
                currency: themeProvider.currencySymbol,
              ),
              const SizedBox(height: 20),
              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.south_west_rounded,
                      label: 'Add Income',
                      color: AppColors.income,
                      onTap: () => _openAddTransactionSheet('income'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.north_east_rounded,
                      label: 'Add Expense',
                      color: AppColors.expense,
                      onTap: () => _openAddTransactionSheet('expense'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.track_changes_rounded,
                      label: 'New Goal',
                      color: AppColors.savings,
                      onTap: () => showDialog(context: context, builder: (_) => const AddGoalDialog()),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.pie_chart_outline_rounded,
                      label: 'Set Budget',
                      color: AppColors.primary,
                      onTap: () => showDialog(context: context, builder: (_) => const AddEditBudgetDialog()),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Mini Stat Cards (Savings & Net Margin)
              Row(
                children: [
                  Expanded(
                    child: MiniStatCard(
                      title: 'Total Savings',
                      amount: totalSavings,
                      currency: themeProvider.currencySymbol,
                      icon: Icons.savings_rounded,
                      color: AppColors.savings,
                      bgColor: AppColors.savings.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MiniStatCard(
                      title: 'Savings Rate',
                      amount: totalIncome > 0 ? ((netBalance / totalIncome) * 100).clamp(0.0, 100.0) : 0.0,
                      currency: '% ',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.accent,
                      bgColor: AppColors.accent.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Recent Transactions Header & List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (widget.onNavigateTab != null) {
                        widget.onNavigateTab!(1);
                      }
                    },
                    child: const Text('View All', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (recentTx.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Text('No transactions logged yet. Tap Add Expense to start!'),
                )
              else
                ...recentTx.map((tx) {
                  final isIncome = tx.type.toLowerCase() == 'income';
                  final catColor = CategoryIconHelper.parseColor(tx.categoryColor);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            CategoryIconHelper.getIcon(tx.categoryIcon),
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
                                tx.description,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${tx.categoryName} • ${Formatters.dateShort(tx.transactionDate)}',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isIncome ? '+' : '-'}${Formatters.currency(tx.amount, symbol: themeProvider.currencySymbol)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isIncome ? AppColors.income : AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
