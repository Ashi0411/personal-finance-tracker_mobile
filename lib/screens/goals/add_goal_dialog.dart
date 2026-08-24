import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/goal_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_text_field.dart';

class AddGoalDialog extends StatefulWidget {
  const AddGoalDialog({super.key});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _initialAmountController = TextEditingController(text: '0.00');
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  final String _selectedIcon = 'target';
  final String _selectedColor = '#8B5CF6';

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _initialAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
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
    final initialAmount = double.tryParse(_initialAmountController.text) ?? 0.0;

    final success = await goalProvider.addGoal(
      name: _nameController.text.trim(),
      targetAmount: targetAmount,
      initialAmount: initialAmount,
      targetDate: _targetDate,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Savings goal created!'), backgroundColor: AppColors.income),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(goalProvider.errorMessage ?? 'Failed to create goal'), backgroundColor: AppColors.expense),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final goalProvider = Provider.of<GoalProvider>(context);

    return AlertDialog(
      title: const Text('New Savings Goal'),
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
                hint: '3000.00',
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
                controller: _initialAmountController,
                label: 'Initial Starting Balance (${themeProvider.currencySymbol})',
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 14),
              const Text('Target Completion Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.darkBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16),
                      const SizedBox(width: 10),
                      Text(Formatters.date(_targetDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: goalProvider.isLoading ? null : _saveGoal,
          child: const Text('Create Goal'),
        ),
      ],
    );
  }
}
