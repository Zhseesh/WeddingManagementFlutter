import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:weddingmanagementf/features/backup/presentation/providers/backup_providers.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/checklist/presentation/providers/checklist_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/dowry/presentation/providers/dowry_providers.dart';
import 'package:weddingmanagementf/features/engagement/presentation/providers/engagement_providers.dart';
import 'package:weddingmanagementf/features/installments/presentation/providers/installment_providers.dart';
import 'package:weddingmanagementf/features/reports/presentation/providers/report_providers.dart';
import 'package:weddingmanagementf/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:weddingmanagementf/features/vendors/presentation/providers/vendor_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/data/wedding_profile_model.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _invalidateAll(WidgetRef ref) {
    ref.invalidate(activeWeddingProfileProvider);
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(transactionListProvider);
    ref.invalidate(budgetSummaryProvider);
    ref.invalidate(activeBudgetProvider);
    ref.invalidate(budgetCategoriesProvider);
    ref.invalidate(categorySpendingProvider);
    ref.invalidate(vendorListProvider);
    ref.invalidate(installmentListProvider);
    ref.invalidate(checklistListProvider);
    ref.invalidate(engagementListProvider);
    ref.invalidate(dowryListProvider);
    ref.invalidate(reportDataProvider);
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Menyiapkan backup...')),
    );
    try {
      final json = await ref.read(backupServiceProvider).exportToJson();
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/backup_wedding_$stamp.json');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Backup Wedding Planner',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal backup: $e')),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final raw = file.bytes != null
        ? String.fromCharCodes(file.bytes!)
        : (file.path != null
            ? await File(file.path!).readAsString()
            : null);
    if (raw == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal membaca file.')),
      );
      return;
    }

    // Validate
    final err = ref.read(backupServiceProvider).validateJson(raw);
    if (err != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('File tidak valid: $err')),
      );
      return;
    }

    // Confirm
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore data?'),
        content: const Text(
          'Semua data saat ini akan DIGANTI dengan data dari file backup. '
          'Aplikasi akan otomatis menyimpan backup data saat ini terlebih dahulu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Auto backup current
    try {
      final preJson =
          await ref.read(backupServiceProvider).exportToJson();
      final docs = await getApplicationDocumentsDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final preFile = File('${docs.path}/pre_restore_$stamp.json');
      await preFile.writeAsString(preJson);
    } catch (_) {
      // Abaikan; restore tetap jalan (PRD bilang backup sebelum restore
      // sebagai upaya terbaik, tidak boleh memblokir restore)
    }

    // Perform restore
    try {
      await ref.read(backupServiceProvider).importFromJson(raw);
      _invalidateAll(ref);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Restore berhasil. Data dimuat ulang.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Restore gagal (data lama aman): $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeWeddingProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil belum dibuat.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _WeddingCard(profile: profile),
              const SizedBox(height: 20),
              const _SectionLabel('Data & Backup'),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.backup),
                      title: const Text('Backup Data'),
                      subtitle: const Text(
                        'Export semua data ke file JSON',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _backup(context, ref),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: const Text('Restore Data'),
                      subtitle: const Text(
                        'Pilih file backup JSON untuk dipulihkan',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _restore(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Tentang'),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Versi Aplikasi'),
                      trailing: Text('1.0.0 (1)'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.pink),
                      title: const Text('Wedding Planner'),
                      subtitle: const Text(
                        'Persiapan & keuangan dalam satu tempat',
                      ),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Wedding Planner & Finance',
                          applicationVersion: '1.0.0',
                          children: const [
                            Text(
                              'Aplikasi offline-first untuk mengelola '
                              'persiapan pernikahan dan keuangan.',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Dibuat dengan ❤️',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeddingCard extends StatelessWidget {
  final WeddingProfile profile;
  const _WeddingCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final df = DateFormat('d MMMM yyyy', 'id_ID');
    final dateText = profile.weddingDate != null
        ? df.format(profile.weddingDate!)
        : 'Belum diatur';
    final days = profile.weddingDate != null
        ? DateTime(profile.weddingDate!.year, profile.weddingDate!.month,
                profile.weddingDate!.day)
            .difference(DateTime(
                DateTime.now().year, DateTime.now().month, DateTime.now().day))
            .inDays
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${profile.partnerOne} & ${profile.partnerTwo}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edit profil',
                icon: Icon(Icons.edit, color: scheme.onPrimary),
                onPressed: () => context.push('/profile/edit', extra: profile),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _row(context, Icons.event, dateText),
          if (profile.weddingLocation != null &&
              profile.weddingLocation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _row(context, Icons.location_on, profile.weddingLocation!),
          ],
          if (days != null && days >= 0) ...[
            const SizedBox(height: 12),
            Text(
              '$days hari lagi',
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: scheme.onPrimary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}