import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'budgets/budgets_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'goals/goals_screen.dart';
import 'profile/profile_screen.dart';
import 'reports/reports_screen.dart';
import 'transactions/transactions_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      DashboardScreen(onNavigateTab: _onTabSelected),
      const TransactionsScreen(),
      const BudgetsScreen(),
      const GoalsScreen(),
      const ReportsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedItemColor: AppColors.primaryLight,
              unselectedItemColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined, size: 20),
                  activeIcon: Icon(Icons.dashboard_rounded, size: 22, color: AppColors.primaryLight),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.swap_horiz_rounded, size: 20),
                  activeIcon: Icon(Icons.swap_horiz_rounded, size: 22, color: AppColors.primaryLight),
                  label: 'Activity',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.pie_chart_outline_rounded, size: 20),
                  activeIcon: Icon(Icons.pie_chart_rounded, size: 22, color: AppColors.primaryLight),
                  label: 'Budgets',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.track_changes_rounded, size: 20),
                  activeIcon: Icon(Icons.track_changes_rounded, size: 22, color: AppColors.primaryLight),
                  label: 'Goals',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded, size: 20),
                  activeIcon: Icon(Icons.bar_chart_rounded, size: 22, color: AppColors.primaryLight),
                  label: 'Analytics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded, size: 20),
                  activeIcon: Icon(Icons.person_rounded, size: 22, color: AppColors.primaryLight),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
