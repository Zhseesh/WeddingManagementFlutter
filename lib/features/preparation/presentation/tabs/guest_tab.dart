import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/features/guests/data/guest_model.dart';
import 'package:weddingmanagementf/features/guests/presentation/guest_form_sheet.dart';
import 'package:weddingmanagementf/features/guests/presentation/providers/guest_providers.dart';

class GuestTab extends ConsumerWidget {
  const GuestTab({super.key});

  Future<void> _toggle(WidgetRef ref, GuestModel item) async {
    await ref
        .read(guestRepositoryProvider)
        .updateInvited(item.id!, !item.isInvited);
    ref.invalidate(guestListProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.of(context);
    final async = ref.watch(guestListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Belum ada tamu undangan.\nTekan + untuk menambah.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ),
          );
        }
        final invited = items.where((g) => g.isInvited).length;
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(guestListProvider);
            await ref.read(guestListProvider.future);
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
                        Text('$invited / ${items.length} diundang',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: palette.ink)),
                        const Spacer(),
                        Text('${(invited / items.length * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: invited / items.length,
                        minHeight: 8,
                        backgroundColor: palette.line,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final guest = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => showGuestEditSheet(context, ref, guest),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Checkbox(
                            value: guest.isInvited,
                            onChanged: (_) => _toggle(ref, guest),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                  AppTheme.primary, palette.surface, 0.88),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              guest.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: guest.isInvited
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: guest.isInvited
                                    ? palette.muted
                                    : palette.ink,
                              ),
                            ),
                          ),
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