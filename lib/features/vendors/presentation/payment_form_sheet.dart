import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/preparation/presentation/sheets/form_sheet_scaffold.dart';
import 'package:weddingmanagementf/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:weddingmanagementf/features/vendors/data/vendor_model.dart';
import 'package:weddingmanagementf/features/vendors/presentation/providers/vendor_providers.dart';

Future<void> showPaymentFormSheet(
  BuildContext context,
  VendorWithPayment summary,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentFormSheet(summary: summary),
  );
}

class _PaymentFormSheet extends ConsumerStatefulWidget {
  final VendorWithPayment summary;
  const _PaymentFormSheet({required this.summary});
  @override
  ConsumerState<_PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<_PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final _descCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _method = 'Transfer';
  int? _categoryId; // <-- STATE BARU
  bool _saving = false;
  static const _methods = ['Cash', 'Transfer', 'E-Wallet', 'Kartu', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.summary.remaining > 0
          ? CurrencyFormatter.format(widget.summary.remaining)
              .replaceAll('Rp ', '')
          : '',
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
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
      await ref.read(vendorRepositoryProvider).recordPayment(
            vendor: widget.summary.vendor,
            categoryId: _categoryId, // <-- KIRIM KE REPO
            amount: amount,
            date: _date,
            paymentMethod: _method,
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          );
      ref.invalidate(vendorListProvider);
      ref.invalidate(vendorDetailProvider(widget.summary.vendor.id!));
      ref.invalidate(transactionListProvider);
      ref.invalidate(dashboardDataProvider);
      ref.invalidate(budgetSummaryProvider);
      ref.invalidate(categorySpendingProvider);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final catsAsync = ref.watch(budgetCategoriesProvider);
    final palette = AppTheme.of(context); // <-- AMBIL KATEGORI

    return FormSheetScaffold(
      title: 'Catat Pembayaran',
      onSave: _submit,
      saving: _saving,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.softBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.vendor.name,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: palette.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sisa: ${CurrencyFormatter.format(s.remaining)}',
                    style: TextStyle(fontSize: 12, color: palette.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal Pembayaran', prefixText: 'Rp '),
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
            DropdownButtonFormField<String>(
              initialValue: _method,
              borderRadius: BorderRadius.circular(16),
              dropdownColor: palette.surface,
              decoration: const InputDecoration(labelText: 'Metode'),
              items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _method = v ?? 'Transfer'),
            ),
            const SizedBox(height: 12),
            // DROPDOWN KATEGORI BARU
            catsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (cats) => DropdownButtonFormField<int?>(
                initialValue: _categoryId,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: palette.surface,
                decoration: const InputDecoration(labelText: 'Kategori Anggaran (opsional)'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('— Tanpa kategori —')),
                  ...cats.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            ),
          ],
        ),
      ),
    );
  }
}