import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/app/app_init.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/wedding_profile/data/wedding_profile_model.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partnerOneCtrl = TextEditingController();
  final _partnerTwoCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();

  DateTime? _weddingDate;
  DateTime? _engagementDate;
  bool _submitting = false;

  @override
  void dispose() {
    _partnerOneCtrl.dispose();
    _partnerTwoCtrl.dispose();
    _locationCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isWedding}) async {
    final now = DateTime.now();
    final initial = isWedding ? (_weddingDate ?? now.add(const Duration(days: 90))) : (_engagementDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
    );
    if (picked == null) return;
    setState(() {
      final normalized = DateTime(picked.year, picked.month, picked.day);
      if (isWedding) {
        _weddingDate = normalized;
      } else {
        _engagementDate = normalized;
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_weddingDate == null) {
      _showSnack('Tanggal pernikahan wajib diisi.');
      return;
    }

    final budget = CurrencyFormatter.parse(_budgetCtrl.text);
    if (budget <= 0) {
      _showSnack('Total anggaran harus lebih dari Rp0.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final now = DateTime.now();
      final profile = WeddingProfile(
        partnerOne: _partnerOneCtrl.text.trim(),
        partnerTwo: _partnerTwoCtrl.text.trim(),
        weddingDate: _weddingDate,
        engagementDate: _engagementDate,
        weddingLocation: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(weddingProfileRepositoryProvider).createProfileWithDefaults(
        profile: profile,
        initialBudget: budget,
      );

      await markOnboardingDone();
      ref.invalidate(activeWeddingProfileProvider);
      if (!mounted) return;
      context.go('/app');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack('Gagal menyimpan: $e');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih tanggal';
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Profil')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Data Pernikahan', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _partnerOneCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama Calon Pengantin 1', prefixIcon: Icon(LucideIcons.user)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _partnerTwoCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama Calon Pengantin 2', prefixIcon: Icon(LucideIcons.user)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(LucideIcons.calendar),
                      title: const Text('Tanggal Pernikahan'),
                      subtitle: Text(_formatDate(_weddingDate)),
                      trailing: const Icon(LucideIcons.chevronRight),
                      onTap: () => _pickDate(isWedding: true),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(LucideIcons.heart),
                      title: const Text('Tanggal Lamaran (Opsional)'),
                      subtitle: Text(_formatDate(_engagementDate)),
                      trailing: const Icon(LucideIcons.chevronRight),
                      onTap: () => _pickDate(isWedding: false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Lokasi Pernikahan (Opsional)', prefixIcon: Icon(LucideIcons.mapPin)),
              ),
              const SizedBox(height: 24),
              Text('Anggaran', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Anggaran Awal', prefixText: 'Rp ', prefixIcon: Icon(LucideIcons.wallet)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  if (CurrencyFormatter.parse(v) <= 0) return 'Harus lebih dari Rp0';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text('Kategori anggaran dan checklist umum akan otomatis dibuat dan bisa kamu ubah nanti.', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan & Lanjut'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}