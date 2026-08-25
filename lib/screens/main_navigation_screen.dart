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

    final navItems = [
      _NavData(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Home'),
      _NavData(icon: Icons.swap_horiz_rounded, activeIcon: Icons.swap_horiz_rounded, label: 'Activity'),
      _NavData(icon: Icons.pie_chart_outline_rounded, activeIcon: Icons.pie_chart_rounded, label: 'Budgets'),
      _NavData(icon: Icons.track_changes_rounded, activeIcon: Icons.track_changes_rounded, label: 'Goals'),
      _NavData(icon: Icons.bar_chart_rounded, activeIcon: Icons.bar_chart_rounded, label: 'Analytics'),
      _NavData(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.07),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isSelected = _currentIndex == index;

                return Expanded(
                  child: _BottomNavItem(
                    item: item,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () => _onTabSelected(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _BottomNavItem extends StatelessWidget {
  final _NavData item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);
    final activeBg = isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEDE9FE);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with pill container only when selected
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: isSelected ? 21 : 19,
                  color: isSelected
                      ? primaryColor
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 4),
              // Label Text
              Text(
                item.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? primaryColor
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
