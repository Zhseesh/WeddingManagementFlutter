import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/installments/data/installment_model.dart';
import 'package:weddingmanagementf/features/installments/presentation/providers/installment_providers.dart';
import 'package:weddingmanagementf/features/preparation/presentation/sheets/form_sheet_scaffold.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

Future<void> showInstallmentFormSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _InstallmentFormSheet(),
  );
}

class _InstallmentFormSheet extends ConsumerStatefulWidget {
  const _InstallmentFormSheet();
  @override
  ConsumerState<_InstallmentFormSheet> createState() =>
      _InstallmentFormSheetState();
}

class _InstallmentFormSheetState extends ConsumerState<_InstallmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _startDate = DateTime.now();
  int? _categoryId;
  final List<_ScheduleDraft> _schedules = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _schedules.add(_ScheduleDraft(dueDate: DateTime.now()));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _totalCtrl.dispose();
    _notesCtrl.dispose();
    for (var s in _schedules) {
      s.amountCtrl.dispose();
    }
    super.dispose();
  }

  int get _schedulesTotal =>
      _schedules.fold(0, (s, d) => s + CurrencyFormatter.parse(d.amountCtrl.text));

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked == null) return;
    setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final total = CurrencyFormatter.parse(_totalCtrl.text);
    if (total <= 0) return;
    if (_schedulesTotal != total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Total termin (${CurrencyFormatter.format(_schedulesTotal)}) harus sama dengan total tagihan (${CurrencyFormatter.format(total)}).')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final profile = await ref.read(activeWeddingProfileProvider.future);
      if (profile?.id == null) return;

      final installment = InstallmentModel(
        profileId: profile!.id!,
        vendorId: _categoryId,
        name: _nameCtrl.text.trim(),
        totalAmount: total,
        startDate: _startDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final schedules = _schedules.asMap().entries.map((e) => ScheduleModel(
        installmentId: 0,
        sequenceNumber: e.key + 1,
        dueDate: e.value.dueDate,
        amount: CurrencyFormatter.parse(e.value.amountCtrl.text),
        status: 'pending',
      )).toList();

      await ref.read(installmentRepositoryProvider).createInstallment(
        installment: installment,
        schedules: schedules,
      );
      
      ref.invalidate(installmentListProvider);
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
      title: 'Tambah Cicilan',
      onSave: _submit,
      saving: _saving,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Tagihan'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total Tagihan', prefixText: 'Rp '),
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
              title: const Text('Tanggal Mulai'),
              subtitle: Text(DateFormat('d MMMM yyyy', 'id_ID').format(_startDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickStartDate,
            ),
            const SizedBox(height: 12),
            const Text('Termin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._schedules.asMap().entries.map((e) => _ScheduleCard(
              index: e.key,
              draft: e.value,
              onRemove: _schedules.length > 1 ? () {
                setState(() => _schedules.removeAt(e.key));
              } : null,
              onDateChanged: (date) => setState(() => e.value.dueDate = date),
              onAmountChanged: () => setState(() {}),
            )),
            TextButton.icon(
              onPressed: () => setState(() => _schedules.add(_ScheduleDraft(dueDate: DateTime.now().add(const Duration(days: 30))))),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Termin'),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.line, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Termin', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(CurrencyFormatter.format(_schedulesTotal), style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleDraft {
  DateTime dueDate;
  final TextEditingController amountCtrl;
  _ScheduleDraft({required this.dueDate, String initialAmount = ''})
      : amountCtrl = TextEditingController(text: initialAmount);
}

class _ScheduleCard extends StatelessWidget {
  final int index;
  final _ScheduleDraft draft;
  final VoidCallback? onRemove;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onAmountChanged;

  const _ScheduleCard({
    required this.index,
    required this.draft,
    this.onRemove,
    required this.onDateChanged,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Termin ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppTheme.error),
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const Divider(),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: draft.dueDate,
                  firstDate: DateTime(DateTime.now().year - 5),
                  lastDate: DateTime(DateTime.now().year + 10),
                );
                if (picked != null) {
                  onDateChanged(DateTime(picked.year, picked.month, picked.day));
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.event, size: 16),
                  const SizedBox(width: 8),
                  Text(DateFormat('d MMM yyyy', 'id_ID').format(draft.dueDate), style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: draft.amountCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => onAmountChanged(),
              decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp ', isDense: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                if (CurrencyFormatter.parse(v) <= 0) return 'Harus > Rp0';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}