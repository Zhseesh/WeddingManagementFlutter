import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';
import 'package:weddingmanagementf/features/transactions/presentation/providers/transaction_providers.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final int transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  Future<void> _void(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void transaksi?'),
        content: const Text(
          'Transaksi tidak akan dihapus, tetapi tidak lagi dihitung '
          'dalam ringkasan dan laporan.',
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
    if (confirm != true) return;

    await ref.read(transactionRepositoryProvider).voidTransaction(tx.id!);
    ref.invalidate(transactionListProvider);
    ref.invalidate(transactionByIdProvider(transactionId));
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(budgetSummaryProvider);
    ref.invalidate(categorySpendingProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi di-void.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transactionByIdProvider(transactionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tx) {
          if (tx == null) {
            return const Center(child: Text('Transaksi tidak ditemukan.'));
          }
          final scheme = Theme.of(context).colorScheme;
          final isIncome = tx.isIncome;
          final color = isIncome ? AppTheme.success : scheme.error;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color.lerp(scheme.surface, color, 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncome
                            ? LucideIcons.arrowDown
                            : LucideIcons.arrowUp,
                        color: color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isIncome ? 'Pemasukan' : 'Pengeluaran',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(tx.amount),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (tx.isVoid) ...[
                      const SizedBox(height: 8),
                      Chip(
                        label: const Text('VOID'),
                        backgroundColor: scheme.errorContainer,
                        labelStyle: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    _row(context, 'Tanggal',
                        DateFormat('d MMMM yyyy', 'id_ID').format(tx.transactionDate)),
                    _row(context, 'Metode', tx.paymentMethod ?? '—'),
                    if (tx.source != null) _row(context, 'Sumber/Penerima', tx.source!),
                    if (tx.description != null)
                      _row(context, 'Deskripsi', tx.description!),
                    _row(
                      context,
                      'Status',
                      tx.isPosted ? 'Posted' : 'Void',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (tx.isPosted)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.errorContainer,
                    foregroundColor: scheme.onErrorContainer,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () => _void(context, ref, tx),
                  child: const Text('Void Transaksi'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return ListTile(
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}