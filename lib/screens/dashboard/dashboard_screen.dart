import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/category_icon_helper.dart';
import '../../widgets/category_management_dialog.dart';
import '../../widgets/hover_lift_card.dart';
import '../../widgets/interactive_overview_card.dart';
import '../../widgets/month_year_picker_popup.dart';
import '../../widgets/user_avatar.dart';
import '../auth/login_screen.dart';
import '../transactions/add_edit_transaction_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    await txProvider.fetchCategories();
    await txProvider.fetchTransactions();
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset, 1);
    });
  }

  void _changeYear(int offset) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year + offset, _selectedDate.month, 1);
    });
  }

  Future<void> _pickCustomMonth() async {
    final picked = await MonthYearPickerPopup.show(context, _selectedDate);
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _openAddTransactionSheet([String type = 'expense']) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddEditTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);
    final user = authProvider.currentUser;

    // Filter transactions for the selected Year & Month
    final monthTransactions = txProvider.transactions.where((tx) {
      return tx.transactionDate.year == _selectedDate.year &&
          tx.transactionDate.month == _selectedDate.month;
    }).toList();

    final incomeTransactions = monthTransactions.where((tx) => tx.type.toLowerCase() == 'income').toList();
    final expenseTransactions = monthTransactions.where((tx) => tx.type.toLowerCase() == 'expense').toList();

    // Calculations
    final monthlyIncome = incomeTransactions.fold(0.0, (sum, tx) => sum + tx.amount);
    final monthlyExpenses = expenseTransactions.fold(0.0, (sum, tx) => sum + tx.amount);
    final monthlyNetSavings = monthlyIncome - monthlyExpenses;

    // Category Breakdowns for Doughnut Charts
    final expenseCatMap = <String, double>{};
    final incomeCatMap = <String, double>{};

    for (final tx in monthTransactions) {
      if (tx.type.toLowerCase() == 'expense') {
        expenseCatMap[tx.categoryName] = (expenseCatMap[tx.categoryName] ?? 0.0) + tx.amount;
      } else {
        incomeCatMap[tx.categoryName] = (incomeCatMap[tx.categoryName] ?? 0.0) + tx.amount;
      }
    }

    final currency = themeProvider.currencySymbol;
    final monthName = DateFormat('MMMM yyyy').format(_selectedDate);

    return Scaffold(
      drawer: AppDrawer(onSelectTab: widget.onNavigateTab),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Header Bar
              _buildTopHeader(context, isDark, user),

              // Main Scrollable Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      // Monthly Overview Main Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Left Title and Right Period Switcher on Same Row
                            _buildPeriodSelector(isDark, monthName),
                            const SizedBox(height: 22),

                            // Row 1: Monthly Income
                            InteractiveOverviewCard(
                              title: 'Monthly Income',
                              amount: monthlyIncome,
                              currency: currency,
                              emoji: '💰',
                              icon: Icons.trending_up_rounded,
                              primaryColor: const Color(0xFF0284C7),
                              bgColor: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.3) : const Color(0xFFE0F2FE),
                              borderColor: isDark ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD),
                              transactions: incomeTransactions,
                              monthName: monthName,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),

                            // Row 2: Monthly Expenses
                            InteractiveOverviewCard(
                              title: 'Monthly Expenses',
                              amount: monthlyExpenses,
                              currency: currency,
                              emoji: '💸',
                              icon: Icons.trending_down_rounded,
                              primaryColor: const Color(0xFFBE123C),
                              bgColor: isDark ? const Color(0xFF881337).withValues(alpha: 0.3) : const Color(0xFFFFF1F2),
                              borderColor: isDark ? const Color(0xFFE11D48) : const Color(0xFFFDA4AF),
                              transactions: expenseTransactions,
                              monthName: monthName,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),

                            // Row 3: Monthly Net Savings
                            InteractiveOverviewCard(
                              title: 'Monthly Net Savings',
                              amount: monthlyNetSavings,
                              currency: currency,
                              emoji: '💎',
                              icon: Icons.account_balance_wallet_rounded,
                              primaryColor: const Color(0xFF4338CA),
                              bgColor: isDark ? const Color(0xFF312E81).withValues(alpha: 0.3) : const Color(0xFFEDE9FE),
                              borderColor: isDark ? const Color(0xFF6366F1) : const Color(0xFFDDD6FE),
                              transactions: monthTransactions,
                              monthName: monthName,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Income by Category Doughnut Chart Card (On Top)
                      _buildCategoryDoughnutCard(
                        title: 'Income by Category',
                        icon: Icons.pie_chart_rounded,
                        iconColor: const Color(0xFF0284C7),
                        categoryMap: incomeCatMap,
                        totalAmount: monthlyIncome,
                        currency: currency,
                        isDark: isDark,
                        isExpense: false,
                      ),
                      const SizedBox(height: 20),

                      // Expense by Category Doughnut Chart Card (Below)
                      _buildCategoryDoughnutCard(
                        title: 'Expense by Category',
                        icon: Icons.pie_chart_rounded,
                        iconColor: const Color(0xFFF43F5E),
                        categoryMap: expenseCatMap,
                        totalAmount: monthlyExpenses,
                        currency: currency,
                        isDark: isDark,
                        isExpense: true,
                      ),
                      const SizedBox(height: 20),

                      // Overall Cash Flow Bar Chart Card
                      _buildCashFlowCard(txProvider.transactions, isDark, currency),
                      const SizedBox(height: 20),

                      // Quick Actions Section (Left: + Add Category, Right: + Add Transaction)
                      _buildQuickActionButtons(context, isDark),
                      const SizedBox(height: 20),

                      // Recent Activities List for this Month
                      _buildRecentActivitiesCard(monthTransactions, isDark, currency, txProvider),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isDark, dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF312E81)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          // Hamburger Menu Button
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
              tooltip: 'Open Menu',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const SizedBox(width: 6),
          // Logo & Subtitle
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFD946EF)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'FinanceTracker',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Personal Finance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Profile Chip
          GestureDetector(
            onTap: () {
              if (widget.onNavigateTab != null) {
                widget.onNavigateTab!(5);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    name: user?.fullName ?? 'User',
                    avatarUrl: user?.avatarUrl,
                    size: 26,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user?.fullName?.split(' ').first ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Logout Icon
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
            tooltip: 'Sign Out',
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark, String monthName) {
    final titleWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text('💎 ', style: TextStyle(fontSize: 18)),
        Icon(Icons.pie_chart_rounded, color: Color(0xFF2563EB), size: 22),
        SizedBox(width: 8),
        Text(
          'Monthly Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );

    final periodSwitcher = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Double Arrow Left (-1 Year)
          _buildArrowButton(
            icon: Icons.keyboard_double_arrow_left_rounded,
            tooltip: '-1 Year',
            onTap: () => _changeYear(-1),
            isDark: isDark,
          ),
          const SizedBox(width: 2),
          // Single Arrow Left (-1 Month)
          _buildArrowButton(
            icon: Icons.chevron_left_rounded,
            tooltip: '-1 Month',
            onTap: () => _changeMonth(-1),
            isDark: isDark,
          ),
          const SizedBox(width: 4),
          // Current Selected Month Pill (Tap to open month/year picker popup)
          InkWell(
            onTap: _pickCustomMonth,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Single Arrow Right (+1 Month)
          _buildArrowButton(
            icon: Icons.chevron_right_rounded,
            tooltip: '+1 Month',
            onTap: () => _changeMonth(1),
            isDark: isDark,
          ),
          const SizedBox(width: 2),
          // Double Arrow Right (+1 Year)
          _buildArrowButton(
            icon: Icons.keyboard_double_arrow_right_rounded,
            tooltip: '+1 Year',
            onTap: () => _changeYear(1),
            isDark: isDark,
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: periodSwitcher),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            titleWidget,
            periodSwitcher,
          ],
        );
      },
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDE9FE).withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Left Button: "+ Add Category"
        Expanded(
          child: _AnimatedLightActionButton(
            label: '+ Add Category',
            icon: Icons.category_rounded,
            isDark: isDark,
            onTap: () {
              showDialog(context: context, builder: (_) => const CategoryManagementDialog());
            },
          ),
        ),
        const SizedBox(width: 14),
        // Right Button: "+ Add Transaction"
        Expanded(
          child: _AnimatedLightActionButton(
            label: '+ Add Transaction',
            icon: Icons.add_circle_rounded,
            isDark: isDark,
            onTap: () => _openAddTransactionSheet('expense'),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDoughnutCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Map<String, double> categoryMap,
    required double totalAmount,
    required String currency,
    required bool isDark,
    required bool isExpense,
  }) {
    final colorPalette = isExpense
        ? [
            const Color(0xFFF43F5E),
            const Color(0xFFEC4899),
            const Color(0xFFD946EF),
            const Color(0xFFFB7185),
            const Color(0xFFFDA4AF),
            const Color(0xFFBE123C),
          ]
        : [
            const Color(0xFF0284C7),
            const Color(0xFF0EA5E9),
            const Color(0xFF38BDF8),
            const Color(0xFF6366F1),
            const Color(0xFF06B6D4),
            const Color(0xFF0369A1),
          ];

    final entries = categoryMap.entries.toList();

    return HoverLiftCard(
      padding: const EdgeInsets.all(22),
      borderRadius: 28,
      glowColor: iconColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (entries.isEmpty || totalAmount <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'No ${isExpense ? "expenses" : "income"} recorded for this month.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else ...[
            // Doughnut Chart
            SizedBox(
              height: 190,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 48,
                  sections: entries.asMap().entries.map((item) {
                    final index = item.key;
                    final catEntry = item.value;
                    final color = colorPalette[index % colorPalette.length];
                    final pct = (catEntry.value / totalAmount) * 100;

                    return PieChartSectionData(
                      value: catEntry.value,
                      color: color,
                      radius: 36,
                      title: '${pct.toStringAsFixed(0)}%',
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
            const SizedBox(height: 18),
            // Legends
            Wrap(
              spacing: 14,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: entries.asMap().entries.map((item) {
                final index = item.key;
                final catEntry = item.value;
                final color = colorPalette[index % colorPalette.length];

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${catEntry.key} (${Formatters.currency(catEntry.value, symbol: currency)})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCashFlowCard(List<TransactionModel> allTransactions, bool isDark, String currency) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i), 1);
      return d;
    });

    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < months.length; i++) {
      final m = months[i];
      final mIncome = allTransactions
          .where((tx) => tx.type.toLowerCase() == 'income' && tx.transactionDate.year == m.year && tx.transactionDate.month == m.month)
          .fold(0.0, (s, tx) => s + tx.amount);

      final mExpense = allTransactions
          .where((tx) => tx.type.toLowerCase() == 'expense' && tx.transactionDate.year == m.year && tx.transactionDate.month == m.month)
          .fold(0.0, (s, tx) => s + tx.amount);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: mIncome, color: const Color(0xFF0284C7), width: 8, borderRadius: BorderRadius.circular(4)),
            BarChartRodData(toY: mExpense, color: const Color(0xFFE11D48), width: 8, borderRadius: BorderRadius.circular(4)),
          ],
        ),
      );
    }

    return HoverLiftCard(
      padding: const EdgeInsets.all(22),
      borderRadius: 28,
      glowColor: const Color(0xFF4F46E5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart_rounded, color: Color(0xFF4F46E5), size: 20),
              SizedBox(width: 8),
              Text(
                'Overall Cash Flow',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('MMM').format(months[idx]),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesCard(
    List<TransactionModel> monthTransactions,
    bool isDark,
    String currency,
    TransactionProvider txProvider,
  ) {
    return HoverLiftCard(
      padding: const EdgeInsets.all(22),
      borderRadius: 28,
      glowColor: const Color(0xFF6366F1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.history_rounded, color: Color(0xFF4F46E5), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Recent Activities',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              // "All Transactions" Interactive Button with 3D Hover Lift
              HoverLiftCard(
                liftOffset: -3,
                glowColor: const Color(0xFF6366F1),
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: isDark ? const Color(0xFF312E81).withValues(alpha: 0.35) : const Color(0xFFEDE9FE),
                border: Border.all(
                  color: isDark ? const Color(0xFF6366F1) : const Color(0xFFDDD6FE),
                  width: 1.2,
                ),
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(1);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'All Transactions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4F46E5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (monthTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No transactions found for this month.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...monthTransactions.take(8).map((tx) {
              final isIncome = tx.type.toLowerCase() == 'income';
              final color = CategoryIconHelper.parseColor(tx.categoryColor);

              return HoverLiftCard(
                liftOffset: -2,
                borderRadius: 16,
                glowColor: color,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CategoryIconHelper.getIcon(tx.categoryIcon),
                        color: color,
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
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Amount
                    Text(
                      '${isIncome ? '+' : '-'}${Formatters.currency(tx.amount, symbol: currency)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isIncome ? const Color(0xFF0284C7) : const Color(0xFFBE123C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Edit Button (Soft Blue/Purple)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 17, color: Color(0xFF6366F1)),
                      tooltip: 'Edit',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddEditTransactionSheet(transactionToEdit: tx),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Delete Button (Soft Rose/Red)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFBE123C)),
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
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
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AnimatedLightActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _AnimatedLightActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_AnimatedLightActionButton> createState() => _AnimatedLightActionButtonState();
}

class _AnimatedLightActionButtonState extends State<_AnimatedLightActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Soft pastel colors that transition smoothly without flashing
    final defaultBg = widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF);
    final hoveredBg = widget.isDark ? const Color(0xFF312E81).withValues(alpha: 0.4) : const Color(0xFFE0E7FF);

    final defaultBorder = widget.isDark ? const Color(0xFF334155) : const Color(0xFFC7D2FE);
    final hoveredBorder = widget.isDark ? const Color(0xFF6366F1) : const Color(0xFF818CF8);

    const primaryText = Color(0xFF4338CA);
    final darkText = const Color(0xFFC7D2FE);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: _isHovered ? hoveredBg : defaultBg,
          border: Border.all(
            color: _isHovered ? hoveredBorder : defaultBorder,
            width: _isHovered ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: _isHovered ? (widget.isDark ? 0.25 : 0.14) : 0.04),
              blurRadius: _isHovered ? 14 : 6,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: widget.isDark ? darkText : primaryText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: widget.isDark ? Colors.white : primaryText,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

