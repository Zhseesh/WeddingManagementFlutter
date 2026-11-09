import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/features/reminders/data/reminder_model.dart';
import 'package:weddingmanagementf/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:weddingmanagementf/features/reminders/presentation/reminder_form_sheet.dart';

class ReminderTab extends ConsumerWidget {
  const ReminderTab({super.key});

  Future<void> _toggle(WidgetRef ref, ReminderModel item) async {
    await ref.read(reminderRepositoryProvider).toggleCompleted(item);
    ref.invalidate(reminderListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reminderListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Belum ada pengingat.\nTekan + untuk menambah.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(reminderListProvider);
            await ref.read(reminderListProvider.future);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = items[i];
              final isPast = item.isPast && !item.isCompleted;
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () =>
                      showReminderFormSheet(context, initial: item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.isCompleted,
                          onChanged: (_) => _toggle(ref, item),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: item.isCompleted
                                      ? AppTheme.muted
                                      : AppTheme.ink,
                                ),
                              ),
                              Text(
                                DateFormat('d MMM yyyy, HH:mm', 'id_ID')
                                    .format(item.reminderDate),
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isPast ? AppTheme.error : AppTheme.muted,
                                  fontWeight: isPast
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isPast)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Text('Lewat',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.error,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}