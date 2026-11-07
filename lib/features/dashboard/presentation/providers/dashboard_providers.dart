import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../wedding_profile/presentation/providers/wedding_profile_providers.dart';
import '../../data/dashboard_data.dart';
import '../../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(databaseHelperProvider)),
);

final dashboardDataProvider = FutureProvider<DashboardData?>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  if (profile == null || profile.id == null) return null;
  return ref.watch(dashboardRepositoryProvider).getDashboardData(profile.id!);
});