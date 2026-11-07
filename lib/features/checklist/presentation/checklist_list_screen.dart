import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/features/checklist/data/checklist_model.dart';
import 'package:weddingmanagementf/features/checklist/presentation/providers/checklist_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';

class ChecklistListScreen extends ConsumerWidget {
  const ChecklistListScreen({super.key});

  Future<void> _toggle(
    WidgetRef ref,
    ChecklistModel item,
  ) async {
    final newStatus = item.isCompleted ? 'pending' : 'completed';
    await ref.read(checklistRepositoryProvider).updateStatus(item.id!, newStatus);
    ref.invalidate(checklistListProvider);
    ref.invalidate(dashboardDataProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(checklistListProvider);
    final filter = ref.watch(checklistFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checklist')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Belum ada checklist.\nTekan + untuk menambah.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final done = items.where((c) => c.isCompleted).length;
          final total = items.length;
          var filtered = items;
          if (filter == 'active') {
            filtered = filtered.where((c) => !c.isCompleted).toList();
          } else if (filter == 'done') {
            filtered = filtered.where((c) => c.isCompleted).toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _ProgressCard(done: done, total: total),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Semua'),
                      selected: filter == null,
                      onSelected: (_) => ref
                          .read(checklistFilterProvider.notifier)
                          .state = null,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Aktif'),
                      selected: filter == 'active',
                      onSelected: (_) => ref
                          .read(checklistFilterProvider.notifier)
                          .state = 'active',
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Selesai'),
                      selected: filter == 'done',
                      onSelected: (_) => ref
                          .read(checklistFilterProvider.notifier)
                          .state = 'done',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Tidak ada item.'))
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(checklistListProvider);
                          await ref.read(checklistListProvider.future);
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) => _ChecklistTile(
                            item: filtered[i],
                            onToggle: () => _toggle(ref, filtered[i]),
                            onTap: () => context.push(
                              '/preparation/checklist/edit',
                              extra: filtered[i],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/preparation/checklist/new'),
        icon: const Icon(Icons.add),
        label: const Text('Checklist'),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressCard({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = total == 0 ? 0.0 : done / total;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Progres',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '$done / $total',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final ChecklistModel item;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _ChecklistTile({
    required this.item,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = item.isOverdue;
    final dueText = item.dueDate != null
        ? DateFormat('d MMM yyyy', 'id_ID').format(item.dueDate!)
        : null;

    return ListTile(
      onTap: onTap,
      leading: Checkbox(
        value: item.isCompleted,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        item.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
          color: item.isCompleted ? scheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: Row(
        children: [
          if (item.category != null) ...[
            Text(item.category!,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
          ],
          if (dueText != null)
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 12,
                  color: overdue ? scheme.error : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 2),
                Text(
                  dueText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: overdue ? scheme.error : null,
                        fontWeight: overdue ? FontWeight.w600 : null,
                      ),
                ),
              ],
            ),
          if (overdue) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Color.lerp(scheme.surface, scheme.error, 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Terlambat',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.error),
              ),
            ),
          ],
        ],
      ),
      trailing: item.priorityEnum == ChecklistPriority.high
          ? Icon(Icons.flag, size: 18, color: scheme.error)
          : item.priorityEnum == ChecklistPriority.medium
              ? Icon(Icons.flag, size: 18, color: scheme.primary)
              : null,
    );
  }
}