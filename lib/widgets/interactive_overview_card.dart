import 'package:flutter/material.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction_model.dart';
import '../../widgets/category_icon_helper.dart';

class InteractiveOverviewCard extends StatefulWidget {
  final String title;
  final double amount;
  final String currency;
  final String emoji;
  final IconData icon;
  final Color primaryColor;
  final Color bgColor;
  final Color borderColor;
  final List<TransactionModel> transactions;
  final String monthName;
  final bool isDark;

  const InteractiveOverviewCard({
    super.key,
    required this.title,
    required this.amount,
    required this.currency,
    required this.emoji,
    required this.icon,
    required this.primaryColor,
    required this.bgColor,
    required this.borderColor,
    required this.transactions,
    required this.monthName,
    required this.isDark,
  });

  @override
  State<InteractiveOverviewCard> createState() => _InteractiveOverviewCardState();
}

class _InteractiveOverviewCardState extends State<InteractiveOverviewCard> {
  bool _isHovered = false;

  void _showDetailedModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header with icon and total
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widget.borderColor, width: 1.2),
                    ),
                    child: Text(widget.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${widget.monthName} • ${widget.transactions.length} Records',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.currency(widget.amount, symbol: widget.currency),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: widget.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                'Activity Log',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (widget.transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(widget.icon, size: 36, color: Colors.grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text(
                          'No records logged for ${widget.monthName}',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: widget.transactions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = widget.transactions[index];
                      final catColor = CategoryIconHelper.parseColor(tx.categoryColor);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            CategoryIconHelper.getIcon(tx.categoryIcon),
                            color: catColor,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          tx.description,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        subtitle: Text(
                          '${tx.categoryName} • ${Formatters.dateShort(tx.transactionDate)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Text(
                          Formatters.currency(tx.amount, symbol: widget.currency),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: widget.primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? widget.primaryColor : widget.borderColor,
            width: _isHovered ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: _isHovered ? 0.22 : 0.06),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDetailedModal(context),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Left: Emoji + Icon badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: widget.isDark ? 0.08 : 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widget.borderColor, width: 1),
                    ),
                    child: Text(widget.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),

                  // Center: Title & Tap for details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(widget.icon, color: widget.primaryColor, size: 14),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              'Tap for breakdown',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: widget.primaryColor.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, size: 12, color: widget.primaryColor.withValues(alpha: 0.8)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Right: Formatted Currency Amount
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Formatters.currency(widget.amount, symbol: widget.currency),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: widget.primaryColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
