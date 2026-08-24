import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _filterType = 'all'; // 'all', 'income', 'expense'
  String _searchQuery = '';
  int? _selectedCategoryId;

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterType => _filterType;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;

  List<TransactionModel> get filteredTransactions {
    return _transactions.where((tx) {
      final matchesType = _filterType == 'all' || tx.type.toLowerCase() == _filterType.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          tx.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.categoryName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryId == null || tx.categoryId == _selectedCategoryId;
      return matchesType && matchesSearch && matchesCategory;
    }).toList();
  }

  double get totalIncome {
    return _transactions
        .where((tx) => tx.type.toLowerCase() == 'income')
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalExpense {
    return _transactions
        .where((tx) => tx.type.toLowerCase() == 'expense')
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get netBalance => totalIncome - totalExpense;

  List<TransactionModel> get recentTransactions {
    final sorted = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return sorted.take(5).toList();
  }

  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    if (_apiClient.isDemoMode) {
      _loadDefaultCategories();
      notifyListeners();
      return;
    }

    try {
      final response = await _apiClient.get('/categories.php');
      if (response.success && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['categories'] ?? []);
        _categories = list.map((item) => CategoryModel.fromJson(item)).toList();
      } else {
        _loadDefaultCategories();
      }
    } catch (_) {
      _loadDefaultCategories();
    }
    notifyListeners();
  }

  Future<void> fetchTransactions() async {
    _setLoading(true);
    _errorMessage = null;

    if (_categories.isEmpty) {
      await fetchCategories();
    }

    final prefs = await SharedPreferences.getInstance();
    final savedTxJson = prefs.getString('user_transactions');

    if (_apiClient.isDemoMode) {
      if (savedTxJson != null) {
        final List list = jsonDecode(savedTxJson);
        _transactions = list.map((item) => TransactionModel.fromJson(item)).toList();
      } else {
        _transactions = [];
      }
      _setLoading(false);
      return;
    }

    try {
      final response = await _apiClient.get('/transactions.php');
      if (response.success && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['transactions'] ?? []);
        _transactions = list.map((item) => TransactionModel.fromJson(item)).toList();
        await _saveToStorage();
      } else {
        if (savedTxJson != null) {
          final List list = jsonDecode(savedTxJson);
          _transactions = list.map((item) => TransactionModel.fromJson(item)).toList();
        } else {
          _transactions = [];
        }
      }
    } catch (_) {
      if (savedTxJson != null) {
        final List list = jsonDecode(savedTxJson);
        _transactions = list.map((item) => TransactionModel.fromJson(item)).toList();
      } else {
        _transactions = [];
      }
    }
    _setLoading(false);
  }

  Future<bool> addTransaction({
    required int categoryId,
    required String type,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    _setLoading(true);

    final category = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryModel(id: categoryId, name: 'General', type: type),
    );

    final newTx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 1,
      categoryId: categoryId,
      categoryName: category.name,
      categoryIcon: category.icon,
      categoryColor: category.color,
      type: type,
      amount: amount,
      description: description,
      transactionDate: date,
      createdAt: DateTime.now(),
    );

    if (_apiClient.isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      _transactions.insert(0, newTx);
      await _saveToStorage();
      _setLoading(false);
      return true;
    }

    try {
      final response = await _apiClient.post('/transactions.php', {
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'description': description,
        'transaction_date': date.toIso8601String().split('T').first,
      });

      if (response.success) {
        await fetchTransactions();
        _setLoading(false);
        return true;
      } else {
        _transactions.insert(0, newTx);
        await _saveToStorage();
        _setLoading(false);
        return true;
      }
    } catch (_) {
      _transactions.insert(0, newTx);
      await _saveToStorage();
      _setLoading(false);
      return true;
    }
  }

  Future<bool> updateTransaction({
    required int id,
    required int categoryId,
    required String type,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    _setLoading(true);
    final category = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryModel(id: categoryId, name: 'General', type: type),
    );

    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(
        categoryId: categoryId,
        categoryName: category.name,
        categoryIcon: category.icon,
        categoryColor: category.color,
        type: type,
        amount: amount,
        description: description,
        transactionDate: date,
      );
      await _saveToStorage();
    }

    if (!_apiClient.isDemoMode) {
      try {
        await _apiClient.put('/transactions.php', {
          'id': id,
          'category_id': categoryId,
          'type': type,
          'amount': amount,
          'description': description,
          'transaction_date': date.toIso8601String().split('T').first,
        });
      } catch (_) {}
    }

    _setLoading(false);
    return true;
  }

  Future<bool> deleteTransaction(int id) async {
    _transactions.removeWhere((tx) => tx.id == id);
    await _saveToStorage();
    notifyListeners();

    if (!_apiClient.isDemoMode) {
      try {
        await _apiClient.delete('/transactions.php?id=$id');
      } catch (_) {}
    }
    return true;
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _transactions.map((tx) => tx.toJson()).toList();
    await prefs.setString('user_transactions', jsonEncode(jsonList));
  }

  void _loadDefaultCategories() {
    _categories = [
      // Income Categories
      CategoryModel(id: 1, name: 'Salary', type: 'income', icon: 'briefcase', color: '#10B981'),
      CategoryModel(id: 2, name: 'Freelance', type: 'income', icon: 'laptop', color: '#6366F1'),
      CategoryModel(id: 3, name: 'Investments', type: 'income', icon: 'trending-up', color: '#06B6D4'),
      CategoryModel(id: 4, name: 'Side Hustle', type: 'income', icon: 'zap', color: '#F59E0B'),
      CategoryModel(id: 5, name: 'Gifts & Bonus', type: 'income', icon: 'gift', color: '#8B5CF6'),
      // Expense Categories
      CategoryModel(id: 6, name: 'Food & Dining', type: 'expense', icon: 'utensils', color: '#EF4444'),
      CategoryModel(id: 7, name: 'Housing & Rent', type: 'expense', icon: 'home', color: '#F97316'),
      CategoryModel(id: 8, name: 'Transportation', type: 'expense', icon: 'car', color: '#3B82F6'),
      CategoryModel(id: 9, name: 'Shopping', type: 'expense', icon: 'shopping-bag', color: '#EC4899'),
      CategoryModel(id: 10, name: 'Entertainment', type: 'expense', icon: 'film', color: '#8B5CF6'),
      CategoryModel(id: 11, name: 'Utilities & Bills', type: 'expense', icon: 'zap', color: '#EAB308'),
      CategoryModel(id: 12, name: 'Health & Medical', type: 'expense', icon: 'heart', color: '#14B8A6'),
      CategoryModel(id: 13, name: 'Education', type: 'expense', icon: 'book', color: '#6366F1'),
      CategoryModel(id: 14, name: 'Travel', type: 'expense', icon: 'plane', color: '#06B6D4'),
    ];
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
