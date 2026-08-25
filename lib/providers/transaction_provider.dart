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
    final prefs = await SharedPreferences.getInstance();
    final savedCats = prefs.getString('user_categories');

    if (savedCats != null) {
      try {
        final List list = jsonDecode(savedCats);
        if (list.isNotEmpty) {
          _categories = list.map((item) => CategoryModel.fromJson(item)).toList();
          notifyListeners();
          return;
        }
      } catch (_) {}
    }

    if (_apiClient.isDemoMode) {
      _loadDefaultCategories();
      await _saveCategoriesToStorage();
      notifyListeners();
      return;
    }

    try {
      final response = await _apiClient.get('/categories.php');
      if (response.success && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['categories'] ?? []);
        if (list.isNotEmpty) {
          _categories = list.map((item) => CategoryModel.fromJson(item)).toList();
        } else {
          _loadDefaultCategories();
        }
        await _saveCategoriesToStorage();
      } else {
        _loadDefaultCategories();
        await _saveCategoriesToStorage();
      }
    } catch (_) {
      _loadDefaultCategories();
      await _saveCategoriesToStorage();
    }
    notifyListeners();
  }

  Future<bool> addCategory({
    required String name,
    required String type,
    required String icon,
    required String color,
  }) async {
    final newCategory = CategoryModel(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      type: type,
      icon: icon,
      color: color,
      isDefault: false,
    );

    _categories.add(newCategory);
    await _saveCategoriesToStorage();
    notifyListeners();

    if (!_apiClient.isDemoMode) {
      try {
        await _apiClient.post('/categories.php', {
          'name': name,
          'type': type,
          'icon': icon,
          'color': color,
        });
      } catch (_) {}
    }
    return true;
  }

  Future<bool> updateCategory({
    required int id,
    required String name,
    required String type,
    required String icon,
    required String color,
  }) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index] = _categories[index].copyWith(
        name: name,
        type: type,
        icon: icon,
        color: color,
      );
      await _saveCategoriesToStorage();
      notifyListeners();

      if (!_apiClient.isDemoMode) {
        try {
          await _apiClient.put('/categories.php', {
            'id': id,
            'name': name,
            'type': type,
            'icon': icon,
            'color': color,
          });
        } catch (_) {}
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteCategory(int id) async {
    _categories.removeWhere((c) => c.id == id);
    await _saveCategoriesToStorage();
    notifyListeners();

    if (!_apiClient.isDemoMode) {
      try {
        await _apiClient.delete('/categories.php?id=$id');
      } catch (_) {}
    }
    return true;
  }

  Future<void> _saveCategoriesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _categories.map((c) => c.toJson()).toList();
    await prefs.setString('user_categories', jsonEncode(jsonList));
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
        try {
          final List list = jsonDecode(savedTxJson);
          if (list.isNotEmpty) {
            _transactions = list.map((item) => TransactionModel.fromJson(item)).toList();
          } else {
            _loadDefaultSeedTransactions();
            await _saveToStorage();
          }
        } catch (_) {
          _loadDefaultSeedTransactions();
          await _saveToStorage();
        }
      } else {
        _loadDefaultSeedTransactions();
        await _saveToStorage();
      }
      _setLoading(false);
      return;
    }

    try {
      final response = await _apiClient.get('/transactions.php');
      if (response.success && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['transactions'] ?? []);
        if (list.isNotEmpty) {
          _transactions = list.map((item) => TransactionModel.fromJson(item)).toList();
          await _saveToStorage();
        } else if (savedTxJson != null) {
          final List savedList = jsonDecode(savedTxJson);
          if (savedList.isNotEmpty) {
            _transactions = savedList.map((item) => TransactionModel.fromJson(item)).toList();
          } else {
            _loadDefaultSeedTransactions();
            await _saveToStorage();
          }
        } else {
          _loadDefaultSeedTransactions();
          await _saveToStorage();
        }
      } else {
        if (savedTxJson != null) {
          final List list = jsonDecode(savedTxJson);
          if (list.isNotEmpty) {
            _transactions = list.map((item) => TransactionModel.fromJson(item)).toList();
          } else {
            _loadDefaultSeedTransactions();
            await _saveToStorage();
          }
        } else {
          _loadDefaultSeedTransactions();
          await _saveToStorage();
        }
      }
    } catch (_) {
      if (savedTxJson != null) {
        final List list = jsonDecode(savedTxJson);
        if (list.isNotEmpty) {
          _transactions = list.map((item) => TransactionModel.fromJson(item)).toList();
        } else {
          _loadDefaultSeedTransactions();
          await _saveToStorage();
        }
      } else {
        _loadDefaultSeedTransactions();
        await _saveToStorage();
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

    _transactions.insert(0, newTx);
    await _saveToStorage();

    if (!_apiClient.isDemoMode) {
      try {
        await _apiClient.post('/transactions.php', {
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

  void _loadDefaultSeedTransactions() {
    _transactions = [
      // August 2026
      TransactionModel(
        id: 101,
        userId: 1,
        categoryId: 1,
        categoryName: 'Salary',
        categoryIcon: 'briefcase',
        categoryColor: '#0284C7',
        type: 'income',
        amount: 250000.0,
        description: 'Monthly Salary (August)',
        transactionDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
      ),
      TransactionModel(
        id: 102,
        userId: 1,
        categoryId: 3,
        categoryName: 'Freelance',
        categoryIcon: 'laptop',
        categoryColor: '#6366F1',
        type: 'income',
        amount: 75000.0,
        description: 'Mobile App Design Project',
        transactionDate: DateTime(2026, 8, 10),
        createdAt: DateTime(2026, 8, 10),
      ),
      TransactionModel(
        id: 103,
        userId: 1,
        categoryId: 4,
        categoryName: 'Investments',
        categoryIcon: 'trending-up',
        categoryColor: '#06B6D4',
        type: 'income',
        amount: 32000.0,
        description: 'Stock Dividends & Interest',
        transactionDate: DateTime(2026, 8, 15),
        createdAt: DateTime(2026, 8, 15),
      ),
      TransactionModel(
        id: 104,
        userId: 1,
        categoryId: 8,
        categoryName: 'Housing & Rent',
        categoryIcon: 'home',
        categoryColor: '#F97316',
        type: 'expense',
        amount: 65000.0,
        description: 'Apartment Monthly Rent',
        transactionDate: DateTime(2026, 8, 2),
        createdAt: DateTime(2026, 8, 2),
      ),
      TransactionModel(
        id: 105,
        userId: 1,
        categoryId: 5,
        categoryName: 'Food',
        categoryIcon: 'utensils',
        categoryColor: '#EF4444',
        type: 'expense',
        amount: 32500.0,
        description: 'Monthly Groceries & Supermarket',
        transactionDate: DateTime(2026, 8, 8),
        createdAt: DateTime(2026, 8, 8),
      ),
      TransactionModel(
        id: 106,
        userId: 1,
        categoryId: 6,
        categoryName: 'Transport',
        categoryIcon: 'car',
        categoryColor: '#F43F5E',
        type: 'expense',
        amount: 18500.0,
        description: 'Fuel & Vehicle Maintenance',
        transactionDate: DateTime(2026, 8, 12),
        createdAt: DateTime(2026, 8, 12),
      ),
      TransactionModel(
        id: 107,
        userId: 1,
        categoryId: 10,
        categoryName: 'Utilities & Bills',
        categoryIcon: 'zap',
        categoryColor: '#EAB308',
        type: 'expense',
        amount: 14200.0,
        description: 'Electricity & Fiber Internet Bill',
        transactionDate: DateTime(2026, 8, 18),
        createdAt: DateTime(2026, 8, 18),
      ),
      TransactionModel(
        id: 108,
        userId: 1,
        categoryId: 9,
        categoryName: 'Entertainment',
        categoryIcon: 'film',
        categoryColor: '#8B5CF6',
        type: 'expense',
        amount: 8500.0,
        description: 'Weekend Dining & Streaming',
        transactionDate: DateTime(2026, 8, 22),
        createdAt: DateTime(2026, 8, 22),
      ),

      // July 2026
      TransactionModel(
        id: 109,
        userId: 1,
        categoryId: 1,
        categoryName: 'Salary',
        categoryIcon: 'briefcase',
        categoryColor: '#0284C7',
        type: 'income',
        amount: 250000.0,
        description: 'Monthly Salary (July)',
        transactionDate: DateTime(2026, 7, 1),
        createdAt: DateTime(2026, 7, 1),
      ),
      TransactionModel(
        id: 110,
        userId: 1,
        categoryId: 5,
        categoryName: 'Food',
        categoryIcon: 'utensils',
        categoryColor: '#EF4444',
        type: 'expense',
        amount: 38000.0,
        description: 'Groceries & Provisions',
        transactionDate: DateTime(2026, 7, 15),
        createdAt: DateTime(2026, 7, 15),
      ),
      TransactionModel(
        id: 111,
        userId: 1,
        categoryId: 8,
        categoryName: 'Housing & Rent',
        categoryIcon: 'home',
        categoryColor: '#F97316',
        type: 'expense',
        amount: 65000.0,
        description: 'House Rent (July)',
        transactionDate: DateTime(2026, 7, 2),
        createdAt: DateTime(2026, 7, 2),
      ),

      // June 2026
      TransactionModel(
        id: 112,
        userId: 1,
        categoryId: 1,
        categoryName: 'Salary',
        categoryIcon: 'briefcase',
        categoryColor: '#0284C7',
        type: 'income',
        amount: 250000.0,
        description: 'Monthly Salary (June)',
        transactionDate: DateTime(2026, 6, 1),
        createdAt: DateTime(2026, 6, 1),
      ),
      TransactionModel(
        id: 113,
        userId: 1,
        categoryId: 6,
        categoryName: 'Transport',
        categoryIcon: 'car',
        categoryColor: '#F43F5E',
        type: 'expense',
        amount: 19000.0,
        description: 'Fuel & Highway Tolls',
        transactionDate: DateTime(2026, 6, 14),
        createdAt: DateTime(2026, 6, 14),
      ),
    ];
  }

  void _loadDefaultCategories() {
    _categories = [
      // Income Categories
      CategoryModel(id: 1, name: 'Salary', type: 'income', icon: 'briefcase', color: '#0284C7'),
      CategoryModel(id: 2, name: 'Personal Income', type: 'income', icon: 'trending-up', color: '#0EA5E9'),
      CategoryModel(id: 3, name: 'Freelance', type: 'income', icon: 'laptop', color: '#6366F1'),
      CategoryModel(id: 4, name: 'Investments', type: 'income', icon: 'trending-up', color: '#06B6D4'),
      // Expense Categories
      CategoryModel(id: 5, name: 'Food', type: 'expense', icon: 'utensils', color: '#EF4444'),
      CategoryModel(id: 6, name: 'Transport', type: 'expense', icon: 'car', color: '#F43F5E'),
      CategoryModel(id: 7, name: 'Shopping', type: 'expense', icon: 'shopping-bag', color: '#EC4899'),
      CategoryModel(id: 8, name: 'Housing & Rent', type: 'expense', icon: 'home', color: '#F97316'),
      CategoryModel(id: 9, name: 'Entertainment', type: 'expense', icon: 'film', color: '#8B5CF6'),
      CategoryModel(id: 10, name: 'Utilities & Bills', type: 'expense', icon: 'zap', color: '#EAB308'),
      CategoryModel(id: 11, name: 'Health & Medical', type: 'expense', icon: 'heart', color: '#14B8A6'),
    ];
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
