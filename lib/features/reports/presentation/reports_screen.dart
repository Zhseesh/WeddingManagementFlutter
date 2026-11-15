import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/reports/data/report_models.dart';
import 'package:weddingmanagementf/features/reports/domain/csv_exporter.dart';
import 'package:weddingmanagementf/features/reports/domain/pdf_exporter.dart';
import 'package:weddingmanagementf/features/reports/presentation/providers/report_providers.dart';
import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final current = ref.read(reportFilterProvider).period;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDateRange: DateTimeRange(start: current.start, end: current.end),
    );
    if (picked == null) return;
    final period = ReportPeriod(
      start: DateTime(picked.start.year, picked.start.month, picked.start.day),
      end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
    );
    ref.read(reportFilterProvider.notifier).state =
        ref.read(reportFilterProvider).withPeriod(period);
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref, ReportData data) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Menyiapkan PDF...')));
    try {
      final profile = await ref.read(activeWeddingProfileProvider.future);
      if (profile == null) return;
      final bytes = await PdfExporter.generate(data, partnerOne: profile.partnerOne, partnerTwo: profile.partnerTwo);
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/laporan_$stamp.pdf');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: 'Laporan Keuangan Pernikahan',
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal export PDF: $e')));
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref, ReportData data) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Menyiapkan CSV...')));
    try {
      final csv = CsvExporter.generate(data);
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/laporan_$stamp.csv');
      await file.writeAsString(csv);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: 'Laporan Keuangan Pernikahan (CSV)',
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal export CSV: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.of(context);
    final async = ref.watch(reportDataProvider);
    final filter = ref.watch(reportFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Laporan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text('Ringkasan dan analisis keuangan',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: palette.muted)),
          ],
        ),
      ),
      body: Column(
        children: [
          _FilterSection(filter: filter, onPickCustom: () => _pickCustomRange(context, ref)),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (data) {
                if (data == null) return const Center(child: Text('Profil belum dibuat.'));
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(reportDataProvider);
                    await ref.read(reportDataProvider.future);
                  },
                  child: _ReportContent(
                    data: data,
                    onExportPdf: () => _exportPdf(context, ref, data),
                    onExportCsv: () => _exportCsv(context, ref, data),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends ConsumerWidget {
  final ReportFilter filter;
  final VoidCallback onPickCustom;
  const _FilterSection({required this.filter, required this.onPickCustom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final df = DateFormat('d MMM yy', 'id_ID');
    final catsAsync = ref.watch(budgetCategoriesProvider);
    final isCustom = !_sameAs(filter.period, ReportPeriod.thisMonth()) &&
        !_sameAs(filter.period, ReportPeriod.last3Months()) &&
        !_sameAs(filter.period, ReportPeriod.thisYear());
    final palette = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _periodChip('Bulan Ini', _sameAs(filter.period, ReportPeriod.thisMonth()),
                    () => ref.read(reportFilterProvider.notifier).state = filter.withPeriod(ReportPeriod.thisMonth())),
                const SizedBox(width: 6),
                _periodChip('3 Bulan', _sameAs(filter.period, ReportPeriod.last3Months()),
                    () => ref.read(reportFilterProvider.notifier).state = filter.withPeriod(ReportPeriod.last3Months())),
                const SizedBox(width: 6),
                _periodChip('Tahun Ini', _sameAs(filter.period, ReportPeriod.thisYear()),
                    () => ref.read(reportFilterProvider.notifier).state = filter.withPeriod(ReportPeriod.thisYear())),
                const SizedBox(width: 6),
                _periodChip(isCustom ? '${df.format(filter.period.start)} - ${df.format(filter.period.end)}' : 'Custom', isCustom, onPickCustom),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<int?>(
                  initialValue: filter.categoryId,
                  isDense: true,
                  borderRadius: BorderRadius.circular(16),
                  dropdownColor: palette.surface,
                  decoration: const InputDecoration(labelText: 'Kategori', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua')),
                    ...catsAsync.maybeWhen(
                      data: (cats) => cats.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))).toList(),
                      orElse: () => const <DropdownMenuItem<int?>>[],
                    ),
                  ],
                  onChanged: (v) => ref.read(reportFilterProvider.notifier).state = filter.withCategory(v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String?>(
                  initialValue: filter.type,
                  isDense: true,
                  borderRadius: BorderRadius.circular(16),
                  dropdownColor: palette.surface,
                  decoration: const InputDecoration(labelText: 'Tipe', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Semua')),
                    DropdownMenuItem(value: 'income', child: Text('Masuk')),
                    DropdownMenuItem(value: 'expense', child: Text('Keluar')),
                  ],
                  onChanged: (v) => ref.read(reportFilterProvider.notifier).state = filter.withType(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }

  static bool _sameAs(ReportPeriod a, ReportPeriod b) =>
      a.start.year == b.start.year &&
      a.start.month == b.start.month &&
      a.start.day == b.start.day &&
      a.end.year == b.end.year &&
      a.end.month == b.end.month &&
      a.end.day == b.end.day;
}

class _ReportContent extends StatelessWidget {
  final ReportData data;
  final VoidCallback onExportPdf;
  final VoidCallback onExportCsv;

  const _ReportContent({required this.data, required this.onExportPdf, required this.onExportCsv});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _StatsGrid(data: data),
        const SizedBox(height: 20),
        _DonutCard(data: data),
        const SizedBox(height: 20),
        _ExportCard(onExportPdf: onExportPdf, onExportCsv: onExportCsv),
        const SizedBox(height: 20),
        _TransactionDetails(data: data),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final ReportData data;
  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final items = [
      _StatItem(label: 'Pemasukan', value: CurrencyFormatter.format(data.totalIncome), icon: LucideIcons.arrowDown,
          color: AppTheme.success, bg: Color.lerp(AppTheme.success, palette.surface, 0.88)!),
      _StatItem(label: 'Pengeluaran', value: CurrencyFormatter.format(data.totalExpense), icon: LucideIcons.arrowUp,
          color: AppTheme.error, bg: Color.lerp(AppTheme.error, palette.surface, 0.88)!),
      _StatItem(label: 'Transaksi', value: '${data.transactions.length}', icon: LucideIcons.receipt,
          color: AppTheme.primary, bg: Color.lerp(AppTheme.primary, palette.surface, 0.88)!),
      _StatItem(label: 'Vendor Aktif', value: '${data.vendors.length}', icon: LucideIcons.store,
          color: AppTheme.tertiary, bg: Color.lerp(AppTheme.tertiary, palette.surface, 0.88)!),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final width = isWide ? (constraints.maxWidth - 12 * 3) / 4 : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((it) => SizedBox(width: width, child: _StatCard(item: it))).toList(),
        );
      },
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatItem({required this.label, required this.value, required this.icon, required this.color, required this.bg});
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
        boxShadow: [BoxShadow(color: palette.shadow, blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: item.bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: palette.muted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(item.value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: palette.ink)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  final ReportData data;
  const _DonutCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    if (data.categories.isEmpty || data.totalExpense == 0) {
      return const SizedBox.shrink();
    }

    final chartPalette = [
      AppTheme.primary,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.tertiary,
      AppTheme.error,
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
    ];

    List<CategoryBreakdown> displayCats;
    if (data.categories.length > 4) {
      final top = data.categories.take(4).toList();
      final rest = data.categories.skip(4).toList();
      final restTotal = rest.fold<int>(0, (a, b) => a + b.total);
      final restCount = rest.fold<int>(0, (a, b) => a + b.transactionCount);
      displayCats = [
        ...top,
        CategoryBreakdown(categoryId: null, name: 'Lainnya', total: restTotal, transactionCount: restCount),
      ];
    } else {
      displayCats = data.categories;
    }

    final sections = displayCats.asMap().entries.map((entry) {
      final i = entry.key;
      final c = entry.value;
      final pct = (c.total / data.totalExpense) * 100;
      return PieChartSectionData(
        value: c.total.toDouble(),
        color: chartPalette[i % chartPalette.length],
        title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: 24,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengeluaran per Kategori', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.ink)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 130,
                width: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 38,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatter.shortFormat(data.totalExpense),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: palette.ink),
                          ),
                        ),
                        Text('Total keluar', style: TextStyle(fontSize: 8, color: palette.muted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: displayCats.asMap().entries.map((entry) {
                    final i = entry.key;
                    final c = entry.value;
                    final pct = data.totalExpense == 0 ? 0.0 : (c.total / data.totalExpense) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: chartPalette[i % chartPalette.length], shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              c.name,
                              style: TextStyle(fontSize: 12, color: palette.ink, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: palette.ink),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final VoidCallback onExportPdf;
  final VoidCallback onExportCsv;
  const _ExportCard({required this.onExportPdf, required this.onExportCsv});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ekspor Laporan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.ink)),
          const SizedBox(height: 12),
          _row(icon: LucideIcons.fileText, title: 'Laporan PDF', subtitle: 'Ringkasan untuk dicetak', onTap: onExportPdf, palette: palette),
          Divider(height: 20, color: palette.line),
          _row(icon: LucideIcons.table, title: 'Data Transaksi CSV', subtitle: 'Untuk spreadsheet', onTap: onExportCsv, palette: palette),
        ],
      ),
    );
  }

  Widget _row({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, required AppPalette palette}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: palette.softPrimary, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: palette.muted)),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
            backgroundColor: palette.softPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Ekspor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _TransactionDetails extends StatelessWidget {
  final ReportData data;
  const _TransactionDetails({required this.data});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    if (data.transactions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Rincian Transaksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.ink)),
              const Spacer(),
              Text('${data.transactions.length} item', style: TextStyle(fontSize: 11, color: palette.muted)),
            ],
          ),
          const SizedBox(height: 12),
          ...data.transactions.map((tx) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TransactionRow(tx: tx),
          )),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final isIncome = tx.isIncome;
    final color = isIncome ? AppTheme.success : AppTheme.error;
    final sign = isIncome ? '+' : '-';
    final title = tx.description?.isNotEmpty == true ? tx.description! : (tx.source?.isNotEmpty == true ? tx.source! : (isIncome ? 'Pemasukan' : 'Pengeluaran'));
    final df = DateFormat('d MMM yyyy', 'id_ID');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.ink)),
              const SizedBox(height: 2),
              Text('${df.format(tx.transactionDate)}${tx.isVoid ? ' · VOID' : ''}', style: TextStyle(fontSize: 11, color: palette.muted)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$sign${CurrencyFormatter.format(tx.amount)}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}