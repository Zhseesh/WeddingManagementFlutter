import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/providers/navigation_providers.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/dashboard/data/dashboard_data.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.of(context);
    final async = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Beranda',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text('Wedding Planner & Finance',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: palette.muted)),
          ],
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(dashboardDataProvider),
        ),
        data: (data) {
          if (data == null) return const _EmptyView();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardDataProvider);
              await ref.read(dashboardDataProvider.future);
            },
            child: _DashboardContent(data: data),
          );
        },
      ),
    );
  }
}

// Helper untuk pindah tab
void _goToTab(WidgetRef ref, {required int mainTab, int? prepSubTab, int? financeSubTab}) {
  ref.read(mainTabProvider.notifier).state = mainTab;
  if (prepSubTab != null) ref.read(prepTabProvider.notifier).state = prepSubTab;
  if (financeSubTab != null) ref.read(financeTabProvider.notifier).state = financeSubTab;
}

class _DashboardContent extends ConsumerWidget {
  final DashboardData data;
  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _HeroCard(data: data),
        const SizedBox(height: 16),
        _StatsGrid(data: data),
        const SizedBox(height: 20),
        _SectionHead(
          title: 'Ringkasan Anggaran',
          actionLabel: 'Lihat detail',
          onAction: () => _goToTab(ref, mainTab: 2, financeSubTab: 0),
        ),
        const SizedBox(height: 8),
        _CategoryList(categories: data.categories),
        const SizedBox(height: 20),
        _SectionHead(
          title: 'Aktivitas Terbaru',
          actionLabel: 'Semua',
          onAction: () => _goToTab(ref, mainTab: 2, financeSubTab: 1),
        ),
        const SizedBox(height: 8),
        _RecentTransactionsList(items: data.recentTransactions),
        const SizedBox(height: 20),
        const _SectionHead(title: 'Akses Cepat'),
        const SizedBox(height: 8),
        const _QuickActionsGrid(),
      ],
    );
  }
}

// ============================================================
// Hero Countdown
// ============================================================

