import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'month_year_picker_popup.dart';

class MonthYearPickerBar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final bool isDark;
  final Color primaryColor;

  const MonthYearPickerBar({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.isDark,
    this.primaryColor = const Color(0xFF2563EB),
  });

  void _changeMonth(int delta) {
    var newMonth = selectedDate.month + delta;
    var newYear = selectedDate.year;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    onDateChanged(DateTime(newYear, newMonth, 1));
  }

  void _changeYear(int delta) {
    onDateChanged(DateTime(selectedDate.year + delta, selectedDate.month, 1));
  }

  Future<void> _pickCustomMonth(BuildContext context) async {
    final pickedDate = await MonthYearPickerPopup.show(context, selectedDate);
    if (pickedDate != null) {
      onDateChanged(pickedDate);
    }
  }

  Widget _buildArrowButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Icon(
              icon,
              size: 15,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Double Arrow Left (-1 Year)
          _buildArrowButton(
            icon: Icons.keyboard_double_arrow_left_rounded,
            tooltip: '-1 Year',
            onTap: () => _changeYear(-1),
          ),
          const SizedBox(width: 2),
          // Single Arrow Left (-1 Month)
          _buildArrowButton(
            icon: Icons.chevron_left_rounded,
            tooltip: '-1 Month',
            onTap: () => _changeMonth(-1),
          ),
          const SizedBox(width: 4),
          // Current Selected Month Pill (Tap to open month/year picker popup)
          InkWell(
            onTap: () => _pickCustomMonth(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Single Arrow Right (+1 Month)
          _buildArrowButton(
            icon: Icons.chevron_right_rounded,
            tooltip: '+1 Month',
            onTap: () => _changeMonth(1),
          ),
          const SizedBox(width: 2),
          // Double Arrow Right (+1 Year)
          _buildArrowButton(
            icon: Icons.keyboard_double_arrow_right_rounded,
            tooltip: '+1 Year',
            onTap: () => _changeYear(1),
          ),
        ],
      ),
    );
  }
}
