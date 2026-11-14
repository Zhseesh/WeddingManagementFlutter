import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/data/wedding_profile_model.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final WeddingProfile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _partnerOneCtrl;
  late final TextEditingController _partnerTwoCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _notesCtrl;

  DateTime? _weddingDate;
  DateTime? _engagementDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _partnerOneCtrl =
        TextEditingController(text: widget.profile.partnerOne);
    _partnerTwoCtrl =
        TextEditingController(text: widget.profile.partnerTwo);
    _locationCtrl =
        TextEditingController(text: widget.profile.weddingLocation ?? '');
    _notesCtrl = TextEditingController(text: widget.profile.notes ?? '');
    _weddingDate = widget.profile.weddingDate;
    _engagementDate = widget.profile.engagementDate;
  }

  @override
  void dispose() {
    _partnerOneCtrl.dispose();
    _partnerTwoCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isWedding}) async {
    final now = DateTime.now();
    final initial = isWedding
        ? (_weddingDate ?? now.add(const Duration(days: 90)))
        : (_engagementDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
    );
    if (picked == null) return;
    setState(() {
      final n = DateTime(picked.year, picked.month, picked.day);
      if (isWedding) {
        _weddingDate = n;
      } else {
        _engagementDate = n;
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_weddingDate == null) {
      _showSnack('Tanggal pernikahan wajib diisi.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final updated = WeddingProfile(
        id: widget.profile.id,
        partnerOne: _partnerOneCtrl.text.trim(),
        partnerTwo: _partnerTwoCtrl.text.trim(),
        weddingDate: _weddingDate,
        engagementDate: _engagementDate,
        weddingLocation: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        notes:
            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        isActive: widget.profile.isActive,
        createdAt: widget.profile.createdAt,
        updatedAt: now,
      );
      await ref
          .read(weddingProfileRepositoryProvider)
          .updateProfile(updated);
      ref.invalidate(activeWeddingProfileProvider);
      ref.invalidate(dashboardDataProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack('Gagal menyimpan: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(DateTime? d) => d == null
      ? 'Pilih tanggal'
      : DateFormat('d MMMM yyyy', 'id_ID').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Data Pernikahan',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _partnerOneCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Calon 1',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _partnerTwoCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Calon 2',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Tanggal Pernikahan'),
                      subtitle: Text(_formatDate(_weddingDate)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickDate(isWedding: true),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.favorite_border),
                      title: const Text('Tanggal Lamaran (opsional)'),
                      subtitle: Text(_formatDate(_engagementDate)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickDate(isWedding: false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Pernikahan (opsional)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}