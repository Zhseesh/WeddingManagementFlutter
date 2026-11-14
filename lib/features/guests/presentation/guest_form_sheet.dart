import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/features/guests/data/guest_model.dart';
import 'package:weddingmanagementf/features/guests/presentation/providers/guest_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

// ============================================================
// TAMBAH TAMU — AlertDialog (gaya "Tambah Kategori")
// ============================================================
Future<void> showGuestAddDialog(BuildContext context, WidgetRef ref) async {
  final nameCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Tambah Tamu'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Tamu',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(ctx, true);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );

  if (ok != true) return;

  try {
    final profile = await ref.read(activeWeddingProfileProvider.future);
    if (profile?.id == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil tidak ditemukan.')),
        );
      }
      return;
    }
    final now = DateTime.now();
    await ref.read(guestRepositoryProvider).insert(GuestModel(
          profileId: profile!.id!,
          name: nameCtrl.text.trim(),
          createdAt: now,
          updatedAt: now,
        ));
    ref.invalidate(guestListProvider);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }
}

// ============================================================
// EDIT / HAPUS TAMU — BottomSheet (gaya "Edit Alokasi")
// ============================================================
Future<void> showGuestEditSheet(
  BuildContext context,
  WidgetRef ref,
  GuestModel initial,
) async {
  final nameCtrl = TextEditingController(text: initial.name);

  final action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final keyboardPadding = MediaQuery.viewInsetsOf(ctx).bottom;
      final safeAreaPadding = MediaQuery.paddingOf(ctx).bottom;

      return Padding(
        padding: EdgeInsets.only(bottom: keyboardPadding),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + safeAreaPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit Tamu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Tamu',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, 'delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        minimumSize: const Size(0, 46),
                      ),
                      child: const Text('Hapus'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, 'save'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                      ),
                      child: const Text('Simpan Perubahan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  if (!context.mounted) return;

  if (action == 'delete') {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus tamu?'),
        content: Text('"${initial.name}" akan dihapus dari daftar tamu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(guestRepositoryProvider).delete(initial.id!);
      ref.invalidate(guestListProvider);
    }
  } else if (action == 'save') {
    final newName = nameCtrl.text.trim();
    if (newName.isEmpty || newName == initial.name) return;
    await ref.read(guestRepositoryProvider).update(
          initial.copyWith(name: newName, updatedAt: DateTime.now()),
        );
    ref.invalidate(guestListProvider);
  }
}