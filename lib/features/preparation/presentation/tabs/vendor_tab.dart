import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/vendors/data/vendor_model.dart';
import 'package:weddingmanagementf/features/vendors/presentation/providers/vendor_providers.dart';

class VendorTab extends ConsumerStatefulWidget {
  const VendorTab({super.key});
  @override
  ConsumerState<VendorTab> createState() => _VendorTabState();
}

class _VendorTabState extends ConsumerState<VendorTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final async = ref.watch(vendorListProvider);
    final query = ref.watch(vendorSearchQueryProvider).toLowerCase();
    final filter = ref.watch(vendorStatusFilterProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) =>
                ref.read(vendorSearchQueryProvider.notifier).state = v,
            decoration: const InputDecoration(
              hintText: 'Cari vendor...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Semua'),
                selected: filter == null,
                onSelected: (_) =>
                    ref.read(vendorStatusFilterProvider.notifier).state = null,
              ),
              const SizedBox(width: 6),
              ...VendorStatus.values.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(s.label),
                    selected: filter == s,
                    onSelected: (_) => ref
                        .read(vendorStatusFilterProvider.notifier)
                        .state = s,
                  ),
                ),
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
              if (filter != null) {
                filtered = filtered
                    .where((v) => v.vendor.status == filter.dbValue)
                    .toList();
              }
              if (query.isNotEmpty) {
                filtered = filtered
                    .where((v) =>
                        v.vendor.name.toLowerCase().contains(query) ||
                        (v.vendor.contactName ?? '')
                            .toLowerCase()
                            .contains(query))
                    .toList();
              }
              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Belum ada vendor.\nTekan + untuk menambah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(vendorListProvider);
                  await ref.read(vendorListProvider.future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            context.push('/preparation/vendor/${item.vendor.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.vendor.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: palette.ink,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(item.vendor.statusEnum.label),
                                    visualDensity: VisualDensity.compact,
                                    labelStyle: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _amount('Harga', item.vendor.agreedPrice,
                                      palette.ink, palette),
                                  _amount('Dibayar', item.totalPaid,
                                      AppTheme.tertiary, palette),
                                  _amount(
                                      'Sisa',
                                      item.remaining,
                                      item.remaining > 0
                                          ? AppTheme.error
                                          : palette.muted,
                                      palette),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: item.progress,
                                  minHeight: 6,
                                  backgroundColor: palette.line,
                                ),
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
          ),
        ),
      ],
    );
  }

  Widget _amount(String label, int value, Color color, AppPalette palette) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: palette.muted)),
          Text(
            CurrencyFormatter.format(value),
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}