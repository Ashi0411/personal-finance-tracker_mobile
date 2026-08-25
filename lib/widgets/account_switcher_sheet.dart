import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_strings.dart';
import '../models/saved_account_model.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/report_provider.dart';
import '../providers/transaction_provider.dart';
import '../screens/auth/login_screen.dart';
import 'hover_lift_card.dart';
import 'user_avatar.dart';

class AccountSwitcherSheet extends StatelessWidget {
  const AccountSwitcherSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AccountSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = authProvider.currentUser;
    final savedAccounts = authProvider.savedAccounts;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Close Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.switch_account_rounded, color: Color(0xFF6366F1), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('switch_account'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            context.tr('saved_accounts'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Saved Accounts List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: savedAccounts.isNotEmpty ? savedAccounts.length : (currentUser != null ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final account = savedAccounts.isNotEmpty
                        ? savedAccounts[index]
                        : SavedAccountModel(
                            id: currentUser!.id,
                            fullName: currentUser.fullName,
                            email: currentUser.email,
                            avatarUrl: currentUser.avatarUrl,
                            currency: currentUser.currency,
                            lastActive: DateTime.now(),
                          );

                    final isActive = currentUser != null &&
                        currentUser.email.toLowerCase() == account.email.toLowerCase();

                    return _AccountItemTile(
                      account: account,
                      isActive: isActive,
                      isDark: isDark,
                      onTap: () async {
                        if (!isActive) {
                          Navigator.pop(context);
                          await authProvider.switchAccount(account.email);
                          if (context.mounted) {
                            // Refresh all providers for new account
                            final txProvider = Provider.of<TransactionProvider>(context, listen: false);
                            final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
                            final goalProvider = Provider.of<GoalProvider>(context, listen: false);
                            final reportProvider = Provider.of<ReportProvider>(context, listen: false);

                            await txProvider.fetchTransactions();
                            budgetProvider.fetchBudgets(fallbackTransactions: txProvider.transactions);
                            goalProvider.fetchGoals();
                            reportProvider.fetchReport(fallbackTransactions: txProvider.transactions);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${context.tr("switched_to")}: ${account.fullName}'),
                                backgroundColor: const Color(0xFF6366F1),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      onRemove: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text(context.tr('remove_account'), style: const TextStyle(fontWeight: FontWeight.w800)),
                            content: Text('${context.tr("remove_account_msg")}\n(${account.email})'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: Text(context.tr('cancel')),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBE123C)),
                                onPressed: () => Navigator.pop(c, true),
                                child: Text(context.tr('delete'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await authProvider.removeSavedAccount(account.email);
                        }
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),
              Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              const SizedBox(height: 10),

              // "+ Add Another Account" Button
              HoverLiftCard(
                liftOffset: -3,
                borderRadius: 20,
                glowColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFC7D2FE),
                  width: 1.2,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.tr('add_another_account'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF4338CA),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountItemTile extends StatelessWidget {
  final SavedAccountModel account;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _AccountItemTile({
    required this.account,
    required this.isActive,
    required this.isDark,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return HoverLiftCard(
      liftOffset: -2,
      borderRadius: 18,
      glowColor: isActive ? const Color(0xFF10B981) : const Color(0xFF6366F1),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: isActive
          ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5))
          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
      border: Border.all(
        color: isActive
            ? const Color(0xFF10B981)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        width: isActive ? 1.6 : 1.0,
      ),
      onTap: onTap,
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              UserAvatar(
                name: account.fullName,
                avatarUrl: account.avatarUrl,
                size: 46,
              ),
              if (isActive)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Name and Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        account.fullName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          context.tr('active_account'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  account.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Trailing: Radio/Check or Delete Option
          if (isActive)
            const Icon(Icons.radio_button_checked_rounded, color: Color(0xFF10B981), size: 22)
          else
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
              tooltip: context.tr('remove_account'),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
