import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:weddingmanagementf/features/installments/presentation/providers/installment_providers.dart';
import 'package:weddingmanagementf/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

class InstallmentPaymentFormScreen extends ConsumerStatefulWidget {
  final int installmentId;
  final int scheduleId;
  const InstallmentPaymentFormScreen({
    super.key,
    required this.installmentId,
    required this.scheduleId,
  });

  @override
  ConsumerState<InstallmentPaymentFormScreen> createState() =>
      _InstallmentPaymentFormScreenState();
}

class _InstallmentPaymentFormScreenState
    extends ConsumerState<InstallmentPaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _method = 'Transfer';
  int? _categoryId;
  bool _submitting = false;
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
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
    });
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
    if (amount <= 0) {
      _showSnack('Nominal harus > Rp0.');
      return;
    }

    final schedule =
        ref.read(scheduleByIdProvider(widget.scheduleId)).asData?.value;
    final paid = ref.read(schedulePaidProvider(widget.scheduleId)).asData?.value ??
        0;
    if (schedule == null) {
      _showSnack('Termin tidak ditemukan.');
      return;
    }
    final remaining = schedule.amount - paid;
    if (amount > remaining) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pembayaran Melebihi Sisa Termin'),
          content: Text(
            'Nominal (${CurrencyFormatter.format(amount)}) melebihi '
            'sisa termin (${CurrencyFormatter.format(remaining)}). Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _submitting = true);
    try {
      final profile = await ref.read(activeWeddingProfileProvider.future);
      if (profile == null || profile.id == null) {
        _showSnack('Profil tidak ditemukan.');
        return;
      }
      await ref.read(installmentRepositoryProvider).recordSchedulePayment(
            schedule: schedule,
            profileId: profile.id!,
            categoryId: _categoryId,
            amount: amount,
            date: _date,
            paymentMethod: _method,
            description:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran tercatat.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack('Gagal: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleByIdProvider(widget.scheduleId));
    final paidAsync = ref.watch(schedulePaidProvider(widget.scheduleId));
    final catsAsync = ref.watch(budgetCategoriesProvider);

    // Auto-fill amount setelah data siap
    if (scheduleAsync.hasValue && paidAsync.hasValue) {
      _autoFill();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bayar Termin')),
      body: SafeArea(
        child: scheduleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (schedule) {
            if (schedule == null) {
              return const Center(child: Text('Termin tidak ditemukan.'));
            }
            final paid = paidAsync.asData?.value ?? 0;
            final remaining = (schedule.amount - paid).clamp(0, schedule.amount);
            final scheme = Theme.of(context).colorScheme;
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Termin ${schedule.sequenceNumber}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          _row(context, 'Jatuh tempo',
                              DateFormat('d MMMM yyyy', 'id_ID').format(schedule.dueDate)),
                          _row(context, 'Total termin',
                              CurrencyFormatter.format(schedule.amount)),
                          _row(context, 'Sudah dibayar',
                              CurrencyFormatter.format(paid)),
                          _row(
                            context,
                            'Sisa',
                            CurrencyFormatter.format(remaining),
                            color: remaining > 0 ? scheme.error : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nominal Pembayaran',
                      prefixText: 'Rp ',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                      if (CurrencyFormatter.parse(v) <= 0) return 'Harus > Rp0';
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
                  DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(
                      labelText: 'Metode',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: _methods
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _method = v ?? 'Transfer'),
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
                    controller: _descCtrl,
                    maxLines: 2,
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
                        : const Text('Simpan Pembayaran'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}