import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/reports/data/report_models.dart';
import 'package:weddingmanagementf/features/reports/domain/csv_exporter.dart';
import 'package:weddingmanagementf/features/reports/domain/pdf_exporter.dart';
import 'package:weddingmanagementf/features/reports/presentation/providers/report_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final current = ref.read(reportFilterProvider).period;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDateRange: DateTimeRange(
        start: current.start,
        end: current.end,
      ),
    );
    if (picked == null) return;
    final period = ReportPeriod(
      start: DateTime(picked.start.year, picked.start.month, picked.start.day),
      end: DateTime(
          picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
    );
    ref.read(reportFilterProvider.notifier).state =
        ref.read(reportFilterProvider).withPeriod(period);
  }

  Future<void> _exportPdf(
    BuildContext context,
    WidgetRef ref,
    ReportData data,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Menyiapkan PDF...')),
    );
    try {
      final profile = await ref.read(activeWeddingProfileProvider.future);
      if (profile == null) return;
      final bytes = await PdfExporter.generate(
        data,
        partnerOne: profile.partnerOne,
        partnerTwo: profile.partnerTwo,
      );
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/laporan_$stamp.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Laporan Keuangan Pernikahan',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal export PDF: $e')),
      );
    }
  }

  Future<void> _exportCsv(
    BuildContext context,
    WidgetRef ref,
    ReportData data,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Menyiapkan CSV...')),
    );
    try {
      final csv = CsvExporter.generate(data);
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/laporan_$stamp.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Laporan Keuangan Pernikahan (CSV)',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal export CSV: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportDataProvider);
    final filter = ref.watch(reportFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: Column(
        children: [
          _FilterSection(
            filter: filter,
            onPickCustom: () => _pickCustomRange(context, ref),
          ),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (data) {
                if (data == null) {
                  return const Center(child: Text('Profil belum dibuat.'));
                }
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

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _periodChip(
                  'Bulan Ini',
                  _sameAs(filter.period, ReportPeriod.thisMonth()),
                  () => ref.read(reportFilterProvider.notifier).state =
                      filter.withPeriod(ReportPeriod.thisMonth()),
                ),
                const SizedBox(width: 6),
                _periodChip(
                  '3 Bulan',
                  _sameAs(filter.period, ReportPeriod.last3Months()),
                  () => ref.read(reportFilterProvider.notifier).state =
                      filter.withPeriod(ReportPeriod.last3Months()),
                ),
                const SizedBox(width: 6),
                _periodChip(
                  'Tahun Ini',
                  _sameAs(filter.period, ReportPeriod.thisYear()),
                  () => ref.read(reportFilterProvider.notifier).state =
                      filter.withPeriod(ReportPeriod.thisYear()),
                ),
                const SizedBox(width: 6),
                _periodChip(
                  isCustom
                      ? '${df.format(filter.period.start)} - ${df.format(filter.period.end)}'
                      : 'Custom',
                  isCustom,
                  onPickCustom,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int?>(
                  initialValue: filter.categoryId,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua'),
                    ),
                    ...catsAsync.maybeWhen(
                      data: (cats) => cats
                          .map((c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      orElse: () => const <DropdownMenuItem<int?>>[],
                    ),
                  ],
                  onChanged: (v) => ref
                      .read(reportFilterProvider.notifier)
                      .state = filter.withCategory(v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String?>(
                  initialValue: filter.type,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipe',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Semua')),
                    DropdownMenuItem(value: 'income', child: Text('Masuk')),
                    DropdownMenuItem(value: 'expense', child: Text('Keluar')),
                  ],
                  onChanged: (v) => ref
                      .read(reportFilterProvider.notifier)
                      .state = filter.withType(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
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

  const _ReportContent({
    required this.data,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final topCategoryTotal =
        data.categories.isEmpty ? 0 : data.categories.first.total;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pemasukan',
                value: CurrencyFormatter.format(data.totalIncome),
                color: const Color(0xFF22C55E),
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'Pengeluaran',
                value: CurrencyFormatter.format(data.totalExpense),
                color: scheme.error,
                icon: Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _StatCard(
          label: 'Saldo Bersih',
          value: CurrencyFormatter.format(data.netBalance),
          color: data.netBalance >= 0 ? scheme.primary : scheme.error,
          icon: Icons.savings,
          wide: true,
        ),
        const SizedBox(height: 16),

        if (data.totalBudget > 0) ...[
          const _SectionTitle(title: 'Anggaran vs Realisasi'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Total Anggaran',
                        style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    Text(CurrencyFormatter.format(data.totalBudget),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: data.budgetUsage,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Terpakai ${CurrencyFormatter.format(data.totalExpense)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      'Sisa ${CurrencyFormatter.format(data.remainingBudget)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: data.remainingBudget < 0
                                ? scheme.error
                                : null,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (data.categories.isNotEmpty) ...[
          const _SectionTitle(title: 'Pengeluaran per Kategori'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              children: data.categories.map((c) {
                final ratio = topCategoryTotal == 0
                    ? 0.0
                    : c.total / topCategoryTotal;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(c.name,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                          Text(CurrencyFormatter.format(c.total),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(scheme.primary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (data.vendors.isNotEmpty) ...[
          const _SectionTitle(title: 'Ringkasan Vendor'),
          ...data.vendors.take(10).map((v) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(v.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Text(CurrencyFormatter.format(v.remaining),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: v.remaining > 0
                                  ? scheme.error
                                  : scheme.tertiary,
                            )),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dibayar ${CurrencyFormatter.format(v.paid)} / '
                      '${CurrencyFormatter.format(v.agreedPrice)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],

        if (data.installments.isNotEmpty) ...[
          const _SectionTitle(title: 'Ringkasan Cicilan'),
          ...data.installments.take(10).map((i) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(i.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Text(CurrencyFormatter.format(i.remaining),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: i.remaining > 0
                                  ? scheme.error
                                  : scheme.tertiary,
                            )),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dibayar ${CurrencyFormatter.format(i.paid)} / '
                      '${CurrencyFormatter.format(i.totalAmount)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],

        const _SectionTitle(title: 'Export Laporan'),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onExportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: onExportCsv,
                icon: const Icon(Icons.table_chart),
                label: const Text('CSV'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool wide;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color.lerp(scheme.surface, color, 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}