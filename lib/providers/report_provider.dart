import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/report_model.dart';
import '../models/transaction_model.dart';

class ReportProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  FinancialReportModel _report = FinancialReportModel.empty();
  String _periodType = 'monthly'; // 'monthly', 'yearly'
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isLoading = false;
  String? _errorMessage;

  FinancialReportModel get report => _report;
  String get periodType => _periodType;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setPeriodType(String type) {
    _periodType = type;
    fetchReport();
  }

  void setYear(int year) {
    _selectedYear = year;
    fetchReport();
  }

  void setMonth(int month) {
    _selectedMonth = month;
    fetchReport();
  }

  Future<void> fetchReport({List<TransactionModel>? fallbackTransactions}) async {
    _setLoading(true);
    _errorMessage = null;

    if (_apiClient.isDemoMode) {
      _calculateFromTransactions(fallbackTransactions ?? []);
      _setLoading(false);
      return;
    }

    try {
      final response = await _apiClient.get(
        '/reports.php?period=$_periodType&year=$_selectedYear&month=$_selectedMonth',
      );

      if (response.success && response.data != null) {
        final data = response.data is Map<String, dynamic> ? response.data : <String, dynamic>{};
        final List catJson = data['category_spending'] ?? (data['categories'] ?? []);
        final List cfJson = data['monthly_cashflow'] ?? (data['cashflows'] ?? []);

        _report = FinancialReportModel(
          periodType: _periodType,
          periodValue: _periodType == 'monthly' ? '$_selectedYear-$_selectedMonth' : '$_selectedYear',
          totalIncome: (data['total_income'] as num?)?.toDouble() ?? 0.0,
          totalExpense: (data['total_expenses'] as num?)?.toDouble() ?? 0.0,
          netSavings: (data['net_savings'] as num?)?.toDouble() ?? 0.0,
          savingsRate: (data['savings_rate'] as num?)?.toDouble() ?? 0.0,
          categoryBreakdowns: catJson.map((c) => CategorySpendingSummary.fromJson(c)).toList(),
          cashflows: cfJson.map((cf) => MonthlyCashflowSummary.fromJson(cf)).toList(),
        );
      } else {
        _calculateFromTransactions(fallbackTransactions ?? []);
      }
    } catch (_) {
      _calculateFromTransactions(fallbackTransactions ?? []);
    }
    _setLoading(false);
  }

  void _calculateFromTransactions(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      _report = FinancialReportModel.empty();
      notifyListeners();
      return;
    }

    final filtered = transactions.where((tx) {
      if (_periodType == 'monthly') {
        return tx.transactionDate.year == _selectedYear && tx.transactionDate.month == _selectedMonth;
      }
      return tx.transactionDate.year == _selectedYear;
    }).toList();

    double income = 0.0;
    double expense = 0.0;
    final Map<int, CategorySpendingSummary> catMap = {};

    for (final tx in filtered) {
      if (tx.type.toLowerCase() == 'income') {
        income += tx.amount;
      } else {
        expense += tx.amount;
        if (catMap.containsKey(tx.categoryId)) {
          final existing = catMap[tx.categoryId]!;
          catMap[tx.categoryId] = CategorySpendingSummary(
            categoryName: existing.categoryName,
            totalAmount: existing.totalAmount + tx.amount,
            percentage: 0.0,
            color: existing.color,
            icon: existing.icon,
          );
        } else {
          catMap[tx.categoryId] = CategorySpendingSummary(
            categoryName: tx.categoryName,
            totalAmount: tx.amount,
            percentage: 0.0,
            color: tx.categoryColor,
            icon: tx.categoryIcon,
          );
        }
      }
    }

    final catList = catMap.values.map((cat) {
      final pct = expense > 0 ? (cat.totalAmount / expense) * 100 : 0.0;
      return CategorySpendingSummary(
        categoryName: cat.categoryName,
        totalAmount: cat.totalAmount,
        percentage: pct,
        color: cat.color,
        icon: cat.icon,
      );
    }).toList();

    _report = FinancialReportModel(
      periodType: _periodType,
      periodValue: _periodType == 'monthly' ? '$_selectedYear-$_selectedMonth' : '$_selectedYear',
      totalIncome: income,
      totalExpense: expense,
      netSavings: income - expense,
      savingsRate: income > 0 ? (((income - expense) / income) * 100).clamp(0.0, 100.0) : 0.0,
      categoryBreakdowns: catList,
      cashflows: [],
    );
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
