import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/goal_model.dart';

class GoalProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<GoalModel> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<GoalModel> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalTargetAmount {
    return _goals.fold(0.0, (sum, g) => sum + g.targetAmount);
  }

  double get totalSavedAmount {
    return _goals.fold(0.0, (sum, g) => sum + g.currentAmount);
  }

  double get overallProgress {
    if (totalTargetAmount <= 0) return 0.0;
    return (totalSavedAmount / totalTargetAmount) * 100;
  }

  Future<void> fetchGoals() async {
    _setLoading(true);
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    final savedGoalsJson = prefs.getString('user_goals');

    if (_apiClient.isDemoMode) {
      if (savedGoalsJson != null) {
        final List list = jsonDecode(savedGoalsJson);
        _goals = list.map((item) => GoalModel.fromJson(item)).toList();
      } else {
        _goals = [];
      }
      _setLoading(false);
      return;
    }

    try {
      final response = await _apiClient.get('/goals.php');
      if (response.success && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['goals'] ?? []);
        _goals = list.map((item) => GoalModel.fromJson(item)).toList();
        await _saveToStorage();
      } else {
        if (savedGoalsJson != null) {
          final List list = jsonDecode(savedGoalsJson);
          _goals = list.map((item) => GoalModel.fromJson(item)).toList();
        } else {
          _goals = [];
        }
      }
    } catch (_) {
      if (savedGoalsJson != null) {
        final List list = jsonDecode(savedGoalsJson);
        _goals = list.map((item) => GoalModel.fromJson(item)).toList();
      } else {
        _goals = [];
      }
    }
    _setLoading(false);
  }

  Future<bool> addGoal({
    required String name,
    required double targetAmount,
    required double initialAmount,
    required DateTime targetDate,
    String? icon,
    String? color,
  }) async {
    _setLoading(true);

    final newGoal = GoalModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 1,
      name: name,
      targetAmount: targetAmount,
      currentAmount: initialAmount,
      targetDate: targetDate,
      icon: icon ?? 'target',
      color: color ?? '#8B5CF6',
      isCompleted: initialAmount >= targetAmount,
      createdAt: DateTime.now(),
    );

    _goals.insert(0, newGoal);
    await _saveToStorage();

    if (!_apiClient.isDemoMode) {
      try {
        await _apiClient.post('/goals.php', {
          'name': name,
          'target_amount': targetAmount,
          'initial_amount': initialAmount,
          'target_date': targetDate.toIso8601String().split('T').first,
          'icon': icon ?? 'target',
          'color': color ?? '#8B5CF6',
        });
      } catch (_) {}
    }

    _setLoading(false);
    return true;
  }

  Future<bool> updateGoal({
    required int id,
    required String name,
    required double targetAmount,
    required double currentAmount,
    required DateTime targetDate,
    String? icon,
    String? color,
  }) async {
    _setLoading(true);

    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      _goals[index] = _goals[index].copyWith(
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: targetDate,
        icon: icon ?? _goals[index].icon,
        color: color ?? _goals[index].color,
        isCompleted: currentAmount >= targetAmount,
      );
      await _saveToStorage();

      if (!_apiClient.isDemoMode) {
        try {
          await _apiClient.put('/goals.php?id=$id', {
            'name': name,
            'target_amount': targetAmount,
            'current_amount': currentAmount,
            'target_date': targetDate.toIso8601String().split('T').first,
            'icon': icon ?? _goals[index].icon,
            'color': color ?? _goals[index].color,
          });
        } catch (_) {}
      }
    }

    _setLoading(false);
    return true;
  }

  Future<bool> addDeposit({required int goalId, required double depositAmount}) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final updatedAmount = _goals[index].currentAmount + depositAmount;
      _goals[index] = _goals[index].copyWith(
        currentAmount: updatedAmount,
        isCompleted: updatedAmount >= _goals[index].targetAmount,
      );
      await _saveToStorage();
      notifyListeners();

      if (!_apiClient.isDemoMode) {
        try {
          await _apiClient.post('/goal-deposit.php', {
            'goal_id': goalId,
            'amount': depositAmount,
          });
        } catch (_) {}
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteGoal(int id) async {
    _goals.removeWhere((g) => g.id == id);
    await _saveToStorage();
    notifyListeners();

    if (!_apiClient.isDemoMode) {
      try {
        await _apiClient.delete('/goals.php?id=$id');
      } catch (_) {}
    }
    return true;
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _goals.map((g) => g.toJson()).toList();
    await prefs.setString('user_goals', jsonEncode(jsonList));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
