import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/budgets/budgets_screen.dart';
import '../screens/goals/goals_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import 'category_management_dialog.dart';
import 'user_avatar.dart';

class AppDrawer extends StatelessWidget {
  final Function(int)? onSelectTab;

  const AppDrawer({super.key, this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAF5FF),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header (Soft Light Purple Gradient)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF312E81), const Color(0xFF4338CA)]
                      : [const Color(0xFF4338CA), const Color(0xFF6366F1), const Color(0xFF818CF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: UserAvatar(
                      name: user?.fullName ?? 'User',
                      avatarUrl: user?.avatarUrl,
                      size: 52,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items List (Elevated on Hover)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  _DrawerMenuItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Overview / Home',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelectTab != null) onSelectTab!(0);
                    },
                  ),
                  const SizedBox(height: 6),
                  _DrawerMenuItem(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Transactions',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelectTab != null) {
                        onSelectTab!(1);
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()));
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  _DrawerMenuItem(
                    icon: Icons.pie_chart_rounded,
                    title: 'Budgets',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelectTab != null) {
                        onSelectTab!(2);
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen()));
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  _DrawerMenuItem(
                    icon: Icons.track_changes_rounded,
                    title: 'Savings Goals',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelectTab != null) {
                        onSelectTab!(3);
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()));
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  _DrawerMenuItem(
                    icon: Icons.category_rounded,
                    title: 'Manage Categories',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(context: context, builder: (_) => const CategoryManagementDialog());
                    },
                  ),
                  const SizedBox(height: 6),
                  _DrawerMenuItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Financial Reports',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelectTab != null) {
                        onSelectTab!(4);
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  const SizedBox(height: 6),
                  _DrawerMenuItem(
                    icon: Icons.person_rounded,
                    title: 'Profile & Settings',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelectTab != null) {
                        onSelectTab!(5);
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  // Dark Mode Switch Item
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFEDE9FE),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.dark_mode_outlined, color: Color(0xFF6366F1), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: themeProvider.isDarkMode,
                          activeTrackColor: const Color(0xFF6366F1),
                          onChanged: (_) => themeProvider.toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sign Out Button (Soft Rose/Purple Mix)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _SignOutButton(
                isDark: isDark,
                onTap: () async {
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
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_DrawerMenuItem> createState() => _DrawerMenuItemState();
}

class _DrawerMenuItemState extends State<_DrawerMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(_isHovered ? 4 : 0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: _isHovered
              ? (widget.isDark ? const Color(0xFF312E81).withValues(alpha: 0.45) : const Color(0xFFEDE9FE))
              : (widget.isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF6366F1)
                : (widget.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            width: _isHovered ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: _isHovered ? 0.2 : (widget.isDark ? 0.1 : 0.04)),
              blurRadius: _isHovered ? 12 : 4,
              offset: Offset(0, _isHovered ? 4 : 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: _isHovered ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      color: const Color(0xFF6366F1),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: _isHovered ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: 0.4),
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

class _SignOutButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _SignOutButton({required this.isDark, required this.onTap});

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: _isHovered
              ? (widget.isDark ? const Color(0xFF881337).withValues(alpha: 0.4) : const Color(0xFFFFE4E6))
              : (widget.isDark ? const Color(0xFF881337).withValues(alpha: 0.2) : const Color(0xFFFFF1F2)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? const Color(0xFFE11D48) : const Color(0xFFFDA4AF),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE11D48).withValues(alpha: _isHovered ? 0.25 : 0.06),
              blurRadius: _isHovered ? 12 : 4,
              offset: Offset(0, _isHovered ? 4 : 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout_rounded, color: Color(0xFFBE123C), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Color(0xFFBE123C),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
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
