import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/data/budget_model.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  Future<void> _addCategory(BuildContext context, WidgetRef ref, int budgetId, int currentSortOrder) async {
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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: allocCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Alokasi', prefixText: 'Rp '),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) Navigator.pop(ctx, true);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _editAllocation(BuildContext context, WidgetRef ref, BudgetCategoryModel cat) async {
    final palette = AppTheme.of(context);
    final ctrl = TextEditingController(text: CurrencyFormatter.format(cat.allocatedAmount).replaceAll('Rp ', ''));

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final keyboardPadding = MediaQuery.viewInsetsOf(ctx).bottom;
        final safeAreaPadding = MediaQuery.paddingOf(ctx).bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: keyboardPadding),
          child: Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + safeAreaPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Kategori: ${cat.name}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.ink)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Alokasi', prefixText: 'Rp '),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, 'delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          minimumSize: const Size(0, 46),
                        ),
                        child: const Text('Hapus'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, 'save'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
                        child: const Text('Simpan Perubahan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted) return;

    if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus kategori?'),
          content: const Text('Transaksi di kategori ini akan menjadi "Tanpa Kategori".'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref.read(budgetRepositoryProvider).deleteCategory(cat.id!);
        ref.invalidate(categorySpendingProvider);
        ref.invalidate(budgetCategoriesProvider);
        ref.invalidate(dashboardDataProvider);
      }
    } else if (action == 'save') {
      await ref.read(budgetRepositoryProvider).updateCategoryAllocation(cat.id!, CurrencyFormatter.parse(ctrl.text));
      ref.invalidate(categorySpendingProvider);
      ref.invalidate(dashboardDataProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.of(context);
    final budgetAsync = ref.watch(activeBudgetProvider);
    final spendingAsync = ref.watch(categorySpendingProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeBudgetProvider);
        ref.invalidate(categorySpendingProvider);
        await ref.read(categorySpendingProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Row(
            children: [
              Text('Kategori',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.ink)),
              const Spacer(),
              budgetAsync.maybeWhen(
                data: (b) => b == null ? const SizedBox.shrink() : TextButton.icon(
                  onPressed: () {
                    final cats = spendingAsync.asData?.value ?? const [];
                    _addCategory(context, ref, b.id!, cats.length);
                  },
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Kategori', style: TextStyle(fontSize: 12)),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          spendingAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
            data: (cats) {
              if (cats.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Belum ada kategori.',
                      style: TextStyle(color: palette.muted),
                    ),
                  ),
                );
              }
              return Column(
                children: cats.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CategoryTile(item: c, onTap: () => _editAllocation(context, ref, c.category)),
                )).toList(),
              );
            },
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
    final palette = AppTheme.of(context);
    final cat = item.category;
    final color = cat.color != null
        ? Color(int.parse('FF${cat.color!.replaceFirst('#', '')}', radix: 16))
        : AppTheme.primary;

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
                    child: Text(cat.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.ink)),
                  ),
                  Text(CurrencyFormatter.format(cat.allocatedAmount),
                      style: TextStyle(fontSize: 12, color: palette.ink)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 6,
                    backgroundColor: palette.line,
                    valueColor: AlwaysStoppedAnimation(color)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('Terpakai ${CurrencyFormatter.format(item.spent)}',
                      style: TextStyle(fontSize: 11, color: palette.muted)),
                  const Spacer(),
                  Text(
                    item.remaining >= 0
                        ? 'Sisa ${CurrencyFormatter.format(item.remaining)}'
                        : 'Lebih ${CurrencyFormatter.format(-item.remaining)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: item.remaining < 0
                            ? AppTheme.error
                            : palette.muted),
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