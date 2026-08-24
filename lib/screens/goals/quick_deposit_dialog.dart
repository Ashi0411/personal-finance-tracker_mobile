import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_text_field.dart';

class QuickDepositDialog extends StatefulWidget {
  final GoalModel goal;

  const QuickDepositDialog({super.key, required this.goal});

  @override
  State<QuickDepositDialog> createState() => _QuickDepositDialogState();
}

class _QuickDepositDialogState extends State<QuickDepositDialog> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addQuickAmount(double amount) {
    final current = double.tryParse(_amountController.text) ?? 0.0;
    _amountController.text = (current + amount).toStringAsFixed(0);
  }

  Future<void> _submitDeposit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid deposit amount'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final success = await goalProvider.addDeposit(goalId: widget.goal.id, depositAmount: amount);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deposited ${Formatters.currency(amount)} into ${widget.goal.name}!'),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.savings_rounded, color: AppColors.savings, size: 24),
          const SizedBox(width: 10),
          Expanded(child: Text('Deposit to ${widget.goal.name}', style: const TextStyle(fontSize: 16))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Remaining to Target: ${Formatters.currency(widget.goal.remainingAmount, symbol: themeProvider.currencySymbol)}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _amountController,
            label: 'Deposit Amount (${themeProvider.currencySymbol})',
            hint: '100.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [
              ActionChip(label: const Text('+25'), onPressed: () => _addQuickAmount(25)),
              ActionChip(label: const Text('+50'), onPressed: () => _addQuickAmount(50)),
              ActionChip(label: const Text('+100'), onPressed: () => _addQuickAmount(100)),
              ActionChip(label: const Text('+250'), onPressed: () => _addQuickAmount(250)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submitDeposit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.savings),
          child: const Text('Confirm Deposit'),
        ),
      ],
    );
  }
}
