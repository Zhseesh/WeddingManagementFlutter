import 'package:intl/intl.dart';
import 'package:weddingmanagementf/features/reports/data/report_models.dart';

class CsvExporter {
  static String generate(ReportData data) {
    final buffer = StringBuffer();
    final df = DateFormat('dd/MM/yyyy', 'id_ID');

    // Header
    buffer.writeln('Laporan Keuangan');
    buffer.writeln(
        'Periode,${df.format(data.filter.period.start)},'
        '${df.format(data.filter.period.end)}');
    buffer.writeln('Tipe,${data.filter.type ?? 'Semua'}');
    buffer.writeln('');

    // Summary
    buffer.writeln('RINGKASAN');
    buffer.writeln('Item,Nilai');
    buffer.writeln('Total Anggaran,${data.totalBudget}');
    buffer.writeln('Total Pemasukan,${data.totalIncome}');
    buffer.writeln('Total Pengeluaran,${data.totalExpense}');
    buffer.writeln('Sisa Anggaran,${data.remainingBudget}');
    buffer.writeln('Saldo Bersih,${data.netBalance}');
    buffer.writeln('');

    // Per category
    buffer.writeln('PER KATEGORI');
    buffer.writeln('Kategori,Total Pengeluaran,Jumlah Transaksi');
    for (final c in data.categories) {
      buffer.writeln('${_escape(c.name)},${c.total},${c.transactionCount}');
    }
    buffer.writeln('');

    // Vendors
    buffer.writeln('RINGKASAN VENDOR');
    buffer.writeln('Vendor,Harga Kesepakatan,Sudah Dibayar,Sisa');
    for (final v in data.vendors) {
      buffer.writeln(
          '${_escape(v.name)},${v.agreedPrice},${v.paid},${v.remaining}');
    }
    buffer.writeln('');

    // Installments
    buffer.writeln('RINGKASAN CICILAN');
    buffer.writeln('Nama,Total,Dibayar,Sisa');
    for (final i in data.installments) {
      buffer.writeln(
          '${_escape(i.name)},${i.totalAmount},${i.paid},${i.remaining}');
    }
    buffer.writeln('');

    // Transactions
    buffer.writeln('DAFTAR TRANSAKSI');
    buffer.writeln('Tanggal,Tipe,Nominal,Deskripsi,Metode,Status');
    for (final t in data.transactions) {
      final desc = _escape(t.description ?? t.source ?? '');
      final method = _escape(t.paymentMethod ?? '');
      buffer.writeln(
          '${df.format(t.transactionDate)},${t.type},${t.amount},'
          '$desc,$method,${t.status}');
    }

    return buffer.toString();
  }

  static String _escape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}