import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/vendors/data/vendor_model.dart';
import 'package:weddingmanagementf/features/vendors/presentation/providers/vendor_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

class VendorFormScreen extends ConsumerStatefulWidget {
  final VendorModel? initial;
  const VendorFormScreen({super.key, this.initial});

  @override
  ConsumerState<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends ConsumerState<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _notesCtrl;

  int? _categoryId;
  DateTime? _bookingDate;
  DateTime? _eventDate;
  VendorStatus _status = VendorStatus.notContacted;
  bool _submitting = false;

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
      text: v != null ? CurrencyFormatter.format(v.agreedPrice).replaceAll('Rp ', '') : '',
    );
    _notesCtrl = TextEditingController(text: v?.notes ?? '');
    _categoryId = v?.categoryId;
    _bookingDate = v?.bookingDate;
    _eventDate = v?.eventDate;
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

  Future<void> _pickDate({required bool booking}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (booking ? _bookingDate : _eventDate) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
    );
    if (picked == null) return;
    setState(() {
      final d = DateTime(picked.year, picked.month, picked.day);
      if (booking) {
        _bookingDate = d;
      } else {
        _eventDate = d;
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final price = CurrencyFormatter.parse(_priceCtrl.text);
    if (price < 0) {
      _showSnack('Harga tidak boleh negatif.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      if (_isEdit) {
        final updated = widget.initial!.copyWith(
          categoryId: _categoryId,
          name: _nameCtrl.text.trim(),
          contactName: _nullIfEmpty(_contactCtrl.text),
          phone: _nullIfEmpty(_phoneCtrl.text),
          address: _nullIfEmpty(_addressCtrl.text),
          agreedPrice: price,
          bookingDate: _bookingDate,
          eventDate: _eventDate,
          status: _status.dbValue,
          notes: _nullIfEmpty(_notesCtrl.text),
        );
        await ref.read(vendorRepositoryProvider).updateVendor(updated);
        ref.invalidate(vendorDetailProvider(widget.initial!.id!));
      } else {
        final profile = await ref.read(activeWeddingProfileProvider.future);
        if (profile == null || profile.id == null) {
          _showSnack('Profil tidak ditemukan.');
          return;
        }
        final vendor = VendorModel(
          profileId: profile.id!,
          categoryId: _categoryId,
          name: _nameCtrl.text.trim(),
          contactName: _nullIfEmpty(_contactCtrl.text),
          phone: _nullIfEmpty(_phoneCtrl.text),
          address: _nullIfEmpty(_addressCtrl.text),
          agreedPrice: price,
          bookingDate: _bookingDate,
          eventDate: _eventDate,
          status: _status.dbValue,
          notes: _nullIfEmpty(_notesCtrl.text),
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(vendorRepositoryProvider).insertVendor(vendor);
      }
      ref.invalidate(vendorListProvider);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack('Gagal menyimpan: $e');
    }
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(budgetCategoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Vendor' : 'Tambah Vendor'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Vendor',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              catsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (cats) => DropdownButtonFormField<int?>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Kategori (opsional)',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('— Tanpa kategori —'),
                    ),
                    ...cats.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Kontak (opsional)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telepon (opsional)',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat (opsional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Kesepakatan',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  if (CurrencyFormatter.parse(v) < 0) return 'Tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.event_available),
                      title: const Text('Tanggal Booking'),
                      subtitle: Text(_bookingDate != null
                          ? DateFormat('d MMM yyyy', 'id_ID').format(_bookingDate!)
                          : 'Belum diatur'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickDate(booking: true),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Tanggal Acara'),
                      subtitle: Text(_eventDate != null
                          ? DateFormat('d MMM yyyy', 'id_ID').format(_eventDate!)
                          : 'Belum diatur'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _pickDate(booking: false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VendorStatus>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: VendorStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
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
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Vendor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}