import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction_model.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/category_icon_helper.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/hover_lift_card.dart';
import 'add_edit_transaction_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final txProvider = Provider.of<TransactionProvider>(context, listen: false);
      if (txProvider.transactions.isEmpty) {
        txProvider.fetchTransactions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTransactionSheet([TransactionModel? tx]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTransactionSheet(transactionToEdit: tx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final txProvider = Provider.of<TransactionProvider>(context);

    final filteredList = txProvider.filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => txProvider.fetchTransactions(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTransactionSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => txProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search transactions, note, category...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              txProvider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip('all', 'All', txProvider),
                    const SizedBox(width: 8),
                    _buildFilterChip('income', 'Income', txProvider, AppColors.income),
                    const SizedBox(width: 8),
                    _buildFilterChip('expense', 'Expenses', txProvider, AppColors.expense),
                  ],
                ),
              ],
            ),
          ),
          // Transactions List
          Expanded(
            child: txProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? EmptyStateView(
                        title: 'No Transactions Found',
                        description: 'Try modifying your search filter or add a new transaction.',
                        buttonText: 'Add First Record',
                        onButtonPressed: () => _openAddTransactionSheet(),
                      )
                    : RefreshIndicator(
                        onRefresh: () => txProvider.fetchTransactions(),
                        child: ListView.separated(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 90, top: 8),
                          itemCount: filteredList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final tx = filteredList[index];
                            final isIncome = tx.type.toLowerCase() == 'income';
                            final catColor = CategoryIconHelper.parseColor(tx.categoryColor);

                            return Dismissible(
                              key: ValueKey('tx_${tx.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.expense,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Transaction'),
                                    content: Text('Delete "${tx.description}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) {
                                txProvider.deleteTransaction(tx.id);
                              },
                                child: HoverLiftCard(
                                  liftOffset: -3,
                                  borderRadius: 18,
                                  glowColor: catColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                  onTap: () => _openAddTransactionSheet(tx),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          CategoryIconHelper.getIcon(tx.categoryIcon),
                                          color: catColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tx.description,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${tx.categoryName} • ${Formatters.dateShort(tx.transactionDate)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${isIncome ? '+' : '-'}${Formatters.currency(tx.amount, symbol: themeProvider.currencySymbol)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: isIncome ? const Color(0xFF059669) : const Color(0xFFE11D48),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () => _openAddTransactionSheet(tx),
                                                borderRadius: BorderRadius.circular(6),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(3),
                                                  child: Icon(Icons.edit_rounded, size: 15, color: isDark ? Colors.white60 : const Color(0xFF6366F1)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: const Text('Delete Transaction', style: TextStyle(fontWeight: FontWeight.w800)),
                                                      content: Text('Are you sure you want to delete "${tx.description}"?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(ctx, false),
                                                          child: const Text('Cancel'),
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBE123C)),
                                                          onPressed: () => Navigator.pop(ctx, true),
                                                          child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirm == true) {
                                                    await txProvider.deleteTransaction(tx.id);
                                                  }
                                                },
                                                borderRadius: BorderRadius.circular(6),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(3),
                                                  child: Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFE11D48)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label, TransactionProvider provider, [Color? activeColor]) {
    final isSelected = provider.filterType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activeColor ?? const Color(0xFF6366F1);

    return Expanded(
      child: HoverLiftCard(
        liftOffset: -2,
        borderRadius: 14,
        glowColor: color,
        onTap: () => provider.setFilterType(type),
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: isSelected ? color : (isDark ? const Color(0xFF1E293B) : Colors.white),
        border: Border.all(
          color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1.0,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
