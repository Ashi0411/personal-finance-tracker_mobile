import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/account_switcher_sheet.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/hover_lift_card.dart';
import '../../widgets/user_avatar.dart';
import '../auth/login_screen.dart';
import 'server_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        if (!context.mounted) return;
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.updateAvatar(base64Image);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture saved successfully! 🎉'),
              backgroundColor: AppColors.income,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load image: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  void _showAvatarPickerOptions(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 20),
                ),
                title: const Text('Choose Photo from Device / Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Upload JPG, PNG from device', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.income, size: 20),
                ),
                title: const Text('Take a Photo (Camera)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Direct camera on mobile / select photo on PC', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              if (authProvider.currentUser?.avatarUrl != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 20),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await authProvider.updateAvatar(null);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile photo removed')),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final nameController = TextEditingController(text: user?.fullName);
    final emailController = TextEditingController(text: user?.email);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Edit Profile & Security',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                CustomTextField(controller: nameController, label: 'Full Name'),
                const SizedBox(height: 14),
                CustomTextField(controller: emailController, label: 'Email Address'),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: currentPasswordController,
                  label: 'Current Password (Optional)',
                  obscureText: true,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: newPasswordController,
                  label: 'New Password (Optional)',
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Save Changes',
                  onPressed: () async {
                    final success = await authProvider.updateProfile(
                      fullName: nameController.text.trim(),
                      email: emailController.text.trim(),
                      currentPassword: currentPasswordController.text,
                      newPassword: newPasswordController.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Profile updated successfully!' : (authProvider.errorMessage ?? 'Update failed'),
                          ),
                          backgroundColor: success ? AppColors.income : AppColors.expense,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(context.tr('select_language'), style: const TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: const Text('English (US)', style: TextStyle(fontWeight: FontWeight.w700)),
                trailing: langProvider.isEnglish
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1))
                    : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  langProvider.setLanguage('en');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Text('🇱🇰', style: TextStyle(fontSize: 24)),
                title: const Text('සිංහල (Sinhala)', style: TextStyle(fontWeight: FontWeight.w700)),
                trailing: langProvider.isSinhala
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1))
                    : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  langProvider.setLanguage('si');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCurrencySelector(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currencies = ['\$', '€', '£', '₹', '¥', 'Rs', 'AED', 'CAD', 'AUD'];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Preferred Currency'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currencies.map((c) {
              final isSelected = themeProvider.currencySymbol == c;
              return ChoiceChip(
                label: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
                selected: isSelected,
                selectedColor: AppColors.primary,
                onSelected: (selected) {
                  if (selected) {
                    themeProvider.setCurrency(c);
                    Navigator.pop(ctx);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                UserAvatar(
                  name: user?.fullName ?? 'User',
                  avatarUrl: user?.avatarUrl,
                  size: 96,
                  showEditBadge: true,
                  onEditPressed: () => _showAvatarPickerOptions(context),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'User Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'user@financetracker.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _showAvatarPickerOptions(context),
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: const Text('Change Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'General Preferences',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          HoverLiftCard(
            borderRadius: 18,
            glowColor: AppColors.primary,
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined, color: AppColors.primary, size: 20),
                  title: Text(context.tr('personal_details'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => _showEditProfileDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.translate_rounded, color: Color(0xFF6366F1), size: 20),
                  title: Text(context.tr('language'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Provider.of<LanguageProvider>(context).isSinhala ? '🇱🇰 සිංහල' : '🇺🇸 English',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  onTap: () => _showLanguageSelector(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined, color: AppColors.savings, size: 20),
                  title: Text(context.tr('dark_mode'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Switch.adaptive(
                    value: themeProvider.isDarkMode,
                    activeTrackColor: AppColors.primary,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.attach_money_rounded, color: AppColors.income, size: 20),
                  title: Text(context.tr('currency'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        themeProvider.currencySymbol,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  onTap: () => _showCurrencySelector(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Network & Backend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          HoverLiftCard(
            borderRadius: 18,
            glowColor: AppColors.accent,
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: ListTile(
              leading: const Icon(Icons.dns_outlined, color: AppColors.accent, size: 20),
              title: const Text('API Base URL & Demo Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Configure PHP server connection', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ServerSettingsScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Account Management & Add/Switch Account Button Card
          Text(
            'Accounts & Switcher',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          HoverLiftCard(
            borderRadius: 18,
            glowColor: const Color(0xFF6366F1),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.switch_account_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('switch_account'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        '${authProvider.savedAccounts.length} ${context.tr("saved_accounts").toLowerCase()}',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => AccountSwitcherSheet.show(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add / Switch',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out of FinanceTracker?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/logo.png', height: 32, width: 32, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'FinanceTracker',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Personal Wealth & Cash Flow Management • v1.0.0',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
