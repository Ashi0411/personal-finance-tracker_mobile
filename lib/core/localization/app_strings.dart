import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General & App
      'app_name': 'FinanceTracker',
      'app_tagline': 'Personal Wealth & Cash Flow Management',
      'version': 'v1.0.0',
      'secure_tag': 'End-to-End Secure',

      // Navigation Bar
      'nav_home': 'Home',
      'nav_activity': 'Activity',
      'nav_budgets': 'Budgets',
      'nav_goals': 'Goals',
      'nav_analytics': 'Analytics',
      'nav_profile': 'Profile',

      // Language Switcher
      'language': 'Language',
      'english': 'English',
      'sinhala': 'සිංහල',
      'select_language': 'Select Language',

      // Dashboard
      'monthly_overview': 'Monthly Overview',
      'monthly_income': 'Monthly Income',
      'monthly_expenses': 'Monthly Expenses',
      'net_savings': 'Net Savings',
      'savings_rate': 'Savings Rate',
      'income_by_category': 'Income by Category',
      'expense_by_category': 'Expense by Category',
      'overall_cashflow': 'Overall Cash Flow',
      'cashflow_trend': 'Cash Flow Trend',
      'quick_actions': 'Quick Actions',
      'add_transaction': 'Add Transaction',
      'add_category': 'Add Category',
      'recent_activities': 'Recent Activities',
      'view_all': 'View All',
      'no_transactions': 'No transactions recorded yet',
      'income': 'Income',
      'expense': 'Expense',
      'sign_out': 'Sign Out',
      'open_menu': 'Open Menu',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',

      // Budgets & Limits
      'monthly_budgets': 'Monthly Budgets & Limits',
      'budget_overview': 'Monthly Budget Overview',
      'total_budget': 'Total Budget',
      'spent': 'Spent',
      'remaining': 'Remaining',
      'limit': 'Limit',
      'add_budget': 'Add Budget',
      'edit_budget': 'Edit Budget',
      'delete_budget': 'Delete Budget',
      'no_budgets_for_month': 'No Budgets for this month',
      'create_budget_prompt': 'Plan your spending by setting category limits.',
      'add_first_budget': 'Set First Budget',
      'over_budget': 'OVER BUDGET',
      'budget_limit_hint': 'Enter budget limit amount',

      // Savings Goals
      'savings_goals': 'Savings Goals',
      'overall_savings': 'Total Savings Progress',
      'add_goal': 'Add Goal',
      'edit_goal': 'Edit Goal',
      'delete_goal': 'Delete Goal',
      'quick_deposit': 'Deposit',
      'target_date': 'Target Date',
      'target_amount': 'Target Amount',
      'saved_amount': 'Saved Amount',
      'days_left': 'days left',
      'completed': 'COMPLETED',
      'no_goals_yet': 'No Savings Goals Yet',
      'create_goal_prompt': 'Create a goal for your vacation, emergency fund, or gadget.',
      'add_first_goal': 'Add First Goal',

      // Analytics & Reports
      'financial_analytics': 'Financial Analytics',
      'monthly_report': 'Monthly Report',
      'annual_report': 'Annual Report',
      'annual_overview': 'Annual Overview',
      'annual_income': 'Annual Income',
      'annual_expenses': 'Annual Expenses',
      'annual_net_savings': 'Annual Net Savings',
      'spending_by_category': 'Spending by Category',
      'export_statement': 'Export Financial Statement',
      'download_pdf': 'Download PDF Statement',
      'export_csv': 'Export CSV (Excel / Sheets)',
      'export_subtitle': 'Download official PDF & CSV records',
      'annual_progression': '12-Month Annual Progression',
      'month': 'Month',
      'entries': 'entries',

      // Profile & Settings
      'profile_settings': 'Profile & Settings',
      'personal_details': 'Personal Details',
      'full_name': 'Full Name',
      'email': 'Email Address',
      'currency': 'Default Currency',
      'save_changes': 'Save Changes',
      'app_preferences': 'Preferences',
      'server_settings': 'API Base URL & Server',
      'change_photo': 'Change Profile Photo',
      'confirm_logout': 'Confirm Logout',
      'logout_confirm_msg': 'Are you sure you want to log out of FinanceTracker?',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'edit': 'Edit',
      'save': 'Save',
      'update': 'Update',
      'search': 'Search',
      'all': 'All',
      'filter': 'Filter',
      'description': 'Description',
      'amount': 'Amount',
      'category': 'Category',
      'date': 'Date',

      // Multi-Account Switcher
      'switch_account': 'Switch Account',
      'add_another_account': 'Add Another Account',
      'active_account': 'Active',
      'saved_accounts': 'Saved Accounts on Device',
      'remove_account': 'Remove from Device',
      'remove_account_msg': 'Are you sure you want to remove this account from this device?',
      'switched_to': 'Switched to',
      'switch': 'Switch',

      // Months
      'month_1': 'January',
      'month_2': 'February',
      'month_3': 'March',
      'month_4': 'April',
      'month_5': 'May',
      'month_6': 'June',
      'month_7': 'July',
      'month_8': 'August',
      'month_9': 'September',
      'month_10': 'October',
      'month_11': 'November',
      'month_12': 'December',
    },
    'si': {
      // General & App
      'app_name': 'FinanceTracker',
      'app_tagline': 'පුද්ගලික මූල්‍ය සහ මුදල් ප්‍රවාහ කළමනාකරණය',
      'version': 'v1.0.0',
      'secure_tag': 'පූර්ණ ආරක්‍ෂිතයි',

      // Navigation Bar
      'nav_home': 'මුල් පිටුව',
      'nav_activity': 'ක්‍රියාකාරකම්',
      'nav_budgets': 'අයවැය',
      'nav_goals': 'ඉලක්ක',
      'nav_analytics': 'විශ්ලේෂණ',
      'nav_profile': 'ගිණුම',

      // Language Switcher
      'language': 'භාෂාව',
      'english': 'English',
      'sinhala': 'සිංහල',
      'select_language': 'භාෂාව තෝරන්න',

      // Dashboard
      'monthly_overview': 'මාසික දළ විශ්ලේෂණය',
      'monthly_income': 'මාසික ආදායම',
      'monthly_expenses': 'මාසික වියදම්',
      'net_savings': 'ශුද්ධ ඉතිරිකිරීම්',
      'savings_rate': 'ඉතිරිකිරීමේ අනුපාතය',
      'income_by_category': 'ප්‍රවර්ග අනුව ආදායම',
      'expense_by_category': 'ප්‍රවර්ග අනුව වියදම්',
      'overall_cashflow': 'සමස්ත මුදල් ප්‍රවාහය',
      'cashflow_trend': 'මුදල් ප්‍රවාහ ප්‍රවණතාව',
      'quick_actions': 'ක්ෂණික ක්‍රියාකාරකම්',
      'add_transaction': 'ගනුදෙනුවක් එක් කරන්න',
      'add_category': 'ප්‍රවර්ගයක් එක් කරන්න',
      'recent_activities': 'මෑත ගනුදෙනු',
      'view_all': 'සියල්ල බලන්න',
      'no_transactions': 'තවමත් ගනුදෙනු සටහන් කර නොමැත',
      'income': 'ආදායම',
      'expense': 'වියදම',
      'sign_out': 'පිටවීම',
      'open_menu': 'මෙනුව විවෘත කරන්න',
      'dark_mode': 'රාත්‍රී මාදිලිය',
      'light_mode': 'දිවා මාදිලිය',

      // Budgets & Limits
      'monthly_budgets': 'මාසික අයවැය සහ සීමාවන්',
      'budget_overview': 'මාසික අයවැය සාරාංශය',
      'total_budget': 'මුළු අයවැය',
      'spent': 'වියදම් කළ මුදල',
      'remaining': 'ඉතිරි මුදල',
      'limit': 'සීමාව',
      'add_budget': 'අයවැයක් එක් කරන්න',
      'edit_budget': 'අයවැය සංස්කරණය',
      'delete_budget': 'අයවැය මකන්න',
      'no_budgets_for_month': 'මෙම මාසය සඳහා අයවැයක් සකසා නැත',
      'create_budget_prompt': 'ප්‍රවර්ග සීමාවන් නියම කර ඔබගේ වියදම් සැලසුම් කරන්න.',
      'add_first_budget': 'පළමු අයවැය සකසන්න',
      'over_budget': 'සීමාව ඉක්මවා ඇත',
      'budget_limit_hint': 'අයවැය සීමා මුදල ඇතුළත් කරන්න',

      // Savings Goals
      'savings_goals': 'ඉතිරිකිරීමේ ඉලක්ක',
      'overall_savings': 'මුළු ඉතිරිකිරීම් ප්‍රගතිය',
      'add_goal': 'ඉලක්කයක් එක් කරන්න',
      'edit_goal': 'ඉලක්කය සංස්කරණය',
      'delete_goal': 'ඉලක්කය මකන්න',
      'quick_deposit': 'තැන්පත් කරන්න',
      'target_date': 'ඉලක්ක දිනය',
      'target_amount': 'ඉලක්ක මුදල',
      'saved_amount': 'ඉතිරි කළ මුදල',
      'days_left': 'දින ඉතිරියි',
      'completed': 'සම්පූර්ණයි',
      'no_goals_yet': 'තවමත් ඉතිරිකිරීමේ ඉලක්ක නැත',
      'create_goal_prompt': 'හදිසි අරමුදලක්, සංචාරයක් හෝ අවශ්‍යතාවක් සඳහා ඉලක්කයක් සකසන්න.',
      'add_first_goal': 'පළමු ඉලක්කය එක් කරන්න',

      // Analytics & Reports
      'financial_analytics': 'මූල්‍ය විශ්ලේෂණ',
      'monthly_report': 'මාසික වාර්තාව',
      'annual_report': 'වාර්ෂික වාර්තාව',
      'annual_overview': 'වාර්ෂික සාරාංශය',
      'annual_income': 'වාර්ෂික ආදායම',
      'annual_expenses': 'වාර්ෂික වියදම්',
      'annual_net_savings': 'වාර්ෂික ශුද්ධ ඉතිරිකිරීම්',
      'spending_by_category': 'ප්‍රවර්ග අනුව වියදම්',
      'export_statement': 'මූල්‍ය ප්‍රකාශනය බාගන්න',
      'download_pdf': 'PDF ප්‍රකාශනය බාගන්න',
      'export_csv': 'CSV ගොනුව බාගන්න (Excel)',
      'export_subtitle': 'නිල PDF සහ CSV ලේඛන බාගත කරන්න',
      'annual_progression': '12-මාසික වාර්ෂික ප්‍රගතිය',
      'month': 'මාසය',
      'entries': 'වාර්තා',

      // Profile & Settings
      'profile_settings': 'ගිණුම සහ සැකසුම්',
      'personal_details': 'පුද්ගලික තොරතුරු',
      'full_name': 'සම්පූර්ණ නම',
      'email': 'විද්‍යුත් තැපෑල',
      'currency': 'පෙරනිමි මුදල් ඒකකය',
      'save_changes': 'වෙනස්කම් සුරකින්න',
      'app_preferences': 'යෙදුම් සැකසුම්',
      'server_settings': 'API සර්වර් සැකසුම්',
      'change_photo': 'පැතිකඩ ඡායාරූපය වෙනස් කරන්න',
      'confirm_logout': 'පිටවීම තහවුරු කරන්න',
      'logout_confirm_msg': 'ඔබට FinanceTracker වෙතින් පිටවීමට අවශ්‍ය බව සහතිකද?',
      'cancel': 'අවලංගු කරන්න',
      'confirm': 'තහවුරු කරන්න',
      'delete': 'මකන්න',
      'edit': 'සංස්කරණය',
      'save': 'සුරකින්න',
      'update': 'යාවත්කාලීන කරන්න',
      'search': 'සොයන්න',
      'all': 'සියල්ල',
      'filter': 'පෙරන්න',
      'description': 'විස්තරය',
      'amount': 'මුදල',
      'category': 'ප්‍රවර්ගය',
      'date': 'දිනය',

      // Multi-Account Switcher
      'switch_account': 'ගිණුම මාරු කරන්න',
      'add_another_account': 'වෙනත් ගිණුමක් එක් කරන්න',
      'active_account': 'ක්‍රියාකාරී',
      'saved_accounts': 'උපාංගයේ සුරකින ලද ගිණුම්',
      'remove_account': 'උපාංගයෙන් ඉවත් කරන්න',
      'remove_account_msg': 'මෙම ගිණුම මෙම උපාංගයෙන් ඉවත් කිරීමට ඔබට අවශ්‍ය බව සහතිකද?',
      'switched_to': 'ගිණුම වෙත මාරු විය',
      'switch': 'මාරු වන්න',

      // Months
      'month_1': 'ජනවාරි',
      'month_2': 'පෙබරවාරි',
      'month_3': 'මාර්තු',
      'month_4': 'අප්‍රේල්',
      'month_5': 'මැයි',
      'month_6': 'ජූනි',
      'month_7': 'ජූලි',
      'month_8': 'අගෝස්තු',
      'month_9': 'සැප්තැම්බර්',
      'month_10': 'ඔක්තෝබර්',
      'month_11': 'නොවැම්බර්',
      'month_12': 'දෙසැම්බර්',
    },
  };

  static String get(BuildContext context, String key) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final lang = langProvider.currentLanguage;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }

  static String of(BuildContext context, String key) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: true);
    final lang = langProvider.currentLanguage;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }

  static String formatMonth(BuildContext context, int month, int year) {
    final monthName = of(context, 'month_$month');
    final isSinhala = Provider.of<LanguageProvider>(context, listen: false).isSinhala;
    return isSinhala ? '$year $monthName' : '$monthName $year';
  }
}

extension AppLocalizationExtension on BuildContext {
  String tr(String key) => AppStrings.of(this, key);
}
