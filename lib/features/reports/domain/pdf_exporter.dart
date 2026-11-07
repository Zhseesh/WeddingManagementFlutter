import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/reports/data/report_models.dart';

class PdfExporter {
  static Future<Uint8List> generate(
    ReportData data, {
    required String partnerOne,
    required String partnerTwo,
  }) async {
    final doc = pw.Document();
    final df = DateFormat('dd/MM/yyyy', 'id_ID');

    pw.Widget sectionTitle(String title) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
          child: pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          ),
        );

    pw.Widget kv(String k, String v) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(k, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(v,
                  style: const pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Laporan Keuangan Pernikahan',
                    style: const pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('$partnerOne & $partnerTwo',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Periode: ${df.format(data.filter.period.start)} - '
                  '${df.format(data.filter.period.end)}'
                  '${data.filter.type != null ? ' · ${data.filter.type == 'income' ? 'Pemasukan' : 'Pengeluaran'}' : ''}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),

          // Summary
          sectionTitle('Ringkasan'),
          kv('Total Anggaran', CurrencyFormatter.format(data.totalBudget)),
          kv('Total Pemasukan', CurrencyFormatter.format(data.totalIncome)),
          kv('Total Pengeluaran', CurrencyFormatter.format(data.totalExpense)),
          kv('Sisa Anggaran', CurrencyFormatter.format(data.remainingBudget)),
          kv('Saldo Bersih', CurrencyFormatter.format(data.netBalance)),

          // Categories
          if (data.categories.isNotEmpty) ...[
            sectionTitle('Pengeluaran per Kategori'),
            pw.TableHelper.fromTextArray(
              headers: ['Kategori', 'Total', 'Transaksi'],
              data: data.categories
                  .map((c) => [
                        c.name,
                        CurrencyFormatter.format(c.total),
                        c.transactionCount.toString(),
                      ])
                  .toList(),
              headerStyle: const pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
              },
            ),
          ],

          // Vendors
          if (data.vendors.isNotEmpty) ...[
            sectionTitle('Ringkasan Vendor'),
            pw.TableHelper.fromTextArray(
              headers: ['Vendor', 'Kesepakatan', 'Dibayar', 'Sisa'],
              data: data.vendors
                  .map((v) => [
                        v.name,
                        CurrencyFormatter.format(v.agreedPrice),
                        CurrencyFormatter.format(v.paid),
                        CurrencyFormatter.format(v.remaining),
                      ])
                  .toList(),
              headerStyle: const pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),
          ],

          // Installments
          if (data.installments.isNotEmpty) ...[
            sectionTitle('Ringkasan Cicilan'),
            pw.TableHelper.fromTextArray(
              headers: ['Nama', 'Total', 'Dibayar', 'Sisa'],
              data: data.installments
                  .map((i) => [
                        i.name,
                        CurrencyFormatter.format(i.totalAmount),
                        CurrencyFormatter.format(i.paid),
                        CurrencyFormatter.format(i.remaining),
                      ])
                  .toList(),
              headerStyle: const pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),
          ],

          // Transactions
          if (data.transactions.isNotEmpty) ...[
            sectionTitle('Daftar Transaksi'),
            pw.TableHelper.fromTextArray(
              headers: ['Tanggal', 'Tipe', 'Nominal', 'Deskripsi', 'Status'],
              data: data.transactions
                  .map((t) => [
                        df.format(t.transactionDate),
                        t.type == 'income' ? 'Masuk' : 'Keluar',
                        CurrencyFormatter.format(t.amount),
                        t.description ?? t.source ?? '',
                        t.status == 'posted' ? 'Posted' : 'VOID',
                      ])
                  .toList(),
              headerStyle: const pw.TextStyle(
                  fontSize: 8, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
              },
            ),
          ],

          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.Text(
            'Dicetak pada ${DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return doc.save();
  }
}