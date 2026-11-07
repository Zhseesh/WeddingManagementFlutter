import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/vendors/data/vendor_model.dart';
import 'package:weddingmanagementf/features/vendors/presentation/providers/vendor_providers.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(vendorListProvider);
    final filter = ref.watch(vendorStatusFilterProvider);
    final query = ref.watch(vendorSearchQueryProvider).toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor')),
      body: Column(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: filter == null,
                  onSelected: (_) =>
                      ref.read(vendorStatusFilterProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                ...VendorStatus.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.store_outlined, size: 64),
                          const SizedBox(height: 12),
                          Text(
                            items.isEmpty
                                ? 'Belum ada vendor.\nTekan + untuk menambah.'
                                : 'Tidak ada vendor yang cocok dengan filter.',
                            textAlign: TextAlign.center,
                          ),
                        ],
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _VendorCard(item: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/preparation/vendor/new'),
        icon: const Icon(Icons.add),
        label: const Text('Vendor'),
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final VendorWithPayment item;
  const _VendorCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = item.vendor;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/preparation/vendor/${v.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      v.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Chip(
                    label: Text(v.statusEnum.label),
                    visualDensity: VisualDensity.compact,
                    labelStyle: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              if (v.contactName != null || v.phone != null) ...[
                const SizedBox(height: 4),
                Text(
                  [v.contactName, v.phone].whereType<String>().join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _amount(context, 'Harga', v.agreedPrice,
                        color: scheme.onSurface),
                  ),
                  Expanded(
                    child: _amount(context, 'Dibayar', item.totalPaid,
                        color: scheme.tertiary),
                  ),
                  Expanded(
                    child: _amount(context, 'Sisa', item.remaining,
                        color: item.remaining > 0
                            ? scheme.error
                            : scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amount(BuildContext context, String label, int value,
      {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          CurrencyFormatter.format(value),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}