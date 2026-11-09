import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/features/checklist/data/checklist_model.dart';
import 'package:weddingmanagementf/features/checklist/presentation/providers/checklist_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/preparation/presentation/sheets/form_sheet_scaffold.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

Future<void> showChecklistFormSheet(
  BuildContext context, {
  ChecklistModel? initial,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ChecklistFormSheet(initial: initial),
  );
}

class _ChecklistFormSheet extends ConsumerStatefulWidget {
  final ChecklistModel? initial;
  const _ChecklistFormSheet({this.initial});
  @override
  ConsumerState<_ChecklistFormSheet> createState() =>
      _ChecklistFormSheetState();
}

class _ChecklistFormSheetState extends ConsumerState<_ChecklistFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _descCtrl;
  ChecklistPriority _priority = ChecklistPriority.medium;
  ChecklistStatus _status = ChecklistStatus.pending;
  DateTime? _dueDate;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _titleCtrl = TextEditingController(text: c?.title ?? '');
    _categoryCtrl = TextEditingController(text: c?.category ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _priority = c?.priorityEnum ?? ChecklistPriority.medium;
    _status = c?.statusEnum ?? ChecklistStatus.pending;
    _dueDate = c?.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 15),
    );
    if (picked == null) return;
    setState(() => _dueDate = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      if (_isEdit) {
        await ref.read(checklistRepositoryProvider).update(ChecklistModel(
              id: widget.initial!.id,
              profileId: widget.initial!.profileId,
              title: _titleCtrl.text.trim(),
              category: _categoryCtrl.text.trim().isEmpty
                  ? null
                  : _categoryCtrl.text.trim(),
              description:
                  _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              priority: _priority.dbValue,
              dueDate: _dueDate,
              status: _status.dbValue,
              isDefault: widget.initial!.isDefault,
              createdAt: widget.initial!.createdAt,
              updatedAt: now,
            ));
      } else {
        final profile = await ref.read(activeWeddingProfileProvider.future);
        if (profile?.id == null) return;
        await ref.read(checklistRepositoryProvider).insert(ChecklistModel(
              profileId: profile!.id!,
              title: _titleCtrl.text.trim(),
              category: _categoryCtrl.text.trim().isEmpty
                  ? null
                  : _categoryCtrl.text.trim(),
              description:
                  _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              priority: _priority.dbValue,
              dueDate: _dueDate,
              status: _status.dbValue,
              createdAt: now,
              updatedAt: now,
            ));
      }
      ref.invalidate(checklistListProvider);
      ref.invalidate(dashboardDataProvider);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetScaffold(
      title: _isEdit ? 'Edit Checklist' : 'Tambah Checklist',
      onSave: _submit,
      saving: _saving,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Judul'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryCtrl,
              decoration:
                  const InputDecoration(labelText: 'Kategori (opsional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Deskripsi (opsional)'),
            ),
            const SizedBox(height: 14),
            const Text('Prioritas',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ChecklistPriority>(
                segments: ChecklistPriority.values
                    .map((p) => ButtonSegment(
                          value: p,
                          label: Text(
                            p.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ))
                    .toList(),
                selected: {_priority},
                expandedInsets: EdgeInsets.zero, 
                onSelectionChanged: (s) => setState(() => _priority = s.first),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Status',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ChecklistStatus>(
                segments: ChecklistStatus.values
                    .map((s) => ButtonSegment(
                          value: s,
                          label: Text(
                            s.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ))
                    .toList(),
                selected: {_status},
                expandedInsets: EdgeInsets.zero, 
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Tenggat (opsional)'),
              subtitle: Text(_dueDate != null
                  ? DateFormat('d MMM yyyy', 'id_ID').format(_dueDate!)
                  : 'Belum diatur'),
              trailing: _dueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _dueDate = null),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
    );
  }
}