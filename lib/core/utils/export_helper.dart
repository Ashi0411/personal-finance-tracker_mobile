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
        return '$mName $y';
      }
      return report.periodValue;
    } else {
      return 'Full Year ${report.periodValue}';
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
    final periodLabel = getStatementTitle(report);

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
      // ANNUAL STATEMENT PDF TEMPLATE (12-Month Annual Progression)
      // -------------------------------------------------------------
      final fullMonthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];

      final targetYear = int.tryParse(report.periodValue) ?? DateTime.now().year;

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
                        'Period: $periodLabel',
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
      // MONTHLY STATEMENT PDF TEMPLATE (Matching Modern Container Design)
      // -------------------------------------------------------------
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
                        'MONTHLY STATEMENT',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#2563EB'),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Period: $periodLabel',
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
                    'MONTHLY INCOME',
                    Formatters.currency(report.totalIncome, symbol: currencySymbol),
                    PdfColor.fromHex('#0F172A'),
                  ),
                  pw.SizedBox(width: 14),
                  _buildAnnualStatCard(
                    'MONTHLY EXPENSES',
                    Formatters.currency(report.totalExpense, symbol: currencySymbol),
                    PdfColor.fromHex('#0F172A'),
                  ),
                  pw.SizedBox(width: 14),
                  _buildAnnualStatCard(
                    'MONTHLY NET SAVINGS',
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

              // Itemized Transactions Log Card (Modern Container Box matching Annual progression)
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
                      'Itemized Transactions Log (${filteredTransactions.length} Records)',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1E1B4B'),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    if (filteredTransactions.isEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 12),
                        child: pw.Text('No transactions recorded for this month.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      )
                    else
                      pw.Table(
                        columnWidths: {
                          0: const pw.FlexColumnWidth(1.6),
                          1: const pw.FlexColumnWidth(3.0),
                          2: const pw.FlexColumnWidth(2.4),
                          3: const pw.FlexColumnWidth(1.6),
                          4: const pw.FlexColumnWidth(2.2),
                        },
                        children: [
                          // Table Header Row
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
                            ),
                            children: [
                              _buildTableHeader('DATE', pw.Alignment.centerLeft),
                              _buildTableHeader('DESCRIPTION', pw.Alignment.centerLeft),
                              _buildTableHeader('CATEGORY', pw.Alignment.centerLeft),
                              _buildTableHeader('TYPE', pw.Alignment.centerLeft),
                              _buildTableHeader('AMOUNT (${currencySymbol.toUpperCase()})', pw.Alignment.centerRight),
                            ],
                          ),
                          // Data Rows
                          ...filteredTransactions.map((tx) {
                            final isIncome = tx.type.toLowerCase() == 'income';
                            return pw.TableRow(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5)),
                              ),
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                  child: pw.Text(
                                    Formatters.dateShort(tx.transactionDate),
                                    style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('#475569')),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                  child: pw.Text(
                                    tx.description,
                                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B')),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                  child: pw.Text(
                                    tx.categoryName,
                                    style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('#334155')),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                  child: pw.Text(
                                    isIncome ? 'Income' : 'Expense',
                                    style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: isIncome ? PdfColor.fromHex('#059669') : PdfColor.fromHex('#DC2626'),
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                                  child: pw.Align(
                                    alignment: pw.Alignment.centerRight,
                                    child: pw.Text(
                                      '${isIncome ? "+" : "-"}${Formatters.currency(tx.amount, symbol: currencySymbol)}',
                                      style: pw.TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: isIncome ? PdfColor.fromHex('#059669') : PdfColor.fromHex('#DC2626'),
                                      ),
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
                      pw.Text('No expenses recorded for this month.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))
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
