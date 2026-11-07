import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/providers/app_providers.dart';
import 'package:weddingmanagementf/features/reports/data/report_models.dart';
import 'package:weddingmanagementf/features/reports/data/report_repository.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(databaseHelperProvider)),
);

/// Filter aktif di tab Laporan.
final reportFilterProvider = StateProvider<ReportFilter>((ref) {
  return ReportFilter(period: ReportPeriod.thisMonth());
});

final reportDataProvider = FutureProvider<ReportData?>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  if (profile == null || profile.id == null) return null;
  final filter = ref.watch(reportFilterProvider);
  return ref.watch(reportRepositoryProvider).getReport(profile.id!, filter);
});