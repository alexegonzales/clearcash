import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'models/money_tx.dart';

/// Builds CSV and PDF files from the transactions and opens the share sheet.
class ExportService {
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // ------------------------------------------------------------ helpers

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _date(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static String _csvField(String v) => '"${v.replaceAll('"', '""')}"';

  /// The built-in PDF font has no peso sign, so the PDF uses "PHP".
  static String _php(int cents) {
    final neg = cents < 0;
    final abs = cents.abs();
    final whole = (abs ~/ 100).toString();
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return '${neg ? '-' : ''}PHP $buf.${_two(abs % 100)}';
  }

  /// The built-in PDF font only knows basic Latin letters.
  static String _safe(String v) =>
      String.fromCharCodes(v.runes.map((c) => c <= 255 ? c : 63)); // 63 = "?"

  static List<MoneyTx> _oldestFirst(Iterable<MoneyTx> items) {
    final list = items.toList()
      ..sort((a, b) {
        final c = a.date.compareTo(b.date);
        return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
      });
    return list;
  }

  // ---------------------------------------------------------------- CSV

  static String buildCsv(List<MoneyTx> items) {
    final b = StringBuffer('\uFEFF'); // helps Excel read the file correctly
    b.writeln('Date,Type,Category,Note,Amount (PHP)');
    for (final t in _oldestFirst(items)) {
      b.writeln(
        [
          _date(t.date),
          t.isIncome ? 'Income' : 'Expense',
          _csvField(t.category),
          _csvField(t.note),
          (t.cents / 100).toStringAsFixed(2),
        ].join(','),
      );
    }
    return b.toString();
  }

  static Future<void> shareCsv(List<MoneyTx> items) async {
    final bytes = Uint8List.fromList(utf8.encode(buildCsv(items)));
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'text/csv',
            name: 'clearcash_transactions.csv',
          ),
        ],
        fileNameOverrides: const ['clearcash_transactions.csv'],
        subject: 'ClearCash transactions',
      ),
    );
  }

  // ---------------------------------------------------------------- PDF

  static pw.Widget _summaryBox(String label, String value) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.2)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    ),
  );

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    bool right = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Align(
      alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    ),
  );

  static Future<Uint8List> buildPdf(List<MoneyTx> all, DateTime month) async {
    final items = _oldestFirst(
      all.where(
        (t) => t.date.year == month.year && t.date.month == month.month,
      ),
    );

    var income = 0;
    var expense = 0;
    final byCategory = <String, int>{};
    for (final t in items) {
      if (t.isIncome) {
        income += t.cents;
      } else {
        expense += t.cents;
        byCategory[t.category] = (byCategory[t.category] ?? 0) + t.cents;
      }
    }
    final categories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'ClearCash Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('${_months[month.month - 1]} ${month.year}'),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              _summaryBox('Income', _php(income)),
              pw.SizedBox(width: 10),
              _summaryBox('Expenses', _php(expense)),
              pw.SizedBox(width: 10),
              _summaryBox('Net', _php(income - expense)),
            ],
          ),
          if (categories.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Spending by category',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            for (final c in categories)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${_safe(c.key)}  (${(c.value * 100 / expense).round()}%)',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      _php(c.value),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
          ],
          pw.SizedBox(height: 20),
          pw.Text(
            'Transactions',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (items.isEmpty)
            pw.Text('No transactions this month.')
          else
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(62),
                1: const pw.FixedColumnWidth(70),
                2: const pw.FlexColumnWidth(),
                3: const pw.FixedColumnWidth(95),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell('Date', bold: true),
                    _cell('Category', bold: true),
                    _cell('Note', bold: true),
                    _cell('Amount', bold: true, right: true),
                  ],
                ),
                for (final t in items)
                  pw.TableRow(
                    children: [
                      _cell(_date(t.date)),
                      _cell(_safe(t.category)),
                      _cell(_safe(t.note)),
                      _cell(
                        '${t.isIncome ? '+' : '-'}${_php(t.cents)}',
                        right: true,
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<void> sharePdf(List<MoneyTx> all, DateTime month) async {
    final bytes = await buildPdf(all, month);
    final name = 'clearcash_report_${month.year}-${_two(month.month)}.pdf';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: name)],
        fileNameOverrides: [name],
        subject: 'ClearCash report',
      ),
    );
  }
}
