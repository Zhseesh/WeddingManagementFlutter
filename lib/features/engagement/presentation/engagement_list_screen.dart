import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/engagement/data/engagement_model.dart';
import 'package:weddingmanagementf/features/engagement/presentation/providers/engagement_providers.dart';

class EngagementListScreen extends ConsumerWidget {
  const EngagementListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(engagementListProvider);
    final filter = ref.watch(engagementFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lamaran')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: filter == null,
                  onSelected: (_) =>
                      ref.read(engagementFilterProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Aktif'),
                  selected: filter == 'active',
                  onSelected: (_) => ref
                      .read(engagementFilterProvider.notifier)
                      .state = 'active',
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Selesai'),
                  selected: filter == 'done',
                  onSelected: (_) =>
                      ref.read(engagementFilterProvider.notifier).state = 'done',
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                var filtered = items;
                if (filter == 'active') {
                  filtered = filtered
                      .where((i) =>
                          i.status != 'completed' && i.status != 'cancelled')
                      .toList();
                } else if (filter == 'done') {
                  filtered =
                      filtered.where((i) => i.status == 'completed').toList();
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        items.isEmpty
                            ? 'Belum ada item lamaran.\nTekan + untuk menambah.'
                            : 'Tidak ada item yang cocok.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(engagementListProvider);
                    await ref.read(engagementListProvider.future);
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _EngagementCard(item: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/preparation/engagement/new'),
        icon: const Icon(Icons.add),
        label: const Text('Item'),
      ),
    );
  }
}

class _EngagementCard extends StatelessWidget {
  final EngagementModel item;
  const _EngagementCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estimatedTotal = item.estimatedPrice * item.quantity;
    final actualTotal = item.actualPrice * item.quantity;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          '/preparation/engagement/edit',
          extra: item,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Chip(
                    label: Text(item.statusEnum.label),
                    visualDensity: VisualDensity.compact,
                    labelStyle: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              if (item.category != null) ...[
                const SizedBox(height: 2),
                Text(item.category!,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _stat(context, 'Jumlah', '${item.quantity}'),
                  _stat(context, 'Estimasi',
                      CurrencyFormatter.format(estimatedTotal),
                      color: scheme.onSurfaceVariant),
                  _stat(context, 'Aktual',
                      CurrencyFormatter.format(actualTotal),
                      color: actualTotal > 0
                          ? scheme.tertiary
                          : scheme.onSurfaceVariant),
                ],
              ),
              if (item.dueDate != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.event,
                        size: 12, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM yyyy', 'id_ID').format(item.dueDate!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value,
      {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}