import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_text_field.dart';

class AddGoalDialog extends StatefulWidget {
  final GoalModel? goalToEdit;

  const AddGoalDialog({super.key, this.goalToEdit});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _amountController;
  late DateTime _targetDate;
  late String _selectedIcon;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goalToEdit?.name ?? '');
    _targetAmountController = TextEditingController(
      text: widget.goalToEdit != null ? widget.goalToEdit!.targetAmount.toStringAsFixed(2) : '',
    );
    _amountController = TextEditingController(
      text: widget.goalToEdit != null
          ? widget.goalToEdit!.currentAmount.toStringAsFixed(2)
          : '0.00',
    );
    _targetDate = widget.goalToEdit?.targetDate ?? DateTime.now().add(const Duration(days: 90));
    _selectedIcon = widget.goalToEdit?.icon ?? 'target';
    _selectedColor = widget.goalToEdit?.color ?? '#8B5CF6';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final targetAmount = double.tryParse(_targetAmountController.text) ?? 0.0;
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    bool success;
    if (widget.goalToEdit != null) {
      success = await goalProvider.updateGoal(
        id: widget.goalToEdit!.id,
        name: _nameController.text.trim(),
        targetAmount: targetAmount,
        currentAmount: amount,
        targetDate: _targetDate,
        icon: _selectedIcon,
        color: _selectedColor,
      );
    } else {
      success = await goalProvider.addGoal(
        name: _nameController.text.trim(),
        targetAmount: targetAmount,
        initialAmount: amount,
        targetDate: _targetDate,
        icon: _selectedIcon,
        color: _selectedColor,
      );
    }

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.goalToEdit != null ? 'Savings goal updated! 🎉' : 'Savings goal created! 🎉'),
          backgroundColor: AppColors.income,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(goalProvider.errorMessage ?? 'Failed to save goal'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final goalProvider = Provider.of<GoalProvider>(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Text(
        widget.goalToEdit == null ? 'New Savings Goal' : 'Edit Savings Goal',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Goal Name / Purpose',
                hint: 'e.g. Dream Vacation Trip',
                prefixIcon: Icons.track_changes_rounded,
                validator: (val) => val == null || val.trim().isEmpty ? 'Goal name is required' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _targetAmountController,
                label: 'Target Amount (${themeProvider.currencySymbol})',
                hint: '50000.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Target amount required';
                  final n = double.tryParse(val);
                  if (n == null || n <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _amountController,
                label: widget.goalToEdit != null
                    ? 'Current Saved Balance (${themeProvider.currencySymbol})'
                    : 'Initial Starting Balance (${themeProvider.currencySymbol})',
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 14),
              const Text('Target Completion Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6366F1)),
                      const SizedBox(width: 10),
                      Text(Formatters.date(_targetDate), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
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
          onPressed: goalProvider.isLoading ? null : _saveGoal,
          child: Text(
            widget.goalToEdit == null ? 'Create Goal' : 'Update Goal',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
