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
  bool _isPressed = false;

  bool get _isBalanceCard =>
      widget.emoji == '💎' ||
      widget.title.toLowerCase().contains('saving') ||
      widget.title.toLowerCase().contains('balance') ||
      widget.title.contains('ඉතිරිකිරීම්') ||
      widget.title.contains('ශේෂය');

  void _showDetailedModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
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

              // Header with Icon and Total Amount
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widget.borderColor, width: 1.2),
                    ),
                    child: Text(widget.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          widget.monthName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Formatters.currency(widget.amount, symbol: widget.currency),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: widget.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // If Balance Card: Show ONLY Net Balance Overview without mixing Income & Expense
              if (_isBalanceCard) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: widget.bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: widget.borderColor, width: 1.4),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, size: 36, color: widget.primaryColor),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Total Net Balance (${widget.monthName})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Formatters.currency(widget.amount, symbol: widget.currency),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: widget.primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: (widget.amount >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.amount >= 0 ? '✓ Positive Cash Balance' : '⚠ Cash Deficit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: widget.amount >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ] else ...[
                // Income or Expense Records List
                Text(
                  'Itemized Activity Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
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
                      separatorBuilder: (_, _) => Divider(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final tx = widget.transactions[index];
                        final catColor = CategoryIconHelper.parseColor(tx.categoryColor);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            '${tx.categoryName} • ${Formatters.dateShort(tx.transactionDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
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
              ],

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
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
    final isElevated = _isPressed || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, isElevated ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isElevated ? widget.primaryColor : widget.borderColor,
            width: isElevated ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: isElevated ? 0.28 : 0.08),
              blurRadius: isElevated ? 20 : 8,
              offset: Offset(0, isElevated ? 8 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onHighlightChanged: (val) => setState(() => _isPressed = val),
            onTap: () => _showDetailedModal(context),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Header with Emoji, Icon, Full Title, and "Tap for details >" Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: widget.isDark ? 0.1 : 0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: widget.borderColor, width: 1),
                        ),
                        child: Text(widget.emoji, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(widget.icon, color: widget.primaryColor, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tap Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: widget.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, size: 12, color: widget.primaryColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Prominent Large Formatted Amount (100% Unclipped)
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      Formatters.currency(widget.amount, symbol: widget.currency),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: widget.primaryColor,
                        letterSpacing: -0.5,
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
