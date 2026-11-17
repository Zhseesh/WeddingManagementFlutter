import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/installments/data/installment_model.dart';
import 'package:weddingmanagementf/features/installments/presentation/installment_payment_form_sheet.dart';
import 'package:weddingmanagementf/features/installments/presentation/providers/installment_providers.dart';
import 'package:weddingmanagementf/features/transactions/presentation/providers/transaction_providers.dart';

class InstallmentDetailScreen extends ConsumerWidget {
  final int installmentId;
  const InstallmentDetailScreen({super.key, required this.installmentId});

  Future<void> _cancelInstallment(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan cicilan?'),
        content: const Text('Cicilan akan ditandai "Dibatalkan". Riwayat pembayaran tetap ada.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Batalkan')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(installmentRepositoryProvider).cancelInstallment(installmentId);
    ref.invalidate(installmentDetailProvider(installmentId));
    ref.invalidate(installmentListProvider);
  }

  Future<void> _voidPayment(BuildContext context, WidgetRef ref, InstallmentPaymentRecord p, int scheduleId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void pembayaran?'),
        content: const Text('Transaksi terkait tidak dihapus, tetapi tidak lagi dihitung.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Void')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(installmentRepositoryProvider).voidSchedulePayment(
      transactionId: p.transactionId,
      scheduleId: scheduleId,
      installmentId: installmentId,
    );
    ref.invalidate(installmentDetailProvider(installmentId));
    ref.invalidate(installmentListProvider);
    ref.invalidate(transactionListProvider);
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(budgetSummaryProvider);
    ref.invalidate(categorySpendingProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(installmentDetailProvider(installmentId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Cicilan'),
        actions: [
          async.maybeWhen(
            data: (d) => d == null
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(LucideIcons.circleX),
                    tooltip: 'Batalkan cicilan',
                    onPressed: d.summary.installment.status == 'cancelled' ? null : () => _cancelInstallment(context, ref),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) {
          if (detail == null) return const Center(child: Text('Cicilan tidak ditemukan.'));
          final s = detail.summary;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(summary: s),
              const SizedBox(height: 20),
              const Text('Termin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...detail.schedules.map((sw) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ScheduleTile(
                      sw: sw,
                      onPay: () => showInstallmentPaymentFormSheet(context, installmentId: installmentId, scheduleId: sw.schedule.id!),
                      onVoid: (payment) => _voidPayment(context, ref, payment, sw.schedule.id!),
                      canPay: s.installment.status != 'cancelled',
                    ),
                  )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final InstallmentWithSummary summary;
  const _HeaderCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final pct = (summary.progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, AppTheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(summary.installment.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              Chip(label: Text(summary.installment.statusLabel), backgroundColor: Colors.white, labelStyle:  TextStyle(color: Theme.of(context).colorScheme.primary), visualDensity: VisualDensity.compact),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Sisa Tagihan', style: TextStyle(color: Colors.white, fontSize: 12)),
          Text(CurrencyFormatter.format(summary.remaining), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: summary.progress, minHeight: 8, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white))),
          const SizedBox(height: 8),
          Text('$pct% · Dibayar ${CurrencyFormatter.format(summary.totalPaid)} / ${CurrencyFormatter.format(summary.installment.totalAmount)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final ScheduleWithPayments sw;
  final VoidCallback onPay;
  final void Function(InstallmentPaymentRecord) onVoid;
  final bool canPay;
  const _ScheduleTile({required this.sw, required this.onPay, required this.onVoid, required this.canPay});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final s = sw.schedule;
    final display = s.displayStatus;
    Color statusColor;
    switch (display) {
      case 'paid': statusColor = AppTheme.success; break;
      case 'overdue': statusColor = AppTheme.error; break;
      case 'partial': statusColor = Theme.of(context).colorScheme.primary; break;
      default: statusColor = palette.muted;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Termin ${s.sequenceNumber}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color.lerp(statusColor, palette.surface, 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(s.displayStatusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                ),
                const Spacer(),
                if (canPay && display != 'paid')
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, minimumSize: const Size(0, 32)),
                    onPressed: onPay,
                    child: const Text('Bayar', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Jatuh tempo: ${DateFormat('d MMM yyyy', 'id_ID').format(s.dueDate)}', style: TextStyle(fontSize: 11, color: palette.muted)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _amount('Total', s.amount, palette.ink, palette)),
                Expanded(child: _amount('Dibayar', sw.totalPaid, AppTheme.success, palette)),
                Expanded(child: _amount('Sisa', sw.remaining, sw.remaining > 0 ? AppTheme.error : palette.muted, palette)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: sw.progress, minHeight: 6, backgroundColor: palette.line)),
            if (sw.payments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: palette.line),
              const SizedBox(height: 6),
              ...sw.payments.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(LucideIcons.banknote, size: 16, color: p.isVoid ? palette.muted : AppTheme.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${CurrencyFormatter.format(p.amount)} · ${DateFormat('d MMM yyyy', 'id_ID').format(p.date)}${p.isVoid ? ' · VOID' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.ink,
                              decoration: p.isVoid ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (!p.isVoid) IconButton(icon: const Icon(LucideIcons.undo2, size: 16, color: AppTheme.error), visualDensity: VisualDensity.compact, onPressed: () => onVoid(p)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amount(String label, int value, Color color, AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: palette.muted)),
        Text(CurrencyFormatter.format(value), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}