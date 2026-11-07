import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/providers/app_providers.dart';
import 'package:weddingmanagementf/features/installments/data/installment_model.dart';
import 'package:weddingmanagementf/features/installments/data/installment_repository.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

final installmentRepositoryProvider = Provider<InstallmentRepository>(
  (ref) => InstallmentRepository(ref.watch(databaseHelperProvider)),
);

final installmentListProvider =
    FutureProvider<List<InstallmentWithSummary>>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  if (profile == null || profile.id == null) return const [];
  return ref.watch(installmentRepositoryProvider).listInstallments(profile.id!);
});

final installmentDetailProvider =
    FutureProvider.family<InstallmentDetail?, int>((ref, id) async {
  return ref.watch(installmentRepositoryProvider).getDetail(id);
});

final scheduleByIdProvider =
    FutureProvider.family<ScheduleModel?, int>((ref, id) async {
  return ref.watch(installmentRepositoryProvider).getScheduleById(id);
});

final schedulePaidProvider =
    FutureProvider.family<int, int>((ref, id) async {
  return ref.watch(installmentRepositoryProvider).getSchedulePaidAmount(id);
});