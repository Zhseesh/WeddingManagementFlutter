import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/preparation/presentation/sheets/form_sheet_scaffold.dart';
import 'package:weddingmanagementf/features/vendors/data/vendor_model.dart';
import 'package:weddingmanagementf/features/vendors/presentation/providers/vendor_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

Future<void> showVendorFormSheet(BuildContext context, {VendorModel? initial}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VendorFormSheet(initial: initial),
  );
}

class _VendorFormSheet extends ConsumerStatefulWidget {
  final VendorModel? initial;
  const _VendorFormSheet({this.initial});
  @override
  ConsumerState<_VendorFormSheet> createState() => _VendorFormSheetState();
}

class _VendorFormSheetState extends ConsumerState<_VendorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _notesCtrl;
  VendorStatus _status = VendorStatus.notContacted;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final v = widget.initial;
    _nameCtrl = TextEditingController(text: v?.name ?? '');
    _contactCtrl = TextEditingController(text: v?.contactName ?? '');
    _phoneCtrl = TextEditingController(text: v?.phone ?? '');
    _addressCtrl = TextEditingController(text: v?.address ?? '');
    _priceCtrl = TextEditingController(
      text: v != null
          ? CurrencyFormatter.format(v.agreedPrice).replaceAll('Rp ', '')
          : '',
    );
    _notesCtrl = TextEditingController(text: v?.notes ?? '');
    _status = v?.statusEnum ?? VendorStatus.notContacted;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final price = CurrencyFormatter.parse(_priceCtrl.text);
      if (_isEdit) {
        final updated = widget.initial!.copyWith(
          name: _nameCtrl.text.trim(),
          contactName: _contactCtrl.text.trim().isEmpty
              ? null
              : _contactCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          agreedPrice: price,
          status: _status.dbValue,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
        await ref.read(vendorRepositoryProvider).updateVendor(updated);
      } else {
        final profile = await ref.read(activeWeddingProfileProvider.future);
        if (profile?.id == null) return;
        await ref.read(vendorRepositoryProvider).insertVendor(VendorModel(
              profileId: profile!.id!,
              name: _nameCtrl.text.trim(),
              contactName: _contactCtrl.text.trim().isEmpty
                  ? null
                  : _contactCtrl.text.trim(),
              phone:
                  _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
              address: _addressCtrl.text.trim().isEmpty
                  ? null
                  : _addressCtrl.text.trim(),
              agreedPrice: price,
              status: _status.dbValue,
              notes:
                  _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
              createdAt: now,
              updatedAt: now,
            ));
      }
      ref.invalidate(vendorListProvider);
      if (_isEdit && widget.initial!.id != null) {
        ref.invalidate(vendorDetailProvider(widget.initial!.id!));
      }
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
      title: _isEdit ? 'Edit Vendor' : 'Tambah Vendor',
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
              decoration: const InputDecoration(labelText: 'Nama Vendor'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga Kesepakatan',
                prefixText: 'Rp ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                if (CurrencyFormatter.parse(v) < 0) return 'Tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactCtrl,
              decoration:
                  const InputDecoration(labelText: 'Nama Kontak (opsional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Telepon (opsional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Alamat (opsional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<VendorStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: VendorStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 12),
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