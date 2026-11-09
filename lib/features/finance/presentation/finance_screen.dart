import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/budget_screen.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/installments/presentation/installment_form_sheet.dart';
import 'package:weddingmanagementf/features/installments/presentation/installment_list_screen.dart';
import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';
import 'package:weddingmanagementf/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:weddingmanagementf/features/transactions/presentation/transaction_form_sheet.dart';

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

  void _onAdd() {
    if (_tab.index == 1) {
      showTransactionFormSheet(context);
    } else if (_tab.index == 2) {
      showInstallmentFormSheet(context);
    }
  }

  static const _fabLabels = ['', 'Transaksi', 'Cicilan'];

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Keuangan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              'Anggaran, transaksi, dan cicilan',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (dashboardAsync.hasValue) _FinanceStats(data: dashboardAsync.value!),
          if (dashboardAsync.hasValue) const SizedBox(height: 16),
          TabBar(
            controller: _tab,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.muted,
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Anggaran'),
              Tab(text: 'Transaksi'),
              Tab(text: 'Cicilan'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                BudgetScreen(),
                _TransactionTab(),
                InstallmentListScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tab.index > 0
          ? FloatingActionButton.extended(
              onPressed: _onAdd,
              icon: const Icon(Icons.add),
              label: Text(_fabLabels[_tab.index]),
            )
          : null,
    );
  }
}

class _FinanceStats extends StatelessWidget {
  final dynamic data; 
  const _FinanceStats({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = [
      _FinanceStatItem(
        label: 'Anggaran',
        value: CurrencyFormatter.format(data.totalBudget),
        icon: Icons.account_balance_wallet_outlined,
        color: AppTheme.primary,
        bg: Color.lerp(AppTheme.primary, Colors.white, 0.88)!,
      ),
      _FinanceStatItem(
        label: 'Pemasukan',
        value: CurrencyFormatter.format(data.totalIncome),
        icon: Icons.arrow_downward,
        color: AppTheme.success,
        bg: Color.lerp(AppTheme.success, Colors.white, 0.88)!,
      ),
      _FinanceStatItem(
        label: 'Pengeluaran',
        value: CurrencyFormatter.format(data.totalPaid),
        icon: Icons.arrow_upward,
        color: AppTheme.error,
        bg: Color.lerp(AppTheme.error, Colors.white, 0.88)!,
      ),
      _FinanceStatItem(
        label: 'Sisa',
        value: CurrencyFormatter.format(data.remainingBudget),
        icon: Icons.savings_outlined,
        color: AppTheme.tertiary,
        bg: Color.lerp(AppTheme.tertiary, Colors.white, 0.88)!,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final width = isWide
              ? (constraints.maxWidth - 12 * 3) / 4
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items
                .map((it) => SizedBox(
                      width: width,
                      child: _FinanceStatCard(item: it),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _FinanceStatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _FinanceStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _FinanceStatCard extends StatelessWidget {
  final _FinanceStatItem item;
  const _FinanceStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF30206B).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: item.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Semua'),
                selected: filter == null,
                onSelected: (_) => ref
                    .read(transactionTypeFilterProvider.notifier)
                    .state = null,
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Masuk'),
                selected: filter == 'income',
                onSelected: (_) => ref
                    .read(transactionTypeFilterProvider.notifier)
                    .state = 'income',
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Keluar'),
                selected: filter == 'expense',
                onSelected: (_) => ref
                    .read(transactionTypeFilterProvider.notifier)
                    .state = 'expense',
              ),
            ],
          ),
        ),
        Expanded(
          child: listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada transaksi.',
                    style: TextStyle(color: AppTheme.muted),
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
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppTheme.line),
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
    final isIncome = tx.isIncome;
    final color = isIncome ? AppTheme.success : AppTheme.error;
    final sign = isIncome ? '+' : '-';
    final title = tx.description?.isNotEmpty == true
        ? tx.description!
        : (tx.source?.isNotEmpty == true
            ? tx.source!
            : (isIncome ? 'Pemasukan' : 'Pengeluaran'));
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color.lerp(color, Colors.white, 0.85),
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
          size: 18,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.ink,
        ),
      ),
      subtitle: Text(
        '${DateFormat('d MMM yyyy', 'id_ID').format(tx.transactionDate)}${tx.isVoid ? ' · VOID' : ''}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Text(
        '$sign${CurrencyFormatter.format(tx.amount)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}