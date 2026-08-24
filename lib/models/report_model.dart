class CategorySpendingSummary {
  final String categoryName;
  final double totalAmount;
  final double percentage;
  final String color;
  final String icon;

  CategorySpendingSummary({
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
    this.color = '#6366F1',
    this.icon = 'tag',
  });

  factory CategorySpendingSummary.fromJson(Map<String, dynamic> json) {
    return CategorySpendingSummary(
      categoryName: json['category_name'] ?? json['category'] ?? 'Other',
      totalAmount: json['total'] is num ? (json['total'] as num).toDouble() : double.tryParse(json['total']?.toString() ?? '0.0') ?? 0.0,
      percentage: json['percentage'] is num ? (json['percentage'] as num).toDouble() : double.tryParse(json['percentage']?.toString() ?? '0.0') ?? 0.0,
      color: json['color'] ?? '#6366F1',
      icon: json['icon'] ?? 'tag',
    );
  }
}

class MonthlyCashflowSummary {
  final String month; // 'Jan', 'Feb', etc.
  final double income;
  final double expense;

  MonthlyCashflowSummary({
    required this.month,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;

  factory MonthlyCashflowSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyCashflowSummary(
      month: json['month'] ?? '',
      income: json['income'] is num ? (json['income'] as num).toDouble() : double.tryParse(json['income']?.toString() ?? '0.0') ?? 0.0,
      expense: json['expense'] is num ? (json['expense'] as num).toDouble() : double.tryParse(json['expense']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}

class FinancialReportModel {
  final String periodType; // 'monthly' or 'yearly'
  final String periodValue; // '2026-08' or '2026'
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate;
  final List<CategorySpendingSummary> categoryBreakdowns;
  final List<MonthlyCashflowSummary> cashflows;

  FinancialReportModel({
    required this.periodType,
    required this.periodValue,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.categoryBreakdowns,
    required this.cashflows,
  });

  factory FinancialReportModel.empty() {
    return FinancialReportModel(
      periodType: 'monthly',
      periodValue: '',
      totalIncome: 0.0,
      totalExpense: 0.0,
      netSavings: 0.0,
      savingsRate: 0.0,
      categoryBreakdowns: [],
      cashflows: [],
    );
  }
}
