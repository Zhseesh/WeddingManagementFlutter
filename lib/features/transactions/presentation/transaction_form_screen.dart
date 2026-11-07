import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';
import 'package:weddingmanagementf/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState
    extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _type = 'expense';
  DateTime _date = DateTime.now();
  int? _categoryId;
  String _paymentMethod = 'Cash';
  bool _submitting = false;

  static const _methods = ['Cash', 'Transfer', 'E-Wallet', 'Kartu', 'Lainnya'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _sourceCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = CurrencyFormatter.parse(_amountCtrl.text);
    if (amount <= 0) {
      _showSnack('Nominal harus lebih dari Rp0.');
      return;
    }

    final profile = await ref.read(activeWeddingProfileProvider.future);
    if (profile == null || profile.id == null) {
      _showSnack('Profil tidak ditemukan.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final tx = TransactionModel(
        profileId: profile.id!,
        categoryId: _categoryId,
        type: _type,
        amount: amount,
        transactionDate: _date,
        source: _sourceCtrl.text.trim().isEmpty ? null : _sourceCtrl.text.trim(),
        paymentMethod: _paymentMethod,
        description:
            _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        status: 'posted',
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(transactionRepositoryProvider).insert(tx);

      // Refresh semua data turunan
      ref.invalidate(transactionListProvider);
      ref.invalidate(dashboardDataProvider);
      ref.invalidate(budgetSummaryProvider);
      ref.invalidate(categorySpendingProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil disimpan.')),
      );
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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(budgetCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'expense',
                    icon: Icon(Icons.arrow_upward),
                    label: Text('Pengeluaran'),
                  ),
                  ButtonSegment(
                    value: 'income',
                    icon: Icon(Icons.arrow_downward),
                    label: Text('Pemasukan'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  if (CurrencyFormatter.parse(v) <= 0) {
                    return 'Harus lebih dari Rp0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Tanggal'),
                  subtitle: Text(
                    DateFormat('d MMMM yyyy', 'id_ID').format(_date),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Kategori error: $e'),
                data: (cats) {
                  return DropdownButtonFormField<int?>(
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
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sourceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sumber / Penerima (opsional)',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Metode Pembayaran',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: _methods
                    .map((m) => DropdownMenuItem<String>(
                          value: m,
                          child: Text(m),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _paymentMethod = v ?? 'Cash'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
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
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}