class _HeroCard extends StatelessWidget {
  final DashboardData data;
  const _HeroCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final days = data.daysToWedding;
    final isPast = days < 0;
    final isToday = days == 0;
    final df = DateFormat('d MMMM yyyy', 'id_ID');
    final dateText = data.profile.weddingDate != null
        ? df.format(data.profile.weddingDate!)
        : 'Tanggal belum diatur';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppTheme.primary, palette.surface, 0.88)!,
            Color.lerp(AppTheme.primary, palette.surface, 0.94)!,
            palette.surface,
          ],
        ),
        border: Border.all(
            color: Color.lerp(AppTheme.primary, palette.surface, 0.75)!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPast
                      ? 'SELAMAT MENEMPUH HIDUP BARU'
                      : isToday
                          ? 'HARI BAHAGIA TELAH TIBA'
                          : 'MENUJU HARI BAHAGIA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.muted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                if (!isPast && !isToday) ...[
                  const Text(
                    '',
                    style: TextStyle(fontSize: 36),
                  ),
                  Text(
                    '$days',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Hari lagi menuju pernikahan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                ] else
                  Text(
                    isPast ? 'Selamat!' : 'Hari ini!',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  '${data.profile.partnerOne} & ${data.profile.partnerTwo} · $dateText',
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
          Icon(
            Icons.favorite,
            size: 56,
            color: Color.lerp(AppTheme.primary, palette.surface, 0.55),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Stats 2x2
// ============================================================

class _StatsGrid extends StatelessWidget {
  final DashboardData data;
  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final percent = data.budgetPercent;
    final items = [
      _StatItem(
        label: 'Total Anggaran',
        value: CurrencyFormatter.format(data.totalBudget),
        icon: Icons.account_balance_wallet_outlined,
        color: AppTheme.primary,
        bg: Color.lerp(AppTheme.primary, palette.surface, 0.88)!,
      ),
      _StatItem(
        label: 'Total Terbayar',
        value: CurrencyFormatter.format(data.totalPaid),
        icon: Icons.check_circle_outline,
        color: AppTheme.success,
        bg: Color.lerp(AppTheme.success, palette.surface, 0.88)!,
      ),
      _StatItem(
        label: 'Sisa Anggaran',
        value: CurrencyFormatter.format(data.remainingBudget),
        icon: Icons.savings_outlined,
        color: AppTheme.tertiary,
        bg: Color.lerp(AppTheme.tertiary, palette.surface, 0.88)!,
      ),
      _StatItem(
        label: 'Progres Anggaran',
        value: '${percent.toStringAsFixed(1)}%',
        icon: Icons.trending_up,
        color: AppTheme.warning,
        bg: Color.lerp(AppTheme.warning, palette.surface, 0.88)!,
      ),
    ];

    return LayoutBuilder(
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
                    child: _StatCard(item: it),
                  ))
              .toList(),
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
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });
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
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
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
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
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

// ============================================================
// Section head
// ============================================================

class _SectionHead extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHead({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              backgroundColor:
                  Color.lerp(AppTheme.primary, palette.surface, 0.9),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

// ============================================================
// Category list (Ringkasan Anggaran)
// ============================================================

class _CategoryList extends StatelessWidget {
  final List<DashboardCategory> categories;
  const _CategoryList({required this.categories});

  Color _parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.line),
        ),
        child: Center(
          child: Text(
            'Belum ada kategori anggaran.',
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        children: categories.map((c) {
          final color = _parseHex(c.colorHex, AppTheme.primary);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${CurrencyFormatter.format(c.spent)} / ${CurrencyFormatter.format(c.budget)}',
                      style: TextStyle(fontSize: 11, color: palette.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: c.progress,
                    minHeight: 8,
                    backgroundColor: palette.line,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// Recent transactions (Aktivitas Terbaru)
// ============================================================

class _RecentTransactionsList extends StatelessWidget {
  final List<TransactionModel> items;
  const _RecentTransactionsList({required this.items});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.line),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 40, color: palette.muted),
            const SizedBox(height: 8),
            Text(
              'Belum ada transaksi',
              style: TextStyle(fontSize: 13, color: palette.ink),
            ),
            const SizedBox(height: 2),
            Text(
              'Tekan + Transaksi untuk mulai mencatat',
              style: TextStyle(fontSize: 11, color: palette.muted),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final tx = entry.value;
          final isLast = entry.key == items.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: palette.line, width: 1)),
            ),
            child: _RecentTile(tx: tx),
          );
        }).toList(),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final TransactionModel tx;
  const _RecentTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final isIncome = tx.isIncome;
    final color = isIncome ? AppTheme.success : AppTheme.error;
    final bgColor = Color.lerp(color, palette.surface, 0.85)!;
    final sign = isIncome ? '+' : '-';
    final title = tx.description?.isNotEmpty == true
        ? tx.description!
        : (tx.source?.isNotEmpty == true
            ? tx.source!
            : (isIncome ? 'Pemasukan' : 'Pengeluaran'));
    final df = DateFormat('d MMM yyyy', 'id_ID');

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                df.format(tx.transactionDate),
                style: TextStyle(fontSize: 11, color: palette.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$sign${CurrencyFormatter.format(tx.amount)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Quick actions (Akses Cepat)
// ============================================================

class _QuickActionsGrid extends ConsumerWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _QuickAction(label: 'Vendor', icon: Icons.store_outlined,
          onTap: () => _goToTab(ref, mainTab: 1, prepSubTab: 0)),
      _QuickAction(label: 'Lamaran', icon: Icons.favorite_border,
          onTap: () => _goToTab(ref, mainTab: 1, prepSubTab: 2)),
      _QuickAction(label: 'Seserahan', icon: Icons.card_giftcard,
          onTap: () => _goToTab(ref, mainTab: 1, prepSubTab: 3)),
      _QuickAction(label: 'Transaksi', icon: Icons.receipt_long_outlined,
          onTap: () => _goToTab(ref, mainTab: 2, financeSubTab: 1)),
      _QuickAction(label: 'Cicilan', icon: Icons.calendar_month_outlined,
          onTap: () => _goToTab(ref, mainTab: 2, financeSubTab: 2)),
      _QuickAction(label: 'Checklist', icon: Icons.check_circle_outline,
          onTap: () => _goToTab(ref, mainTab: 1, prepSubTab: 1)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final columns = isWide ? 6 : 3;
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions
              .map((a) => SizedBox(width: width, child: _QuickActionButton(action: a)))
              .toList(),
        );
      },
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.icon, required this.onTap});
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: palette.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(
            children: [
              const Icon(Icons.circle, size: 0),
              Icon(action.icon, size: 22, color: AppTheme.primary),
              const SizedBox(height: 6),
              Text(action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Empty & Error states
// ============================================================

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Profil pernikahan belum dibuat. Restart aplikasi untuk setup.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: palette.muted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}