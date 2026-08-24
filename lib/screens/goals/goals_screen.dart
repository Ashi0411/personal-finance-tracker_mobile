import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/category_icon_helper.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/hover_lift_card.dart';
import 'add_goal_dialog.dart';
import 'quick_deposit_dialog.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);
      if (goalProvider.goals.isEmpty) {
        goalProvider.fetchGoals();
      }
    });
  }

  void _openAddGoalDialog() {
    showDialog(context: context, builder: (_) => const AddGoalDialog());
  }

  void _openDepositDialog(GoalModel goal) {
    showDialog(context: context, builder: (_) => QuickDepositDialog(goal: goal));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final goalProvider = Provider.of<GoalProvider>(context);

    final goals = goalProvider.goals;
    final totalTarget = goalProvider.totalTargetAmount;
    final totalSaved = goalProvider.totalSavedAmount;
    final overallProg = goalProvider.overallProgress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => goalProvider.fetchGoals(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddGoalDialog,
        backgroundColor: AppColors.savings,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: goalProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => goalProvider.fetchGoals(),
              child: ListView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 90),
                children: [
                  // Overall Savings Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Savings Progress',
                              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${overallProg.toStringAsFixed(1)}% Achieved',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          Formatters.currency(totalSaved, symbol: themeProvider.currencySymbol),
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target: ${Formatters.currency(totalTarget, symbol: themeProvider.currencySymbol)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (overallProg / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white24,
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
                        'Active Milestones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${goals.length} Goals',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (goals.isEmpty)
                    EmptyStateView(
                      title: 'No Savings Goals Yet',
                      description: 'Create a savings goal for your vacation, emergency fund, or gadget.',
                      buttonText: 'Add First Goal',
                      onButtonPressed: _openAddGoalDialog,
                    )
                  else
                    ...goals.map((g) {
                      final goalColor = CategoryIconHelper.parseColor(g.color);
                      final isComplete = g.isCompleted || g.progressPercentage >= 100;

                      return HoverLiftCard(
                        liftOffset: -3,
                        borderRadius: 20,
                        glowColor: goalColor,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: goalColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    CategoryIconHelper.getIcon(g.icon),
                                    color: goalColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              g.name,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                            ),
                                          ),
                                          if (isComplete)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.income.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'COMPLETED',
                                                style: TextStyle(color: AppColors.income, fontSize: 10, fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Target: ${Formatters.date(g.targetDate)} (${g.daysRemaining} days left)',
                                        style: TextStyle(
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  onPressed: () => goalProvider.deleteGoal(g.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Saved so far',
                                      style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 11),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Formatters.currency(g.currentAmount, symbol: themeProvider.currencySymbol),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Target Goal',
                                      style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 11),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Formatters.currency(g.targetAmount, symbol: themeProvider.currencySymbol),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (g.progressPercentage / 100).clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                                valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _openDepositDialog(g),
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                label: const Text('Add Deposit / Contribution', style: TextStyle(fontWeight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: goalColor.withValues(alpha: 0.5)),
                                  foregroundColor: goalColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
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
