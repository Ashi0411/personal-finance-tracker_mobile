import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../providers/budget_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/custom_text_field.dart';

class AddEditBudgetDialog extends StatefulWidget {
  final BudgetModel? budgetToEdit;

  const AddEditBudgetDialog({super.key, this.budgetToEdit});

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
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved successfully!'), backgroundColor: AppColors.income),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(budgetProvider.errorMessage ?? 'Failed to save budget'), backgroundColor: AppColors.expense),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final expenseCategories = txProvider.categories.where((c) => c.type.toLowerCase() == 'expense').toList();

    if (_selectedCategoryId == null && expenseCategories.isNotEmpty) {
      _selectedCategoryId = expenseCategories.first.id;
    }

    return AlertDialog(
      title: Text(widget.budgetToEdit == null ? 'Set Category Budget' : 'Update Budget Limit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.budgetToEdit == null) ...[
                const Text('Expense Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  items: expenseCategories.map((cat) {
                    return DropdownMenuItem<int>(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoryId = val;
                    });
                  },
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              CustomTextField(
                controller: _amountController,
                label: 'Monthly Limit (${themeProvider.currencySymbol})',
                hint: '500.00',
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: budgetProvider.isLoading ? null : _saveBudget,
          child: const Text('Save Budget'),
        ),
      ],
    );
  }
}
