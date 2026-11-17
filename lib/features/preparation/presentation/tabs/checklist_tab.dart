import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/features/checklist/data/checklist_model.dart';
import 'package:weddingmanagementf/features/checklist/presentation/providers/checklist_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/checklist/presentation/checklist_form_sheet.dart';

class ChecklistTab extends ConsumerWidget {
  const ChecklistTab({super.key});

  Future<void> _toggle(WidgetRef ref, ChecklistModel item) async {
    await ref
        .read(checklistRepositoryProvider)
        .updateStatus(item.id!, item.isCompleted ? 'pending' : 'completed');
    ref.invalidate(checklistListProvider);
    ref.invalidate(dashboardDataProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.of(context);
    final async = ref.watch(checklistListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Belum ada checklist.\nTekan + untuk menambah.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ),
          );
        }
        final done = items.where((c) => c.isCompleted).length;
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(checklistListProvider);
            await ref.read(checklistListProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.line),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('$done / ${items.length} selesai',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: palette.ink)),
                        const Spacer(),
                        Text('${(done / items.length * 100).round()}%',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: done / items.length,
                        minHeight: 8,
                        backgroundColor: palette.line,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...items.map((c) {
                final overdue = c.isOverdue;
                final dueText = c.dueDate != null
                    ? DateFormat('d MMM', 'id_ID').format(c.dueDate!)
                    : null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => showChecklistFormSheet(context, initial: c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Checkbox(
                            value: c.isCompleted,
                            onChanged: (_) => _toggle(ref, c),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    decoration: c.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: c.isCompleted
                                        ? palette.muted
                                        : palette.ink,
                                  ),
                                ),
                                if (dueText != null)
                                  Text(
                                    dueText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: overdue
                                          ? AppTheme.error
                                          : palette.muted,
                                      fontWeight: overdue
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (c.priorityEnum == ChecklistPriority.high)
                            const Icon(LucideIcons.flag,
                                size: 16, color: AppTheme.error),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}