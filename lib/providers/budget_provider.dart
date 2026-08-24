import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';

class BudgetProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalAllocated {
    return _budgets.fold(0.0, (sum, b) => sum + b.allocatedAmount);
  }

  double get totalSpent {
    return _budgets.fold(0.0, (sum, b) => sum + b.spentAmount);
  }

  double get overallPercentage {
    if (totalAllocated <= 0) return 0.0;
    return (totalSpent / totalAllocated) * 100;
  }

  Future<void> fetchBudgets() async {
    _setLoading(true);
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    final savedBudgetsJson = prefs.getString('user_budgets');

    if (_apiClient.isDemoMode) {
      if (savedBudgetsJson != null) {
        final List list = jsonDecode(savedBudgetsJson);
        _budgets = list.map((item) => BudgetModel.fromJson(item)).toList();
      } else {
        _budgets = [];
      }
      _setLoading(false);
      return;
    }

    try {
      final response = await _apiClient.get('/budgets.php');
      if (response.success && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['budgets'] ?? []);
        _budgets = list.map((item) => BudgetModel.fromJson(item)).toList();
        await _saveToStorage();
      } else {
        if (savedBudgetsJson != null) {
          final List list = jsonDecode(savedBudgetsJson);
          _budgets = list.map((item) => BudgetModel.fromJson(item)).toList();
        } else {
          _budgets = [];
        }
      }
    } catch (_) {
      if (savedBudgetsJson != null) {
        final List list = jsonDecode(savedBudgetsJson);
        _budgets = list.map((item) => BudgetModel.fromJson(item)).toList();
      } else {
        _budgets = [];
      }
    }
    _setLoading(false);
  }

  Future<bool> setBudget({
    required CategoryModel category,
    required double allocatedAmount,
  }) async {
    _setLoading(true);

    final now = DateTime.now();
    final monthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final newBudget = BudgetModel(
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

    final existingIndex = _budgets.indexWhere((b) => b.categoryId == category.id);
    if (existingIndex != -1) {
      _budgets[existingIndex] = _budgets[existingIndex].copyWith(allocatedAmount: allocatedAmount);
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
