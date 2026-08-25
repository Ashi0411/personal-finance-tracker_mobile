import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/report_model.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import 'formatters.dart';

class ExportHelper {
  static String getStatementTitle(FinancialReportModel report) {
    final isMonthly = report.periodType.toLowerCase() == 'monthly';
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    if (isMonthly) {
      final parts = report.periodValue.split('-');
      if (parts.length >= 2) {
        final y = parts[0];
        final mIdx = (int.tryParse(parts[1]) ?? 1) - 1;
        final mName = (mIdx >= 0 && mIdx < 12) ? monthNames[mIdx] : parts[1];
        return 'Monthly Financial Statement - $mName $y';
      }
      return 'Monthly Financial Statement - ${report.periodValue}';
    } else {
      return 'Annual Financial Statement - Year ${report.periodValue}';
    }
  }

  /// Generate and print/download formatted PDF Financial Statement
  static Future<void> exportPdfReport({
    required FinancialReportModel report,
    required List<TransactionModel> transactions,
    required UserModel? user,
    required String currencySymbol,
  }) async {
    final pdf = pw.Document();
    final isMonthly = report.periodType.toLowerCase() == 'monthly';
    final nowFormatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // Filter transactions to strictly match the selected month or year
    final filteredTransactions = transactions.where((tx) {
      if (isMonthly) {
        final parts = report.periodValue.split('-');
        final y = int.tryParse(parts[0]) ?? tx.transactionDate.year;
        final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? tx.transactionDate.month;
        return tx.transactionDate.year == y && tx.transactionDate.month == m;
      } else {
        final y = int.tryParse(report.periodValue) ?? tx.transactionDate.year;
        return tx.transactionDate.year == y;
      }
    }).toList();

    if (!isMonthly) {
      // -------------------------------------------------------------
      // ANNUAL STATEMENT PDF TEMPLATE (Matching User Requested Design)
      // -------------------------------------------------------------
      final fullMonthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];

      final targetYear = int.tryParse(report.periodValue) ?? DateTime.now().year;

      // Compute 12-month progression
      final List<Map<String, dynamic>> monthlyProgression = [];
      for (int m = 1; m <= 12; m++) {
        double mIncome = 0;
        double mExpense = 0;
        int mCount = 0;
        for (final tx in transactions) {
          if (tx.transactionDate.year == targetYear && tx.transactionDate.month == m) {
            mCount++;
            if (tx.type.toLowerCase() == 'income') {
              mIncome += tx.amount;
            } else {
              mExpense += tx.amount;
            }
          }
        }
        monthlyProgression.add({
          'month': fullMonthNames[m - 1],
          'income': mIncome,
          'expense': mExpense,
          'net': mIncome - mExpense,
          'count': mCount,
        });
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FinanceTracker',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1E1B4B'),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Personal Wealth & Cash Flow Management',
                        style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#64748B')),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'ANNUAL STATEMENT',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#2563EB'),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Period: Full Year $targetYear',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                      ),
                      pw.Text(
                        'Generated: $nowFormatted',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        'Account Holder: ${user?.fullName ?? user?.email ?? "User"}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey300, height: 20),

              // KPI Header Cards (4 Columns)
              pw.Row(
                children: [
                  _buildAnnualStatCard(
                    'ANNUAL INCOME',
                    Formatters.currency(report.totalIncome, symbol: currencySymbol),
                    PdfColor.fromHex('#0F172A'),
                  ),
                  pw.SizedBox(width: 14),
                  _buildAnnualStatCard(
                    'ANNUAL EXPENSES',
                    Formatters.currency(report.totalExpense, symbol: currencySymbol),
                    PdfColor.fromHex('#0F172A'),
                  ),
                  pw.SizedBox(width: 14),
                  _buildAnnualStatCard(
                    'ANNUAL NET SAVINGS',
                    Formatters.currency(report.netSavings, symbol: currencySymbol),
                    PdfColor.fromHex('#2563EB'),
                  ),
                  pw.SizedBox(width: 14),
                  _buildAnnualStatCard(
                    'SAVINGS RATE',
                    '${report.savingsRate.toStringAsFixed(1)}%',
                    PdfColor.fromHex('#059669'),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // 12-Month Annual Progression Card
              pw.Container(
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 1),
                ),
                padding: const pw.EdgeInsets.all(14),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '12-Month Annual Progression',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1E1B4B'),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2.0),
                        1: const pw.FlexColumnWidth(2.2),
                        2: const pw.FlexColumnWidth(2.2),
                        3: const pw.FlexColumnWidth(2.2),
                        4: const pw.FlexColumnWidth(1.8),
                      },
                      children: [
                        // Table Header Row
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
                          ),
                          children: [
                            _buildTableHeader('MONTH', pw.Alignment.centerLeft),
                            _buildTableHeader('INCOME (${currencySymbol.toUpperCase()})', pw.Alignment.centerRight),
                            _buildTableHeader('EXPENSES (${currencySymbol.toUpperCase()})', pw.Alignment.centerRight),
                            _buildTableHeader('NET SAVINGS (${currencySymbol.toUpperCase()})', pw.Alignment.centerRight),
                            _buildTableHeader('TRANSACTIONS', pw.Alignment.centerRight),
                          ],
                        ),
                        // 12 Data Rows
                        ...monthlyProgression.map((item) {
                          final double inc = item['income'];
                          final double exp = item['expense'];
                          final double net = item['net'];
                          final int count = item['count'];

                          return pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5)),
                            ),
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                child: pw.Text(
                                  item['month'],
                                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B')),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                child: pw.Align(
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    Formatters.currency(inc, symbol: currencySymbol),
                                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2563EB')),
                                  ),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                child: pw.Align(
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    Formatters.currency(exp, symbol: currencySymbol),
                                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#DC2626')),
                                  ),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                child: pw.Align(
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    net >= 0
                                        ? '+ ${Formatters.currency(net, symbol: currencySymbol)}'
                                        : '- ${Formatters.currency(net.abs(), symbol: currencySymbol)}',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: net >= 0 ? PdfColor.fromHex('#059669') : PdfColor.fromHex('#DC2626'),
                                    ),
                                  ),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                child: pw.Align(
                                  alignment: pw.Alignment.centerRight,
                                  child: pw.Text(
                                    '$count entries',
                                    style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#64748B')),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              // Bottom Section: Expense Breakdown by Category
              pw.Container(
                width: 280,
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 1),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Expense Breakdown by Category',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1E1B4B'),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (report.categoryBreakdowns.isEmpty)
                      pw.Text('No expenses recorded for this year.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))
                    else
                      pw.Table(
                        columnWidths: {
                          0: const pw.FlexColumnWidth(2.5),
                          1: const pw.FlexColumnWidth(2.0),
                          2: const pw.FlexColumnWidth(1.5),
                        },
                        children: [
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.6)),
                            ),
                            children: [
                              _buildTableHeader('CATEGORY', pw.Alignment.centerLeft),
                              _buildTableHeader('AMOUNT (${currencySymbol.toUpperCase()})', pw.Alignment.centerRight),
                              _buildTableHeader('% OF TOTAL', pw.Alignment.centerRight),
                            ],
                          ),
                          ...report.categoryBreakdowns.map((cat) {
                            return pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                                  child: pw.Text(cat.categoryName, style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                                  child: pw.Align(
                                    alignment: pw.Alignment.centerRight,
                                    child: pw.Text(
                                      Formatters.currency(cat.totalAmount, symbol: currencySymbol),
                                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#DC2626')),
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                                  child: pw.Align(
                                    alignment: pw.Alignment.centerRight,
                                    child: pw.Text('${cat.percentage.toStringAsFixed(0)}%', style: const pw.TextStyle(fontSize: 8)),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Generated automatically by FinanceTracker • Confidential Financial Record',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ),
            ];
          },
        ),
      );
    } else {
      // -------------------------------------------------------------
      // MONTHLY STATEMENT PDF TEMPLATE
      // -------------------------------------------------------------
      final statementTitle = getStatementTitle(report);

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
                        'FinanceTracker',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E1B4B')),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#EEF2FF'),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Text(
                          statementTitle,
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#3730A3')),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Generated on: $nowFormatted', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('User: ${user?.fullName ?? user?.email ?? "User"}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
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
              pw.Text('Itemized Transactions Log (${filteredTransactions.length} Records)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
              pw.SizedBox(height: 8),
              if (filteredTransactions.isEmpty)
                pw.Text('No transactions recorded for this month.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
              else
                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                  rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  headers: ['Date', 'Description', 'Category', 'Type', 'Amount'],
                  data: filteredTransactions.map((tx) {
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
                  'Generated automatically by FinanceTracker • Confidential Financial Record',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ),
            ];
          },
        ),
      );
    }

