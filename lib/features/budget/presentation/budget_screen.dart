import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/data/budget_model.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  Future<void> _editTotal(
    BuildContext context,
    WidgetRef ref,
    BudgetModel budget,
  ) async {
    final ctrl = TextEditingController(
      text: CurrencyFormatter.format(budget.totalAmount).replaceAll('Rp ', ''),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Total Anggaran'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: 'Rp '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final newTotal = CurrencyFormatter.parse(ctrl.text);
    if (newTotal <= 0) return;
    await ref
        .read(budgetRepositoryProvider)
        .updateTotalAmount(budget.id!, newTotal);
    ref.invalidate(activeBudgetProvider);
    ref.invalidate(budgetSummaryProvider);
    ref.invalidate(categorySpendingProvider);
    ref.invalidate(dashboardDataProvider);
  }

  Future<void> _addCategory(
    BuildContext context,
    WidgetRef ref,
    int budgetId,
    int currentSortOrder,
  ) async {
    final nameCtrl = TextEditingController();
    final allocCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Wajib diisi'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: allocCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Alokasi',
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(budgetRepositoryProvider).createCategory(
            budgetId: budgetId,
            name: nameCtrl.text.trim(),
            allocatedAmount: CurrencyFormatter.parse(allocCtrl.text),
            sortOrder: currentSortOrder + 1,
          );
      ref.invalidate(categorySpendingProvider);
      ref.invalidate(budgetCategoriesProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: nama kategori mungkin sudah ada. $e')),
      );
    }
  }

  Future<void> _editAllocation(
    BuildContext context,
    WidgetRef ref,
    BudgetCategoryModel cat,
  ) async {
    final ctrl = TextEditingController(
      text: CurrencyFormatter.format(cat.allocatedAmount).replaceAll('Rp ', ''),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah Alokasi: ${cat.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: 'Rp '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(budgetRepositoryProvider)
        .updateCategoryAllocation(cat.id!, CurrencyFormatter.parse(ctrl.text));
    ref.invalidate(categorySpendingProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(budgetSummaryProvider);
    final budgetAsync = ref.watch(activeBudgetProvider);
    final spendingAsync = ref.watch(categorySpendingProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(budgetSummaryProvider);
        ref.invalidate(activeBudgetProvider);
        ref.invalidate(categorySpendingProvider);
        await ref.read(budgetSummaryProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          summaryAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (s) {
              if (s == null) return const SizedBox.shrink();
              return _SummaryCard(
                summary: s,
                onEdit: budgetAsync.maybeWhen(
                  data: (b) => b == null
                      ? null
                      : () => _editTotal(context, ref, b),
                  orElse: () => null,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Kategori',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              budgetAsync.maybeWhen(
                data: (b) => b == null
                    ? const SizedBox.shrink()
                    : TextButton.icon(
                        onPressed: () {
                          final cats = spendingAsync.asData?.value ?? const [];
                          _addCategory(context, ref, b.id!, cats.length);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Kategori'),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          spendingAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (cats) {
              if (cats.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Belum ada kategori.')),
                );
              }
              return Column(
                children: cats
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CategoryTile(
                            item: c,
                            onTap: () =>
                                _editAllocation(context, ref, c.category),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BudgetSummary summary;
  final VoidCallback? onEdit;
  const _SummaryCard({required this.summary, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = (summary.usagePercent * 100).round();
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
              Text(
                'Total Anggaran',
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit, color: scheme.onPrimary, size: 20),
                  tooltip: 'Ubah total',
                ),
            ],
          ),
          Text(
            CurrencyFormatter.format(summary.totalBudget),
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.usagePercent,
              minHeight: 8,
              backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Terpakai ${CurrencyFormatter.format(summary.totalExpense)} · $pct%',
                style: TextStyle(color: scheme.onPrimary, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Sisa ${CurrencyFormatter.format(summary.remaining)}',
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategorySpending item;
  final VoidCallback onTap;
  const _CategoryTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cat = item.category;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cat.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(cat.allocatedAmount),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Terpakai ${CurrencyFormatter.format(item.spent)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    item.remaining >= 0
                        ? 'Sisa ${CurrencyFormatter.format(item.remaining)}'
                        : 'Lebih ${CurrencyFormatter.format(-item.remaining)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: item.remaining < 0 ? scheme.error : null,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}