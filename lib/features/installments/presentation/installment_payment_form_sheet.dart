import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/installments/presentation/providers/installment_providers.dart';
import 'package:weddingmanagementf/features/preparation/presentation/sheets/form_sheet_scaffold.dart';
import 'package:weddingmanagementf/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

Future<void> showInstallmentPaymentFormSheet(
  BuildContext context, {
  required int installmentId,
  required int scheduleId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InstallmentPaymentFormSheet(
      installmentId: installmentId,
      scheduleId: scheduleId,
    ),
  );
}

class _InstallmentPaymentFormSheet extends ConsumerStatefulWidget {
  final int installmentId;
  final int scheduleId;
  const _InstallmentPaymentFormSheet({
    required this.installmentId,
    required this.scheduleId,
  });
  @override
  ConsumerState<_InstallmentPaymentFormSheet> createState() =>
      _InstallmentPaymentFormSheetState();
}

class _InstallmentPaymentFormSheetState
    extends ConsumerState<_InstallmentPaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _method = 'Transfer';
  int? _categoryId;
  bool _saving = false;
  bool _initialized = false;

  static const _methods = ['Cash', 'Transfer', 'E-Wallet', 'Kartu', 'Lainnya'];

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

  void _autoFill() {
    if (_initialized) return;
    final schedule = ref.read(scheduleByIdProvider(widget.scheduleId)).asData?.value;
    final paid = ref.read(schedulePaidProvider(widget.scheduleId)).asData?.value;
    if (schedule != null) {
      final remaining = schedule.amount - (paid ?? 0);
      if (remaining > 0) {
        _amountCtrl.text = CurrencyFormatter.format(remaining).replaceAll('Rp ', '');
      }
      _initialized = true;
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = CurrencyFormatter.parse(_amountCtrl.text);
    if (amount <= 0) return;

    final schedule = ref.read(scheduleByIdProvider(widget.scheduleId)).asData?.value;
    final paid = ref.read(schedulePaidProvider(widget.scheduleId)).asData?.value ?? 0;
    if (schedule == null) return;
    
    if (amount > (schedule.amount - paid)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Melebihi Sisa'),
          content: const Text('Nominal melebihi sisa termin. Lanjutkan?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lanjut')),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _saving = true);
    try {
      final profile = await ref.read(activeWeddingProfileProvider.future);
      if (profile?.id == null) return;

      await ref.read(installmentRepositoryProvider).recordSchedulePayment(
        schedule: schedule,
        profileId: profile!.id!,
        categoryId: _categoryId,
        amount: amount,
        date: _date,
        paymentMethod: _method,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );

      ref.invalidate(installmentDetailProvider(widget.installmentId));
      ref.invalidate(installmentListProvider);
      ref.invalidate(scheduleByIdProvider(widget.scheduleId));
      ref.invalidate(schedulePaidProvider(widget.scheduleId));
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
    final scheduleAsync = ref.watch(scheduleByIdProvider(widget.scheduleId));
    final paidAsync = ref.watch(schedulePaidProvider(widget.scheduleId));
    final catsAsync = ref.watch(budgetCategoriesProvider);
    final palette = AppTheme.of(context);

    if (scheduleAsync.hasValue && paidAsync.hasValue) {
      _autoFill();
    }

    return FormSheetScaffold(
      title: 'Bayar Termin',
      onSave: _submit,
      saving: _saving,
      child: scheduleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
        data: (schedule) {
          if (schedule == null) return const Text('Termin tidak ditemukan.');
          final paid = paidAsync.asData?.value ?? 0;
          final remaining = (schedule.amount - paid).clamp(0, schedule.amount);

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: palette.softBg, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sisa Tagihan', style: TextStyle(fontSize: 12, color: palette.muted)),
                          Text(CurrencyFormatter.format(remaining), style: TextStyle(fontWeight: FontWeight.bold, color: palette.ink)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Jatuh tempo', style: TextStyle(fontSize: 12, color: palette.muted)),
                          Text(DateFormat('d MMM yyyy', 'id_ID').format(schedule.dueDate), style: TextStyle(fontSize: 12, color: palette.ink)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 8),
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
                  decoration: const InputDecoration(labelText: 'Metode'),
                  items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _method = v ?? 'Transfer'),
                ),
                const SizedBox(height: 12),
                catsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (cats) => DropdownButtonFormField<int?>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Kategori (opsional)'),
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
          );
        },
      ),
    );
  }
}