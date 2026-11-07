import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:weddingmanagementf/core/utils/currency_formatter.dart';
import 'package:weddingmanagementf/features/budget/presentation/providers/budget_providers.dart';
import 'package:weddingmanagementf/features/installments/data/installment_model.dart';
import 'package:weddingmanagementf/features/installments/presentation/providers/installment_providers.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

class InstallmentFormScreen extends ConsumerStatefulWidget {
  const InstallmentFormScreen({super.key});

  @override
  ConsumerState<InstallmentFormScreen> createState() =>
      _InstallmentFormScreenState();
}

class _InstallmentFormScreenState
    extends ConsumerState<InstallmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _startDate = DateTime.now();
  int? _vendorId;
  final List<_ScheduleDraft> _schedules = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Start with 1 termin kosong
    _schedules.add(_ScheduleDraft(dueDate: DateTime.now()));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _totalCtrl.dispose();
    _notesCtrl.dispose();
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
    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _addSchedule() async {
    setState(() {
      _schedules.add(_ScheduleDraft(
        dueDate: DateTime.now().add(const Duration(days: 30)),
      ));
    });
  }

  Future<void> _pickScheduleDate(_ScheduleDraft d) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: d.dueDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked == null) return;
    setState(() {
      d.dueDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final total = CurrencyFormatter.parse(_totalCtrl.text);
    if (total <= 0) {
      _showSnack('Total tagihan harus lebih dari Rp0.');
      return;
    }
    if (_schedules.isEmpty) {
      _showSnack('Minimal 1 termin.');
      return;
    }
    final schedulesTotal = _schedulesTotal;
    if (schedulesTotal != total) {
      _showSnack(
        'Total termin (${CurrencyFormatter.format(schedulesTotal)}) '
        'harus sama dengan total tagihan (${CurrencyFormatter.format(total)}).',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final profile = await ref.read(activeWeddingProfileProvider.future);
      if (profile == null || profile.id == null) {
        _showSnack('Profil tidak ditemukan.');
        return;
      }
      final now = DateTime.now();
      final installment = InstallmentModel(
        profileId: profile.id!,
        vendorId: _vendorId,
        name: _nameCtrl.text.trim(),
        totalAmount: total,
        startDate: _startDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );
      final schedules = <ScheduleModel>[];
      for (var i = 0; i < _schedules.length; i++) {
        schedules.add(ScheduleModel(
          installmentId: 0, // placeholder, akan di-set di repo
          sequenceNumber: i + 1,
          dueDate: _schedules[i].dueDate,
          amount: CurrencyFormatter.parse(_schedules[i].amountCtrl.text),
          status: 'pending',
        ));
      }

      await ref.read(installmentRepositoryProvider).createInstallment(
            installment: installment,
            schedules: schedules,
          );
      ref.invalidate(installmentListProvider);
      if (!mounted) return;
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
    final scheme = Theme.of(context).colorScheme;
    final catsAsync = ref.watch(budgetCategoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Cicilan')),
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
                  labelText: 'Nama Tagihan',
                  prefixIcon: Icon(Icons.receipt_long),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _totalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Tagihan',
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
                  title: const Text('Tanggal Mulai'),
                  subtitle: Text(
                    DateFormat('d MMMM yyyy', 'id_ID').format(_startDate),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(height: 12),
              catsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (cats) => DropdownButtonFormField<int?>(
                  initialValue: _vendorId,
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
                  onChanged: (v) => setState(() => _vendorId = v),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Termin',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addSchedule,
                    icon: const Icon(Icons.add),
                    label: const Text('Termin'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ..._schedules.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                return _ScheduleDraftCard(
                  index: i,
                  draft: d,
                  onPickDate: () => _pickScheduleDate(d),
                  onAmountChanged: () => setState(() {}),
                  onRemove: _schedules.length > 1
                      ? () {
                          setState(() {
                            _schedules.removeAt(i);
                          });
                        }
                      : null,
                );
              }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color.lerp(scheme.surface, scheme.primary, 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total ${_schedules.length} termin: '
                        '${CurrencyFormatter.format(_schedulesTotal)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
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
                    : const Text('Simpan Cicilan'),
              ),
            ],
          ),
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

class _ScheduleDraftCard extends StatelessWidget {
  final int index;
  final _ScheduleDraft draft;
  final VoidCallback onPickDate;
  final VoidCallback onAmountChanged;
  final VoidCallback? onRemove;

  const _ScheduleDraftCard({
    required this.index,
    required this.draft,
    required this.onPickDate,
    required this.onAmountChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Termin ${index + 1}',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            InkWell(
              onTap: onPickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.event, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('d MMM yyyy', 'id_ID').format(draft.dueDate),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ),
            TextFormField(
              controller: draft.amountCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => onAmountChanged(),
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                isDense: true,
              ),
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