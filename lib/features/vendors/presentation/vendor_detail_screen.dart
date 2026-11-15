import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:weddingmanagementf/features/vendors/data/vendor_model.dart';
import 'package:weddingmanagementf/features/vendors/presentation/payment_form_sheet.dart';
import 'package:weddingmanagementf/features/vendors/presentation/providers/vendor_providers.dart';
import 'package:weddingmanagementf/features/vendors/presentation/vendor_form_sheet.dart';

class VendorDetailScreen extends ConsumerWidget {
  final int vendorId;
  const VendorDetailScreen({super.key, required this.vendorId});

  Future<void> _void(BuildContext context, WidgetRef ref, PaymentRecord p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void pembayaran?'),
        content: const Text('Transaksi terkait tidak dihapus, tetapi tidak dihitung sebagai pembayaran.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Void')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(vendorRepositoryProvider).voidPayment(p.transactionId);
    ref.invalidate(vendorDetailProvider(vendorId));
    ref.invalidate(vendorListProvider);
    ref.invalidate(transactionListProvider);
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(budgetSummaryProvider);
    ref.invalidate(categorySpendingProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.of(context);
    final async = ref.watch(vendorDetailProvider(vendorId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Vendor'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            tooltip: 'Edit vendor',
            onPressed: () {
              final detail = async.asData?.value;
              if (detail == null) return;
              showVendorFormSheet(context, initial: detail.summary.vendor);
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Vendor tidak ditemukan.'));
          }
          final s = detail.summary;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(summary: s),
              const SizedBox(height: 16),
              _InfoCard(vendor: s.vendor),
              const SizedBox(height: 20),
              Text(
                'Riwayat Pembayaran (${detail.payments.length})',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.ink),
              ),
              const SizedBox(height: 8),
              if (detail.payments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: palette.softBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text('Belum ada pembayaran.', style: TextStyle(color: palette.muted))),
                )
              else
                ...detail.payments.map((p) => _PaymentTile(
                      record: p,
                      onVoid: p.isVoid ? null : () => _void(context, ref, p),
                    )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: async.maybeWhen(
        data: (d) => d == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => showPaymentFormSheet(context, d.summary),
                icon: const Icon(LucideIcons.plus),
                label: const Text('Catat Pembayaran'),
              ),
        orElse: () => null,
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final VendorWithPayment summary;
  const _HeaderCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final pct = (summary.progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(summary.vendor.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Chip(
                label: Text(summary.vendor.statusEnum.label),
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(color: AppTheme.primary),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Sisa Tagihan', style: TextStyle(color: Colors.white, fontSize: 12)),
          Text(
            CurrencyFormatter.format(summary.remaining),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$pct% · Dibayar ${CurrencyFormatter.format(summary.totalPaid)} / ${CurrencyFormatter.format(summary.vendor.agreedPrice)}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final VendorModel vendor;
  const _InfoCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          if (vendor.contactName != null)
            ListTile(
              leading: const Icon(LucideIcons.user),
              title: const Text('Kontak'),
              subtitle: Text(vendor.contactName!),
            ),
          if (vendor.phone != null)
            ListTile(
              leading: const Icon(LucideIcons.phone),
              title: const Text('Telepon'),
              subtitle: Text(vendor.phone!),
            ),
          if (vendor.address != null)
            ListTile(
              leading: const Icon(LucideIcons.mapPin),
              title: const Text('Alamat'),
              subtitle: Text(vendor.address!),
            ),
          if (vendor.notes != null)
            ListTile(
              leading: const Icon(LucideIcons.stickyNote),
              title: const Text('Catatan'),
              subtitle: Text(vendor.notes!),
            ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentRecord record;
  final VoidCallback? onVoid;
  const _PaymentTile({required this.record, this.onVoid});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: record.isVoid ? palette.line : palette.softSuccess,
          child: Icon(LucideIcons.banknote,
              color: record.isVoid ? palette.muted : AppTheme.success),
        ),
        title: Text(
          CurrencyFormatter.format(record.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: palette.ink,
            decoration: record.isVoid ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${DateFormat('d MMM yyyy', 'id_ID').format(record.date)}'
          '${record.method != null ? ' · ${record.method}' : ''}'
          '${record.isVoid ? ' · VOID' : ''}',
          style: TextStyle(color: palette.muted),
        ),
        trailing: record.isVoid
            ? null
            : IconButton(
                icon: const Icon(LucideIcons.undo2, color: AppTheme.error),
                onPressed: onVoid,
              ),
      ),
    );
  }
}