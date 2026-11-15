import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/core/services/notification_service.dart';
import 'package:weddingmanagementf/features/preparation/presentation/sheets/form_sheet_scaffold.dart';
import 'package:weddingmanagementf/features/reminders/data/reminder_model.dart';
import 'package:weddingmanagementf/features/reminders/presentation/providers/reminder_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

Future<void> showReminderFormSheet(
  BuildContext context, {
  ReminderModel? initial,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReminderFormSheet(initial: initial),
  );
}

class _ReminderFormSheet extends ConsumerStatefulWidget {
  final ReminderModel? initial;
  const _ReminderFormSheet({this.initial});
  @override
  ConsumerState<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends ConsumerState<_ReminderFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late DateTime _date;
  late bool _isEnabled;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _titleCtrl = TextEditingController(text: m?.title ?? '');
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _date = m?.reminderDate ?? DateTime.now().add(const Duration(hours: 1));
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
      _date = DateTime(picked.year, picked.month, picked.day, _date.hour,
          _date.minute);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(_date.year, _date.month, _date.day, picked.hour,
          picked.minute);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_date.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu tidak boleh di masa lalu.')),
      );
      return;
    }
    setState(() => _saving = true);
    if (_isEnabled) {
      await NotificationService.instance.ensurePermission();
    }
    try {
      if (_isEdit) {
        await ref.read(reminderRepositoryProvider).update(ReminderModel(
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
            ));
      } else {
        final profile = await ref.read(activeWeddingProfileProvider.future);
        if (profile?.id == null) return;
        await ref.read(reminderRepositoryProvider).insert(ReminderModel(
              profileId: profile!.id!,
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              reminderDate: _date,
              isEnabled: _isEnabled,
              createdAt: DateTime.now(),
            ));
      }
      ref.invalidate(reminderListProvider);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pengingat?'),
        content: const Text('Pengingat ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(reminderRepositoryProvider).delete(widget.initial!.id!);
    ref.invalidate(reminderListProvider);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetScaffold(
      title: _isEdit ? 'Edit Pengingat' : 'Tambah Pengingat',
      onSave: _submit,
      saving: _saving,
      onDelete: _isEdit ? _delete : null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Judul Pengingat'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Deskripsi (opsional)'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.calendar),
              title: const Text('Tanggal'),
              subtitle: Text(
                  DateFormat('d MMMM yyyy', 'id_ID').format(_date)),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.clock),
              title: const Text('Jam'),
              subtitle: Text(DateFormat('HH:mm').format(_date)),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: _pickTime,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktifkan Notifikasi'),
              value: _isEnabled,
              onChanged: (v) => setState(() => _isEnabled = v),
            ),
          ],
        ),
      ),
    );
  }
}