    final titleForFile = isMonthly ? 'Monthly_Statement_${report.periodValue}' : 'Annual_Statement_${report.periodValue}';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'FinanceTracker_${titleForFile}.pdf',
    );
  }

  static pw.Widget _buildAnnualStatCard(String label, String value, PdfColor valueColor) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#64748B')),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text, pw.Alignment alignment) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Align(
        alignment: alignment,
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#64748B')),
        ),
      ),
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
  static String generateCsv(List<TransactionModel> transactions, String currencySymbol, [String? title]) {
    final buffer = StringBuffer();
    if (title != null && title.isNotEmpty) {
      buffer.writeln('# $title');
    }
    buffer.writeln('ID,Date,Type,Category,Description,Amount ($currencySymbol),Created At');

    for (final tx in transactions) {
      final safeDesc = tx.description.replaceAll('"', '""');
      final safeCat = tx.categoryName.replaceAll('"', '""');
      buffer.writeln(
        '${tx.id},"${Formatters.date(tx.transactionDate)}",${tx.type.toUpperCase()},"$safeCat","$safeDesc",${tx.amount.toStringAsFixed(2)},"${tx.createdAt?.toIso8601String() ?? ""}"',
      );
    }

    return buffer.toString();
  }

  /// Trigger CSV download / share
  static Future<void> exportCsvReport(List<TransactionModel> transactions, String currencySymbol, [String? title]) async {
    final csvString = generateCsv(transactions, currencySymbol, title);
    final bytes = utf8.encode(csvString);
    final cleanTitle = (title ?? 'Transactions').replaceAll(' ', '_').replaceAll('-', '_');
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'FinanceTracker_${cleanTitle}.csv',
    );
  }
}
