import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart'; // 👈 Tambahan import Lucide
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/features/guests/data/guest_model.dart';
import 'package:weddingmanagementf/features/guests/presentation/guest_form_sheet.dart';
import 'package:weddingmanagementf/features/guests/presentation/providers/guest_providers.dart';

class GuestTab extends ConsumerStatefulWidget {
  const GuestTab({super.key});
  @override
  ConsumerState<GuestTab> createState() => _GuestTabState();
}

class _GuestTabState extends ConsumerState<GuestTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // 👈 Tambahan method _toggle yang sempat hilang
  Future<void> _toggle(WidgetRef ref, GuestModel item) async {
    await ref
        .read(guestRepositoryProvider)
        .updateInvited(item.id!, !item.isInvited);
    ref.invalidate(guestListProvider);
  }

  Future<void> _exportCsv(List<GuestModel> guests) async {
    final buffer = StringBuffer();
    buffer.writeln('No,Nama Tamu,Status Undangan');
    for (var i = 0; i < guests.length; i++) {
      final status = guests[i].isInvited ? 'Sudah Diundang' : 'Belum Diundang';
      final name = guests[i].name.replaceAll(',', ' '); // Sanitasi koma
      buffer.writeln('${i + 1},$name,$status');
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/daftar_tamu.csv');
      await file.writeAsString(buffer.toString());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Daftar Tamu Undangan',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final async = ref.watch(guestListProvider);
    // 👈 Tambahan variabel query yang sempat hilang
    final query = ref.watch(guestSearchQueryProvider).toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => ref.read(guestSearchQueryProvider.notifier).state = v,
            decoration: const InputDecoration(
              hintText: 'Cari tamu...',
              prefixIcon: Icon(LucideIcons.search),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              // Logika Filter
              var filtered = items;
              if (query.isNotEmpty) {
                filtered = filtered.where((g) => g.name.toLowerCase().contains(query)).toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    items.isEmpty ? 'Belum ada tamu.' : 'Tamu tidak ditemukan.',
                    style: TextStyle(color: palette.muted),
                  ),
                );
              }

              final invited = filtered.where((g) => g.isInvited).length;
              
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$invited / ${filtered.length} diundang',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: palette.ink)),
                              TextButton.icon(
                                onPressed: () => _exportCsv(filtered), 
                                icon: const Icon(LucideIcons.download, size: 16),
                                label: const Text('Ekspor CSV', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: filtered.isEmpty ? 0 : invited / filtered.length,
                              minHeight: 8,
                              backgroundColor: palette.line,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 👈 Pastikan map menggunakan 'filtered' bukan 'items'
                    ...filtered.asMap().entries.map((entry) {
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
                                        Theme.of(context).colorScheme.primary, palette.surface, 0.88),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).colorScheme.primary,
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
          ),
        ),
      ],
    );
  }
}