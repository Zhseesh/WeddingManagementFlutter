import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/preparation/presentation/sheets/form_sheet_scaffold.dart';
import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';
import 'package:weddingmanagementf/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

Future<void> showTransactionFormSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TransactionFormSheet(),
  );
}

class _TransactionFormSheet extends ConsumerStatefulWidget {
  const _TransactionFormSheet();
  @override
  ConsumerState<_TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<_TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _type = 'expense';
  DateTime _date = DateTime.now();
  int? _categoryId;
  String _paymentMethod = 'Cash';
  bool _saving = false;

  static const _methods = ['Cash', 'Transfer', 'E-Wallet', 'Kartu', 'Lainnya'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _sourceCtrl.dispose();
    _descCtrl.dispose();
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
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = CurrencyFormatter.parse(_amountCtrl.text);
    if (amount <= 0) return;

    setState(() => _saving = true);
    try {
      final profile = await ref.read(activeWeddingProfileProvider.future);
      if (profile?.id == null) return;

      final tx = TransactionModel(
        profileId: profile!.id!,
        categoryId: _categoryId,
        type: _type,
        amount: amount,
        transactionDate: _date,
        source: _sourceCtrl.text.trim().isEmpty ? null : _sourceCtrl.text.trim(),
        paymentMethod: _paymentMethod,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        status: 'posted',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(transactionRepositoryProvider).insert(tx);

      ref.invalidate(transactionListProvider);
      ref.invalidate(dashboardDataProvider);
      ref.invalidate(budgetSummaryProvider);
      ref.invalidate(categorySpendingProvider);

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
    final categoriesAsync = ref.watch(budgetCategoriesProvider);

    return FormSheetScaffold(
      title: 'Tambah Transaksi',
      onSave: _submit,
      saving: _saving,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'expense',
                    icon: Icon(Icons.arrow_upward, size: 16),
                    label: Text('Pengeluaran', style: TextStyle(fontSize: 13)),
                  ),
                  ButtonSegment(
                    value: 'income',
                    icon: Icon(Icons.arrow_downward, size: 16),
                    label: Text('Pemasukan', style: TextStyle(fontSize: 13)),
                  ),
                ],
                selected: {_type},
                expandedInsets: EdgeInsets.zero,
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                if (CurrencyFormatter.parse(v) <= 0) return 'Harus > Rp0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Tanggal'),
              subtitle: Text(DateFormat('d MMMM yyyy', 'id_ID').format(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            const SizedBox(height: 4),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (cats) => DropdownButtonFormField<int?>(
                initialValue: _categoryId,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: AppTheme.of(context).surface,
                decoration: const InputDecoration(labelText: 'Kategori (opsional)'),
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
              controller: _sourceCtrl,
              decoration: const InputDecoration(
                  labelText: 'Sumber / Penerima (opsional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              borderRadius: BorderRadius.circular(16),
              dropdownColor: AppTheme.of(context).surface,
              decoration: const InputDecoration(labelText: 'Metode'),
              items: _methods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _paymentMethod = v ?? 'Cash'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)'),
            ),
          ],
        ),
      ),
    );
  }
}