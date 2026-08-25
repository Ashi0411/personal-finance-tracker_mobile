import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class BudgetProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double totalAllocatedForMonth(String monthYear) {
    return _budgets
        .where((b) => b.monthYear == monthYear)
        .fold(0.0, (sum, b) => sum + b.allocatedAmount);
  }

  double totalSpentForMonth(String monthYear) {
    return _budgets
        .where((b) => b.monthYear == monthYear)
        .fold(0.0, (sum, b) => sum + b.spentAmount);
  }

  double _calculateSpentForCategory(BudgetModel b, List<TransactionModel>? transactions, String monthYear) {
    if (transactions == null || transactions.isEmpty) {
      return b.spentAmount;
    }

    final parts = monthYear.split('-');
    final year = int.tryParse(parts[0]) ?? 2026;
    final month = int.tryParse(parts.length > 1 ? parts[1] : '8') ?? 8;

    final catNameLower = b.categoryName.trim().toLowerCase();
    final spent = transactions
        .where((tx) =>
            tx.type.toLowerCase() == 'expense' &&
            tx.transactionDate.year == year &&
            tx.transactionDate.month == month &&
            (tx.categoryId == b.categoryId ||
             tx.categoryName.trim().toLowerCase() == catNameLower))
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return spent;
  }

  Future<void> fetchBudgets({List<TransactionModel>? fallbackTransactions}) async {
    _setLoading(true);
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    final savedBudgetsJson = prefs.getString('user_budgets');

    List<BudgetModel> loadedBudgets = [];

    if (_apiClient.isDemoMode) {
      if (savedBudgetsJson != null) {
        final List list = jsonDecode(savedBudgetsJson);
        loadedBudgets = list.map((item) => BudgetModel.fromJson(item)).toList();
      } else {
        // Default initial budgets specifically tagged for 2026-08 (August 2026)
        loadedBudgets = [
          BudgetModel(
            id: 1,
            userId: 1,
            categoryId: 1,
            categoryName: 'Food',
            categoryIcon: 'restaurant',
            categoryColor: '#3B82F6',
            allocatedAmount: 15000.0,
            spentAmount: 5000.0,
            monthYear: '2026-08',
          ),
          BudgetModel(
            id: 2,
            userId: 1,
            categoryId: 2,
            categoryName: 'Transport',
            categoryIcon: 'directions_car',
            categoryColor: '#06B6D4',
            allocatedAmount: 10000.0,
            spentAmount: 6000.0,
            monthYear: '2026-08',
          ),
        ];
      }
    } else {
      try {
        final response = await _apiClient.get('/budgets.php');
        if (response.success && response.data != null) {
          final List list = response.data is List ? response.data : (response.data['budgets'] ?? []);
          loadedBudgets = list.map((item) => BudgetModel.fromJson(item)).toList();
        } else if (savedBudgetsJson != null) {
          final List list = jsonDecode(savedBudgetsJson);
          loadedBudgets = list.map((item) => BudgetModel.fromJson(item)).toList();
        }
      } catch (_) {
        if (savedBudgetsJson != null) {
          final List list = jsonDecode(savedBudgetsJson);
          loadedBudgets = list.map((item) => BudgetModel.fromJson(item)).toList();
        }
      }
    }

    // Ensure all budgets have a valid monthYear (default to 2026-08 if empty)
    _budgets = loadedBudgets.map((b) {
      final mYear = b.monthYear.isEmpty ? '2026-08' : b.monthYear;
      final actualSpent = _calculateSpentForCategory(b, fallbackTransactions, mYear);
      return b.copyWith(monthYear: mYear, spentAmount: actualSpent);
    }).toList();

    await _saveToStorage();
    _setLoading(false);
  }

  Future<bool> setBudget({
    required CategoryModel category,
    required double allocatedAmount,
    required String monthYear,
    List<TransactionModel>? fallbackTransactions,
  }) async {
    _setLoading(true);

    final tempBudget = BudgetModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 1,
      categoryId: category.id,
      categoryName: category.name,
      categoryColor: category.color,
      categoryIcon: category.icon,
      allocatedAmount: allocatedAmount,
      spentAmount: 0.0,
      monthYear: monthYear,
    );

    final spent = _calculateSpentForCategory(tempBudget, fallbackTransactions, monthYear);
    final newBudget = tempBudget.copyWith(spentAmount: spent);

    final existingIndex = _budgets.indexWhere(
      (b) =>
          (b.categoryId == category.id || b.categoryName.toLowerCase() == category.name.toLowerCase()) &&
          b.monthYear == monthYear,
    );

    if (existingIndex != -1) {
      _budgets[existingIndex] = _budgets[existingIndex].copyWith(
        allocatedAmount: allocatedAmount,
        spentAmount: spent,
        categoryName: category.name,
        categoryColor: category.color,
        categoryIcon: category.icon,
      );
    } else {
      _budgets.add(newBudget);
    }
    await _saveToStorage();

    if (!_apiClient.isDemoMode) {
      try {
        await _apiClient.post('/budgets.php', {
          'category_id': category.id,
          'allocated_amount': allocatedAmount,
          'month_year': monthYear,
        });
      } catch (_) {}
    }

    _setLoading(false);
    return true;
  }

  Future<bool> deleteBudget(int id) async {
    _budgets.removeWhere((b) => b.id == id);
    await _saveToStorage();
    notifyListeners();

    if (!_apiClient.isDemoMode) {
      try {
        await _apiClient.delete('/budgets.php?id=$id');
      } catch (_) {}
    }
    return true;
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _budgets.map((b) => b.toJson()).toList();
    await prefs.setString('user_budgets', jsonEncode(jsonList));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
