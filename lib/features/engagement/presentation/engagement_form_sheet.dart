import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/engagement/data/engagement_model.dart';
import 'package:weddingmanagementf/features/engagement/presentation/providers/engagement_providers.dart';
import 'package:weddingmanagementf/features/preparation/presentation/sheets/form_sheet_scaffold.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

Future<void> showEngagementFormSheet(
  BuildContext context, {
  EngagementModel? initial,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EngagementFormSheet(initial: initial),
  );
}

class _EngagementFormSheet extends ConsumerStatefulWidget {
  final EngagementModel? initial;
  const _EngagementFormSheet({this.initial});
  @override
  ConsumerState<_EngagementFormSheet> createState() =>
      _EngagementFormSheetState();
}

class _EngagementFormSheetState extends ConsumerState<_EngagementFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _estCtrl;
  late final TextEditingController _actualCtrl;
  late final TextEditingController _notesCtrl;
  EngagementStatus _status = EngagementStatus.pending;
  DateTime? _dueDate;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _categoryCtrl = TextEditingController(text: m?.category ?? '');
    _qtyCtrl = TextEditingController(text: (m?.quantity ?? 1).toString());
    _estCtrl = TextEditingController(
      text: (m?.estimatedPrice ?? 0) > 0
          ? CurrencyFormatter.format(m!.estimatedPrice).replaceAll('Rp ', '')
          : '',
    );
    _actualCtrl = TextEditingController(
      text: (m?.actualPrice ?? 0) > 0
          ? CurrencyFormatter.format(m!.actualPrice).replaceAll('Rp ', '')
          : '',
    );
    _notesCtrl = TextEditingController(text: m?.notes ?? '');
    _status = m?.statusEnum ?? EngagementStatus.pending;
    _dueDate = m?.dueDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _qtyCtrl.dispose();
    _estCtrl.dispose();
    _actualCtrl.dispose();
    _notesCtrl.dispose();
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
      final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
      final est = CurrencyFormatter.parse(_estCtrl.text);
      final actual = CurrencyFormatter.parse(_actualCtrl.text);
      if (_isEdit) {
        await ref.read(engagementRepositoryProvider).update(EngagementModel(
              id: widget.initial!.id,
              profileId: widget.initial!.profileId,
              name: _nameCtrl.text.trim(),
              category:
                  _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
              quantity: qty,
              estimatedPrice: est,
              actualPrice: actual,
              status: _status.dbValue,
              dueDate: _dueDate,
              notes:
                  _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              createdAt: widget.initial!.createdAt,
              updatedAt: now,
            ));
      } else {
        final profile = await ref.read(activeWeddingProfileProvider.future);
        if (profile?.id == null) return;
        await ref.read(engagementRepositoryProvider).insert(EngagementModel(
              profileId: profile!.id!,
              name: _nameCtrl.text.trim(),
              category:
                  _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
              quantity: qty,
              estimatedPrice: est,
              actualPrice: actual,
              status: _status.dbValue,
              dueDate: _dueDate,
              notes:
                  _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              createdAt: now,
              updatedAt: now,
            ));
      }
      ref.invalidate(engagementListProvider);
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
        title: const Text('Hapus item?'),
        content: const Text('Item ini akan dihapus permanen.'),
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
    await ref.read(engagementRepositoryProvider).delete(widget.initial!.id!);
    ref.invalidate(engagementListProvider);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetScaffold(
      title: _isEdit ? 'Edit Item Lamaran' : 'Tambah Item Lamaran',
      onSave: _submit,
      saving: _saving,
      onDelete: _isEdit ? _delete : null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama Item'),
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
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah'),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Harus > 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _estCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga Estimasi (opsional)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _actualCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga Aktual (opsional)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EngagementStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: EngagementStatus.values
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
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
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Catatan (opsional)'),
            ),
          ],
        ),
      ),
    );
  }
}