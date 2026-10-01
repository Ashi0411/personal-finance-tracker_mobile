import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/goal_model.dart';
import '../../providers/goal_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/custom_text_field.dart';

class QuickDepositDialog extends StatefulWidget {
  final GoalModel goal;

  const QuickDepositDialog({super.key, required this.goal});

  @override
  State<QuickDepositDialog> createState() => _QuickDepositDialogState();
}

class _QuickDepositDialogState extends State<QuickDepositDialog> {
  final _amountController = TextEditingController();
  bool _deductFromBalance = true;
  bool _isSubmitting = false;

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

    setState(() => _isSubmitting = true);

    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final success = await goalProvider.addDeposit(goalId: widget.goal.id, depositAmount: amount);

    if (success && _deductFromBalance) {
      // Find or create "Savings & Goals" category to record expense and deduct from monthly balance
      final savingsCategory = await txProvider.getOrCreateSavingsCategory();
      await txProvider.addTransaction(
        categoryId: savingsCategory.id,
        type: 'expense',
        amount: amount,
        description: 'Goal Deposit: ${widget.goal.name}',
        date: DateTime.now(),
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _deductFromBalance
                ? 'Deposited ${Formatters.currency(amount, symbol: themeProvider.currencySymbol)} into ${widget.goal.name} & deducted from monthly balance!'
                : 'Deposited ${Formatters.currency(amount, symbol: themeProvider.currencySymbol)} into ${widget.goal.name}!',
          ),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.savings_rounded, color: Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deposit to ${widget.goal.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Remaining: ${Formatters.currency(widget.goal.remainingAmount, symbol: themeProvider.currencySymbol)}',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _amountController,
              label: 'Deposit Amount (${themeProvider.currencySymbol})',
              hint: '1000.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('+500'),
                  onPressed: () => _addQuickAmount(500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                ActionChip(
                  label: const Text('+1,000'),
                  onPressed: () => _addQuickAmount(1000),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                ActionChip(
                  label: const Text('+5,000'),
                  onPressed: () => _addQuickAmount(5000),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                ActionChip(
                  label: const Text('+10,000'),
                  onPressed: () => _addQuickAmount(10000),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _deductFromBalance,
                activeThumbColor: const Color(0xFF10B981),
                onChanged: (val) => setState(() => _deductFromBalance = val),
                title: const Text(
                  'Deduct from Monthly Balance',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Records as a savings transaction to deduct from monthly income/funds',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitDeposit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Confirm Deposit', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
