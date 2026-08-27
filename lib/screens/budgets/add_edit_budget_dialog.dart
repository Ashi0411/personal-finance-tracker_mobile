import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/category_icon_helper.dart';
import '../../widgets/custom_text_field.dart';

class AddEditBudgetDialog extends StatefulWidget {
  final BudgetModel? budgetToEdit;
  final String monthYear;

  const AddEditBudgetDialog({
    super.key,
    this.budgetToEdit,
    required this.monthYear,
  });

  @override
  State<AddEditBudgetDialog> createState() => _AddEditBudgetDialogState();
}

class _AddEditBudgetDialogState extends State<AddEditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.budgetToEdit != null ? widget.budgetToEdit!.allocatedAmount.toStringAsFixed(2) : '',
    );
    _selectedCategoryId = widget.budgetToEdit?.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expense category'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    final category = txProvider.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => CategoryModel(id: _selectedCategoryId!, name: 'Category', type: 'expense'),
    );

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    final success = await budgetProvider.setBudget(
      category: category,
      allocatedAmount: amount,
      monthYear: widget.monthYear,
      fallbackTransactions: txProvider.transactions,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved successfully! 🎉'), backgroundColor: AppColors.income),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(budgetProvider.errorMessage ?? 'Failed to save budget'), backgroundColor: AppColors.expense),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProvider = Provider.of<TransactionProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final expenseCategories = txProvider.categories.where((c) => c.type.toLowerCase() == 'expense').toList();

    if (_selectedCategoryId == null && expenseCategories.isNotEmpty) {
      _selectedCategoryId = expenseCategories.first.id;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Text(
        widget.budgetToEdit == null ? 'Set Category Budget' : 'Update Budget Limit',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.budgetToEdit == null) ...[
                const Text(
                  'Expense Category',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  isExpanded: true,
                  dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 12,
                  menuMaxHeight: 320,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF6366F1),
                    size: 22,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 1.5,
                      ),
                    ),
                  ),
                  selectedItemBuilder: (context) {
                    return expenseCategories.map((cat) {
                      final catColor = CategoryIconHelper.parseColor(cat.color);
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CategoryIconHelper.getIcon(cat.icon),
                              color: catColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                  items: expenseCategories.map((cat) {
                    final catColor = CategoryIconHelper.parseColor(cat.color);
                    return DropdownMenuItem<int>(
                      value: cat.id,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CategoryIconHelper.getIcon(cat.icon),
                              color: catColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoryId = val;
                    });
                  },
                ),
                const SizedBox(height: 18),
              ],
              CustomTextField(
                controller: _amountController,
                label: 'Monthly Limit (${themeProvider.currencySymbol})',
                hint: '15000.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Limit amount is required';
                  final num = double.tryParse(val);
                  if (num == null || num <= 0) return 'Enter a valid amount > 0';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: budgetProvider.isLoading ? null : _saveBudget,
          child: const Text('Save Budget', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
