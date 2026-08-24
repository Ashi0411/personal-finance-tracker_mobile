class GoalModel {
  final int id;
  final int userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String icon;
  final String color;
  final bool isCompleted;
  final DateTime? createdAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    this.icon = 'target',
    this.color = '#8B5CF6',
    this.isCompleted = false,
    this.createdAt,
  });

  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);
  double get progressPercentage => targetAmount > 0 ? ((currentAmount / targetAmount) * 100).clamp(0.0, 100.0) : 0.0;
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays.clamp(0, 9999);

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    final curAmount = json['current_amount'] is num
        ? (json['current_amount'] as num).toDouble()
        : double.tryParse(json['current_amount']?.toString() ?? (json['saved_amount']?.toString() ?? '0.0')) ?? 0.0;
    final tarAmount = json['target_amount'] is num
        ? (json['target_amount'] as num).toDouble()
        : double.tryParse(json['target_amount']?.toString() ?? '0.0') ?? 0.0;

    return GoalModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? json['title'] ?? '',
      targetAmount: tarAmount,
      currentAmount: curAmount,
      targetDate: json['target_date'] != null
          ? DateTime.tryParse(json['target_date'].toString()) ?? DateTime.now().add(const Duration(days: 90))
          : DateTime.now().add(const Duration(days: 90)),
      icon: json['icon'] ?? 'target',
      color: json['color'] ?? '#8B5CF6',
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true || (curAmount >= tarAmount && tarAmount > 0),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate.toIso8601String().split('T').first,
      'icon': icon,
      'color': color,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  GoalModel copyWith({
    int? id,
    int? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? icon,
    String? color,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
