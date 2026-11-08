import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/features/reminders/data/reminder_model.dart';
import 'package:weddingmanagementf/features/reminders/presentation/providers/reminder_providers.dart';

class ReminderListScreen extends ConsumerWidget {
  const ReminderListScreen({super.key});

  String _relativeDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = d.difference(today).inDays;
    final time = DateFormat('HH:mm').format(dt);
    if (diff == 0) return 'Hari ini, $time';
    if (diff == 1) return 'Besok, $time';
    if (diff == -1) return 'Kemarin, $time';
    if (diff > 1 && diff <= 7) {
      return '${DateFormat('EEE, d MMM', 'id_ID').format(dt)}, $time';
    }
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reminderListProvider);
    final filter = ref.watch(reminderFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengingat')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          var filtered = items;
          if (filter == 'active') {
            filtered = filtered.where((r) => !r.isCompleted).toList();
          } else if (filter == 'done') {
            filtered = filtered.where((r) => r.isCompleted).toList();
          }

          return Column(
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
                          ref.read(reminderFilterProvider.notifier).state = null,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Aktif'),
                      selected: filter == 'active',
                      onSelected: (_) => ref
                          .read(reminderFilterProvider.notifier)
                          .state = 'active',
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Selesai'),
                      selected: filter == 'done',
                      onSelected: (_) =>
                          ref.read(reminderFilterProvider.notifier).state = 'done',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            items.isEmpty
                                ? 'Belum ada pengingat.\nTekan + untuk menambah.'
                                : 'Tidak ada pengingat yang cocok.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(reminderListProvider);
                          await ref.read(reminderListProvider.future);
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _ReminderCard(
                            item: filtered[i],
                            relativeDate: _relativeDate(
                                filtered[i].reminderDate),
                            onToggleCompleted: () async {
                              await ref
                                  .read(reminderRepositoryProvider)
                                  .toggleCompleted(filtered[i]);
                              ref.invalidate(reminderListProvider);
                            },
                            onToggleEnabled: () async {
                              await ref
                                  .read(reminderRepositoryProvider)
                                  .toggleEnabled(filtered[i]);
                              ref.invalidate(reminderListProvider);
                            },
                            onTap: () => context.push(
                              '/preparation/reminder/edit',
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
        onPressed: () => context.push('/preparation/reminder/new'),
        icon: const Icon(Icons.add),
        label: const Text('Pengingat'),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel item;
  final String relativeDate;
  final VoidCallback onToggleCompleted;
  final VoidCallback onToggleEnabled;
  final VoidCallback onTap;

  const _ReminderCard({
    required this.item,
    required this.relativeDate,
    required this.onToggleCompleted,
    required this.onToggleEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPast = item.isPast && !item.isCompleted;
    final isActive = item.isEnabled && !item.isCompleted;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: item.isCompleted,
                onChanged: (_) => onToggleCompleted(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.isCompleted
                            ? scheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.alarm,
                          size: 12,
                          color: isPast
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          relativeDate,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: isPast ? scheme.error : null,
                                fontWeight:
                                    isPast ? FontWeight.w600 : null,
                              ),
                        ),
                        if (isPast) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                  scheme.surface, scheme.error, 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Lewat',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: scheme.error),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isActive
                    ? 'Matikan notifikasi'
                    : 'Aktifkan notifikasi',
                icon: Icon(
                  isActive
                      ? Icons.notifications_active
                      : Icons.notifications_off_outlined,
                  color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                ),
                onPressed: item.isCompleted ? null : onToggleEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}