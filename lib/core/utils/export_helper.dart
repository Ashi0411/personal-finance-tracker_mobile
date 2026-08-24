import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/report_model.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import 'formatters.dart';

class ExportHelper {
  /// Generate and print/download formatted PDF Financial Statement
  static Future<void> exportPdfReport({
    required FinancialReportModel report,
    required List<TransactionModel> transactions,
    required UserModel? user,
    required String currencySymbol,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header with Logo and Brand
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SpendWise Finance',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text('Personal Financial Statement & Summary', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated on: ${Formatters.date(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text('User: ${user?.fullName ?? "Valued User"}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text(user?.email ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.indigo200, height: 24),

            // Summary KPI Cards Grid
            pw.Row(
              children: [
                _buildKpiCard('Total Income', Formatters.currency(report.totalIncome, symbol: currencySymbol), PdfColors.green800, PdfColors.green50),
                pw.SizedBox(width: 10),
                _buildKpiCard('Total Expenses', Formatters.currency(report.totalExpense, symbol: currencySymbol), PdfColors.red800, PdfColors.red50),
                pw.SizedBox(width: 10),
                _buildKpiCard('Net Savings', Formatters.currency(report.netSavings, symbol: currencySymbol), PdfColors.indigo800, PdfColors.indigo50),
                pw.SizedBox(width: 10),
                _buildKpiCard('Savings Rate', Formatters.percentage(report.savingsRate), PdfColors.purple800, PdfColors.purple50),
              ],
            ),
            pw.SizedBox(height: 24),

            // Category Spending Breakdown
            pw.Text('Category Spending Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
            pw.SizedBox(height: 8),
            if (report.categoryBreakdowns.isEmpty)
              pw.Text('No spending recorded for this period.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
            else
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo600),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                headers: ['Category', 'Amount', 'Percentage Share'],
                data: report.categoryBreakdowns.map((cat) {
                  return [
                    cat.categoryName,
                    Formatters.currency(cat.totalAmount, symbol: currencySymbol),
                    '${cat.percentage.toStringAsFixed(1)}%',
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 24),

            // Itemized Transactions Log
            pw.Text('Recent Transactions Log (${transactions.length} Records)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
            pw.SizedBox(height: 8),
            if (transactions.isEmpty)
              pw.Text('No transactions recorded yet.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
            else
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                headers: ['Date', 'Description', 'Category', 'Type', 'Amount'],
                data: transactions.map((tx) {
                  final isIncome = tx.type.toLowerCase() == 'income';
                  return [
                    Formatters.dateShort(tx.transactionDate),
                    tx.description,
                    tx.categoryName,
                    isIncome ? 'Income' : 'Expense',
                    '${isIncome ? "+" : "-"}${Formatters.currency(tx.amount, symbol: currencySymbol)}',
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 30),
            pw.Center(
              child: pw.Text(
                'Generated automatically by SpendWise Mobile & Web App • Confidential Financial Record',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'SpendWise_Financial_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildKpiCard(String label, String value, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: textColor, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }

  /// Generate CSV Spreadsheet data string for transactions
  static String generateCsv(List<TransactionModel> transactions, String currencySymbol) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Date,Type,Category,Description,Amount ($currencySymbol),Created At');

    for (final tx in transactions) {
      final safeDesc = tx.description.replaceAll('"', '""');
      final safeCat = tx.categoryName.replaceAll('"', '""');
      buffer.writeln(
        '${tx.id},"${Formatters.date(tx.transactionDate)}",${tx.type.toUpperCase()},"safeCat","safeDesc",${tx.amount.toStringAsFixed(2)},"${tx.createdAt?.toIso8601String() ?? ""}"',
      );
    }

    return buffer.toString();
  }

  /// Trigger CSV download / share
  static Future<void> exportCsvReport(List<TransactionModel> transactions, String currencySymbol) async {
    final csvString = generateCsv(transactions, currencySymbol);
    final bytes = utf8.encode(csvString);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'SpendWise_Transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }
}
