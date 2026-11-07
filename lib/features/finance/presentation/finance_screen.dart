import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/budget_screen.dart';
import 'package:weddingmanagementf/features/installments/presentation/installment_list_screen.dart';
import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';
import 'package:weddingmanagementf/features/transactions/presentation/providers/transaction_providers.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Widget? _buildFab(BuildContext context) {
    if (_tab.index == 0) {
      return FloatingActionButton.extended(
        onPressed: () => context.push('/finance/transaction/new'),
        icon: const Icon(Icons.add),
        label: const Text('Transaksi'),
      );
    }
    if (_tab.index == 2) {
      return FloatingActionButton.extended(
        onPressed: () => context.push('/finance/installment/new'),
        icon: const Icon(Icons.add),
        label: const Text('Cicilan'),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Transaksi'),
            Tab(text: 'Anggaran'),
            Tab(text: 'Cicilan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _TransactionTab(),
          BudgetScreen(),
          InstallmentListScreen(),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }
}

class _TransactionTab extends ConsumerWidget {
  const _TransactionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(transactionListProvider);
    final filter = ref.watch(transactionTypeFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<String?>(
            segments: const [
              ButtonSegment(value: null, label: Text('Semua')),
              ButtonSegment(value: 'income', label: Text('Masuk')),
              ButtonSegment(value: 'expense', label: Text('Keluar')),
            ],
            selected: {filter},
            onSelectionChanged: (s) {
              ref.read(transactionTypeFilterProvider.notifier).state = s.first;
            },
          ),
        ),
        Expanded(
          child: listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Belum ada transaksi.\nTekan tombol + untuk menambah.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(transactionListProvider);
                  await ref.read(transactionListProvider.future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => _TransactionTile(tx: items[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIncome = tx.isIncome;
    final color = isIncome ? const Color(0xFF22C55E) : scheme.error;
    final sign = isIncome ? '+' : '-';
    final title = tx.description?.isNotEmpty == true
        ? tx.description!
        : (tx.source?.isNotEmpty == true
            ? tx.source!
            : (isIncome ? 'Pemasukan' : 'Pengeluaran'));
    return ListTile(
      onTap: () => context.push('/finance/transaction/${tx.id}'),
      leading: CircleAvatar(
        backgroundColor: Color.lerp(scheme.surface, color, 0.15),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: tx.isVoid ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        '${DateFormat('d MMM yyyy', 'id_ID').format(tx.transactionDate)}'
        '${tx.isVoid ? ' · VOID' : ''}',
      ),
      trailing: Text(
        '$sign${CurrencyFormatter.format(tx.amount)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          decoration: tx.isVoid ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}