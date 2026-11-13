import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/features/backup/presentation/providers/backup_providers.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/checklist/presentation/providers/checklist_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/dowry/presentation/providers/dowry_providers.dart';
import 'package:weddingmanagementf/features/engagement/presentation/providers/engagement_providers.dart';
import 'package:weddingmanagementf/features/guests/presentation/providers/guest_providers.dart';
import 'package:weddingmanagementf/features/installments/presentation/providers/installment_providers.dart';
import 'package:weddingmanagementf/core/providers/navigation_providers.dart';
import 'package:weddingmanagementf/features/reminders/presentation/providers/reminder_providers.dart';
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
    ref.invalidate(reminderListProvider);
    ref.invalidate(reportDataProvider);
    ref.invalidate(guestListProvider);
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Menyiapkan backup...')));
    try {
      final json = await ref.read(backupServiceProvider).exportToJson();
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/backup_wedding_$stamp.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], subject: 'Backup Wedding Planner');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal backup: $e')));
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
        : (file.path != null ? await File(file.path!).readAsString() : null);
    if (raw == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Gagal membaca file.')));
      return;
    }

    final err = ref.read(backupServiceProvider).validateJson(raw);
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text('File tidak valid: $err')));
      return;
    }

    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore data?'),
        content: const Text('Semua data saat ini akan DIGANTI dengan data dari file backup. Aplikasi akan otomatis menyimpan backup data saat ini terlebih dahulu.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Restore')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final preJson = await ref.read(backupServiceProvider).exportToJson();
      final docs = await getApplicationDocumentsDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final preFile = File('${docs.path}/pre_restore_$stamp.json');
      await preFile.writeAsString(preJson);
    } catch (_) {}

    try {
      await ref.read(backupServiceProvider).importFromJson(raw);
      _invalidateAll(ref);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Restore berhasil. Data dimuat ulang.'), duration: Duration(seconds: 3)),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Restore gagal (data lama aman): $e')));
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Wedding Planner & Finance',
      applicationVersion: '1.0.0',
      children: const [
        Text('Aplikasi offline-first untuk mengelola persiapan pernikahan dan keuangan.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeWeddingProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text('Data pernikahan & pengaturan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.muted)),
          ],
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profil belum dibuat.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProfileCard(
                profile: profile,
                onEdit: () => context.push('/profile/edit', extra: profile),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                onBackup: () => _backup(context, ref),
                onRestore: () => _restore(context, ref),
                onReminder: () {
                  ref.read(mainTabProvider.notifier).state = 1;
                  ref.read(prepTabProvider.notifier).state = 4;
                },
                onAbout: () => _showAbout(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// Profile Card
// ============================================================

class _ProfileCard extends StatelessWidget {
  final WeddingProfile profile;
  final VoidCallback onEdit;
  const _ProfileCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMMM yyyy', 'id_ID');
    final weddingText = profile.weddingDate != null ? df.format(profile.weddingDate!) : 'Belum diatur';
    final engagementText = profile.engagementDate != null ? df.format(profile.engagementDate!) : 'Belum diatur';
    final locationText = (profile.weddingLocation?.isNotEmpty ?? false) ? profile.weddingLocation! : 'Belum diatur';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FIX: dijadikan const
              const SizedBox(
                width: 54,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFF0EDFF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.favorite, color: AppTheme.primary, size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${profile.partnerOne} & ${profile.partnerTwo}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // FIX: dijadikan const (menggunakan BorderRadius.all)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFE3F8EF),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          child: Text(
                            'Profil aktif',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.success),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  backgroundColor: const Color(0xFFF0EDFF),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 14),
                    SizedBox(width: 4),
                    Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.line),
          const SizedBox(height: 12),
          _infoRow('Tanggal pernikahan', weddingText),
          const SizedBox(height: 10),
          _infoRow('Tanggal lamaran', engagementText),
          const SizedBox(height: 10),
          _infoRow('Lokasi', locationText),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, color: AppTheme.ink, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Settings Card
// ============================================================

class _SettingsCard extends StatelessWidget {
  final VoidCallback onBackup;
  final VoidCallback onRestore;
  final VoidCallback onReminder;
  final VoidCallback onAbout;
  const _SettingsCard({
    required this.onBackup,
    required this.onRestore,
    required this.onReminder,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Pengaturan & Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.ink)),
            ),
          ),
          _row(
            title: 'Backup data',
            subtitle: 'Simpan semua data sebagai JSON',
            actionLabel: 'Backup',
            onAction: onBackup,
          ),
          const Divider(height: 1, color: AppTheme.line),
          _row(
            title: 'Restore data',
            subtitle: 'Pulihkan dari file JSON',
            actionLabel: 'Pilih file',
            onAction: onRestore,
          ),
          const Divider(height: 1, color: AppTheme.line),
          _row(
            title: 'Pengingat',
            subtitle: 'Jadwal dan notifikasi persiapan',
            actionLabel: 'Kelola',
            onAction: onReminder,
          ),
          const Divider(height: 1, color: AppTheme.line),
          _row(
            title: 'Tentang aplikasi',
            subtitle: 'Wedding Planner v1.0.0',
            actionLabel: 'Info',
            onAction: onAbout,
            trailingPill: 'v1.0.0',
          ),
        ],
      ),
    );
  }

  Widget _row({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
    String? trailingPill,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (trailingPill != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                trailingPill,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
              ),
            )
          else
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                backgroundColor: const Color(0xFFF0EDFF),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}