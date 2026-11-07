import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:weddingmanagementf/features/vendors/data/vendor_model.dart';
import 'package:weddingmanagementf/features/vendors/presentation/payment_form_screen.dart';
import 'package:weddingmanagementf/features/vendors/presentation/providers/vendor_providers.dart';

class VendorDetailScreen extends ConsumerWidget {
  final int vendorId;
  const VendorDetailScreen({super.key, required this.vendorId});

  Future<void> _voidPayment(
    BuildContext context,
    WidgetRef ref,
    PaymentRecord p,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void pembayaran?'),
        content: const Text(
          'Transaksi terkait tidak dihapus, tetapi tidak akan dihitung '
          'sebagai pembayaran vendor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Void'),
          ),
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
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pembayaran di-void.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vendorDetailProvider(vendorId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Vendor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit vendor',
            onPressed: () {
              final detail = async.asData?.value;
              if (detail == null) return;
              context.push(
                '/preparation/vendor/edit',
                extra: detail.summary.vendor,
              );
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
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(summary: s),
              const SizedBox(height: 16),
              _InfoCard(vendor: s.vendor),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Riwayat Pembayaran',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${detail.payments.length} entri',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (detail.payments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Belum ada pembayaran.'),
                  ),
                )
              else
                Column(
                  children: detail.payments
                      .map((p) => _PaymentTile(
                            record: p,
                            onVoid: p.isVoid
                                ? null
                                : () => _voidPayment(context, ref, p),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: async.maybeWhen(
        data: (detail) => detail == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PaymentFormScreen(summary: detail.summary),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
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
    final scheme = Theme.of(context).colorScheme;
    final pct = (summary.progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
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
                child: Text(
                  summary.vendor.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(
                label: Text(summary.vendor.statusEnum.label),
                backgroundColor: scheme.onPrimary,
                labelStyle: TextStyle(color: scheme.primary),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sisa Tagihan',
            style: TextStyle(color: scheme.onPrimary, fontSize: 12),
          ),
          Text(
            CurrencyFormatter.format(summary.remaining),
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.progress,
              minHeight: 8,
              backgroundColor: Color.lerp(
                scheme.primary,
                scheme.onPrimary,
                0.7,
              ),
              valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$pct% · Dibayar ${CurrencyFormatter.format(summary.totalPaid)} / '
            '${CurrencyFormatter.format(summary.vendor.agreedPrice)}',
            style: TextStyle(color: scheme.onPrimary, fontSize: 12),
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
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          if (vendor.contactName != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Kontak'),
              subtitle: Text(vendor.contactName!),
            ),
          if (vendor.phone != null)
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Telepon'),
              subtitle: Text(vendor.phone!),
            ),
          if (vendor.address != null)
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Alamat'),
              subtitle: Text(vendor.address!),
            ),
          if (vendor.bookingDate != null)
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Tanggal Booking'),
              subtitle: Text(
                DateFormat('d MMM yyyy', 'id_ID').format(vendor.bookingDate!),
              ),
            ),
          if (vendor.eventDate != null)
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Tanggal Acara'),
              subtitle: Text(
                DateFormat('d MMM yyyy', 'id_ID').format(vendor.eventDate!),
              ),
            ),
          if (vendor.notes != null)
            ListTile(
              leading: const Icon(Icons.notes),
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: record.isVoid
              ? scheme.surfaceContainerHighest
              : Color.lerp(scheme.surface, scheme.tertiary, 0.15),
          child: Icon(
            Icons.payments_outlined,
            color: record.isVoid ? scheme.onSurfaceVariant : scheme.tertiary,
          ),
        ),
        title: Text(
          CurrencyFormatter.format(record.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: record.isVoid ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${DateFormat('d MMM yyyy', 'id_ID').format(record.date)}'
          '${record.method != null ? ' · ${record.method}' : ''}'
          '${record.isVoid ? ' · VOID' : ''}',
        ),
        trailing: record.isVoid
            ? null
            : IconButton(
                icon: Icon(Icons.undo, color: scheme.error),
                tooltip: 'Void',
                onPressed: onVoid,
              ),
      ),
    );
  }
}