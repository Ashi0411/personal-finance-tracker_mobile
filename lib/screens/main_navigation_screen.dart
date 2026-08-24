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
                  child: _AnimatedBottomNavItem(
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

class _AnimatedBottomNavItem extends StatefulWidget {
  final _NavData item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _AnimatedBottomNavItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AnimatedBottomNavItem> createState() => _AnimatedBottomNavItemState();
}

class _AnimatedBottomNavItemState extends State<_AnimatedBottomNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6366F1);
    final isSelected = widget.isSelected;
    final isDark = widget.isDark;

    // Smooth, gentle color tones
    final activeBg = isDark ? const Color(0xFF312E81).withValues(alpha: 0.5) : const Color(0xFFEDE9FE);
    final hoveredBg = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9).withValues(alpha: 0.6);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        transform: Matrix4.translationValues(
          0,
          _isHovered ? -3 : (isSelected ? -2 : 0),
          0,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with gentle pill container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? activeBg : (_isHovered ? hoveredBg : Colors.transparent),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isSelected ? widget.item.activeIcon : widget.item.icon,
                      size: isSelected ? 21 : 19,
                      color: isSelected
                          ? primaryColor
                          : (_isHovered
                              ? (isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4F46E5))
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Label Text
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? primaryColor
                          : (_isHovered
                              ? (isDark ? Colors.white : const Color(0xFF1E293B))
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      letterSpacing: -0.2,
                    ),
                    child: Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
