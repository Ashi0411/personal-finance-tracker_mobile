class BudgetModel {
  final int id;
  final int userId;
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final double allocatedAmount;
  final double spentAmount;
  final String monthYear; // 'YYYY-MM'

  BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon = 'pie-chart',
    this.categoryColor = '#6366F1',
    required this.allocatedAmount,
    this.spentAmount = 0.0,
    required this.monthYear,
  });

  double get remainingAmount => (allocatedAmount - spentAmount).clamp(0.0, double.infinity);
  double get percentageSpent => allocatedAmount > 0 ? ((spentAmount / allocatedAmount) * 100) : 0.0;

  // Status: safe (< 75%), warning (75% - 99%), exceeded (>= 100%)
  String get status {
    if (percentageSpent >= 100.0) return 'exceeded';
    if (percentageSpent >= 75.0) return 'warning';
    return 'safe';
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      categoryName: json['category_name'] ?? json['category'] ?? 'General',
      categoryIcon: json['category_icon'] ?? json['icon'] ?? 'pie-chart',
      categoryColor: json['category_color'] ?? json['color'] ?? '#6366F1',
      allocatedAmount: json['allocated_amount'] is num
          ? (json['allocated_amount'] as num).toDouble()
          : double.tryParse(json['allocated_amount']?.toString() ?? (json['amount']?.toString() ?? '0.0')) ?? 0.0,
      spentAmount: json['spent_amount'] is num
          ? (json['spent_amount'] as num).toDouble()
          : double.tryParse(json['spent_amount']?.toString() ?? '0.0') ?? 0.0,
      monthYear: json['month_year'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'category_color': categoryColor,
      'allocated_amount': allocatedAmount,
      'spent_amount': spentAmount,
      'month_year': monthYear,
    };
  }

  BudgetModel copyWith({
    int? id,
    int? userId,
    int? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    double? allocatedAmount,
    double? spentAmount,
    String? monthYear,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      monthYear: monthYear ?? this.monthYear,
    );
  }
}
