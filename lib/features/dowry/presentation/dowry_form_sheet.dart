import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/dowry/data/dowry_model.dart';
import 'package:weddingmanagementf/features/dowry/presentation/providers/dowry_providers.dart';
import 'package:weddingmanagementf/features/preparation/presentation/sheets/form_sheet_scaffold.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

Future<void> showDowryFormSheet(BuildContext context, {DowryModel? initial}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DowryFormSheet(initial: initial),
  );
}

class _DowryFormSheet extends ConsumerStatefulWidget {
  final DowryModel? initial;
  const _DowryFormSheet({this.initial});
  @override
  ConsumerState<_DowryFormSheet> createState() => _DowryFormSheetState();
}

class _DowryFormSheetState extends ConsumerState<_DowryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _estCtrl;
  late final TextEditingController _actualCtrl;
  late final TextEditingController _notesCtrl;
  DowryStatus _status = DowryStatus.notPurchased;
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
    _status = m?.statusEnum ?? DowryStatus.notPurchased;
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
      final est = CurrencyFormatter.parse(_estCtrl.text);
      final actual = CurrencyFormatter.parse(_actualCtrl.text);
      if (_isEdit) {
        await ref.read(dowryRepositoryProvider).update(DowryModel(
              id: widget.initial!.id,
              profileId: widget.initial!.profileId,
              name: _nameCtrl.text.trim(),
              category:
                  _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
              quantity: qty,
              estimatedPrice: est,
              actualPrice: actual,
              status: _status.dbValue,
              notes:
                  _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              createdAt: widget.initial!.createdAt,
              updatedAt: now,
            ));
      } else {
        final profile = await ref.read(activeWeddingProfileProvider.future);
        if (profile?.id == null) return;
        await ref.read(dowryRepositoryProvider).insert(DowryModel(
              profileId: profile!.id!,
              name: _nameCtrl.text.trim(),
              category:
                  _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
              quantity: qty,
              estimatedPrice: est,
              actualPrice: actual,
              status: _status.dbValue,
              notes:
                  _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              createdAt: now,
              updatedAt: now,
            ));
      }
      ref.invalidate(dowryListProvider);
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
      title: _isEdit ? 'Edit Seserahan' : 'Tambah Seserahan',
      onSave: _submit,
      saving: _saving,
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
            DropdownButtonFormField<DowryStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: DowryStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
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