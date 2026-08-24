import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
      customPattern: '$symbol #,##0.00',
    );
    return formatter.format(amount);
  }

  static String compactCurrency(double amount, {String symbol = '\$'}) {
    if (amount.abs() >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  static String date(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String dateShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String monthYearShort(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  static String percentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}
