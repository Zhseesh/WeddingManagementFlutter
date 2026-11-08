import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/core/services/notification_service.dart';
import 'package:weddingmanagementf/features/reminders/data/reminder_model.dart';
import 'package:weddingmanagementf/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

class ReminderFormScreen extends ConsumerStatefulWidget {
  final ReminderModel? initial;
  const ReminderFormScreen({super.key, this.initial});

  @override
  ConsumerState<ReminderFormScreen> createState() =>
      _ReminderFormScreenState();
}

class _ReminderFormScreenState extends ConsumerState<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late DateTime _date;
  late bool _isEnabled;
  bool _submitting = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _titleCtrl = TextEditingController(text: m?.title ?? '');
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _date = m?.reminderDate ??
        DateTime.now().add(const Duration(hours: 1));
    _isEnabled = m?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 15),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_date.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      _showSnack('Waktu pengingat tidak boleh di masa lalu.');
      return;
    }
    setState(() => _submitting = true);

    // Minta izin notifikasi jika reminder di-enable
    if (_isEnabled) {
      await NotificationService.instance.ensurePermission();
    }

    try {
      final now = DateTime.now();
      if (_isEdit) {
        final updated = ReminderModel(
          id: widget.initial!.id,
          profileId: widget.initial!.profileId,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          reminderDate: _date,
          referenceType: widget.initial!.referenceType,
          referenceId: widget.initial!.referenceId,
          isEnabled: _isEnabled,
          isCompleted: widget.initial!.isCompleted,
          createdAt: widget.initial!.createdAt,
        );
        await ref.read(reminderRepositoryProvider).update(updated);
      } else {
        final profile = await ref.read(activeWeddingProfileProvider.future);
        if (profile == null || profile.id == null) {
          _showSnack('Profil tidak ditemukan.');
          return;
        }
        final model = ReminderModel(
          profileId: profile.id!,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          reminderDate: _date,
          isEnabled: _isEnabled,
          createdAt: now,
        );
        await ref.read(reminderRepositoryProvider).insert(model);
      }
      ref.invalidate(reminderListProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack('Gagal: $e');
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pengingat?'),
        content: const Text('Pengingat ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(reminderRepositoryProvider)
        .delete(widget.initial!.id!);
    ref.invalidate(reminderListProvider);
    if (!mounted) return;
    context.pop();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Pengingat' : 'Tambah Pengingat'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus',
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Judul Pengingat',
                  prefixIcon: Icon(Icons.alarm),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Text('Waktu',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Tanggal'),
                      subtitle: Text(
                        DateFormat('d MMMM yyyy', 'id_ID').format(_date),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickDate,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Jam'),
                      subtitle: Text(DateFormat('HH:mm').format(_date)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktifkan Notifikasi'),
                subtitle: const Text(
                  'Notifikasi akan muncul di HP saat waktunya tiba. '
                  'Pastikan izin notifikasi diberikan.',
                ),
                value: _isEnabled,
                onChanged: (v) => setState(() => _isEnabled = v),
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
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}