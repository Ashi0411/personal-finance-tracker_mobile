import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction_model.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/category_icon_helper.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddEditTransactionSheet extends StatefulWidget {
  final TransactionModel? transactionToEdit;

  const AddEditTransactionSheet({super.key, this.transactionToEdit});

  @override
  State<AddEditTransactionSheet> createState() => _AddEditTransactionSheetState();
}

class _AddEditTransactionSheetState extends State<AddEditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final tx = widget.transactionToEdit;
    _type = tx?.type ?? 'expense';
    _amountController = TextEditingController(text: tx != null ? tx.amount.toStringAsFixed(2) : '');
    _descriptionController = TextEditingController(text: tx?.description ?? '');
    _selectedDate = tx?.transactionDate ?? DateTime.now();
    _selectedCategoryId = tx?.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    bool success;
    if (widget.transactionToEdit == null) {
      success = await txProvider.addTransaction(
        categoryId: _selectedCategoryId!,
        type: _type,
        amount: amount,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
      );
    } else {
      success = await txProvider.updateTransaction(
        id: widget.transactionToEdit!.id,
        categoryId: _selectedCategoryId!,
        type: _type,
        amount: amount,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
      );
    }

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transactionToEdit == null
                ? 'Transaction added successfully!'
                : 'Transaction updated successfully!',
          ),
          backgroundColor: AppColors.income,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(txProvider.errorMessage ?? 'Failed to save transaction'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    // Filter categories by selected type (income vs expense)
    final categories = txProvider.categories.where((c) => c.type.toLowerCase() == _type.toLowerCase()).toList();

    // Auto-select first matching category if current selection is invalid
    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    } else if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = categories.isNotEmpty ? categories.first.id : null;
    }

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.transactionToEdit == null ? 'Add New Transaction' : 'Edit Transaction',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Segmented Income/Expense Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _type = 'expense';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'expense' ? AppColors.expense : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Expense',
                            style: TextStyle(
                              color: _type == 'expense' ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _type = 'income';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'income' ? AppColors.income : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Income',
                            style: TextStyle(
                              color: _type == 'income' ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Amount Input
              CustomTextField(
                controller: _amountController,
                label: 'Amount (${themeProvider.currencySymbol})',
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.attach_money_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter amount';
                  final num = double.tryParse(val);
                  if (num == null || num <= 0) return 'Enter a valid amount > 0';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              // Description Input
              CustomTextField(
                controller: _descriptionController,
                label: 'Description / Note',
                hint: 'e.g. Grocery shopping at Walmart',
                prefixIcon: Icons.description_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Description is required';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              // Category Selection
              const Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (categories.isEmpty)
                const Text('No categories available', style: TextStyle(color: Colors.grey))
              else
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategoryId == cat.id;
                      final catColor = CategoryIconHelper.parseColor(cat.color);

                      return FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        avatar: Icon(
                          CategoryIconHelper.getIcon(cat.icon),
                          size: 16,
                          color: isSelected ? Colors.white : catColor,
                        ),
                        label: Text(
                          cat.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        backgroundColor: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                        selectedColor: catColor,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = cat.id;
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 18),
              // Date Picker
              const Text('Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        Formatters.date(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: widget.transactionToEdit == null ? 'Add Transaction' : 'Save Changes',
                icon: Icons.check_circle_outline_rounded,
                isLoading: txProvider.isLoading,
                onPressed: _saveTransaction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
