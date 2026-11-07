import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/providers/app_providers.dart';
import 'package:weddingmanagementf/features/engagement/data/engagement_model.dart';
import 'package:weddingmanagementf/features/engagement/data/engagement_repository.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

final engagementRepositoryProvider = Provider<EngagementRepository>(
  (ref) => EngagementRepository(ref.watch(databaseHelperProvider)),
);

final engagementListProvider =
    FutureProvider<List<EngagementModel>>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  if (profile == null || profile.id == null) return const [];
  return ref.watch(engagementRepositoryProvider).listForProfile(profile.id!);
});

/// Filter: null = semua, 'active' = belum selesai, 'done' = selesai
final engagementFilterProvider = StateProvider<String?>((ref) => null);