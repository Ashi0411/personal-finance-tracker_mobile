class TransactionModel {
  final int id;
  final int userId;
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final String type; // 'income' or 'expense'
  final double amount;
  final String description;
  final DateTime transactionDate;
  final DateTime? createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon = 'tag',
    this.categoryColor = '#6366F1',
    required this.type,
    required this.amount,
    required this.description,
    required this.transactionDate,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      categoryName: json['category_name'] ?? json['category'] ?? 'General',
      categoryIcon: json['category_icon'] ?? json['icon'] ?? 'tag',
      categoryColor: json['category_color'] ?? json['color'] ?? '#6366F1',
      type: json['type'] ?? 'expense',
      amount: json['amount'] is num ? (json['amount'] as num).toDouble() : double.tryParse(json['amount']?.toString() ?? '0.0') ?? 0.0,
      description: json['description'] ?? '',
      transactionDate: json['transaction_date'] != null
          ? DateTime.tryParse(json['transaction_date'].toString()) ?? DateTime.now()
          : (json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now()),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
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
      'type': type,
      'amount': amount,
      'description': description,
      'transaction_date': transactionDate.toIso8601String().split('T').first,
    };
  }

  TransactionModel copyWith({
    int? id,
    int? userId,
    int? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? type,
    double? amount,
    String? description,
    DateTime? transactionDate,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
