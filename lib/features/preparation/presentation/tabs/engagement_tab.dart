import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/engagement/presentation/engagement_form_sheet.dart';
import 'package:weddingmanagementf/features/engagement/presentation/providers/engagement_providers.dart';

class EngagementTab extends ConsumerWidget {
  const EngagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppTheme.of(context);
    final async = ref.watch(engagementListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Belum ada item lamaran.\nTekan + untuk menambah.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = items[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () =>
                      showEngagementFormSheet(context, initial: item),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: palette.ink)),
                            ),
                            Chip(
                              label: Text(item.statusEnum.label),
                              visualDensity: VisualDensity.compact,
                              labelStyle: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item.quantity} × ${CurrencyFormatter.format(item.actualPrice > 0 ? item.actualPrice : item.estimatedPrice)}',
                          style: TextStyle(
                              fontSize: 12, color: palette.muted),
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