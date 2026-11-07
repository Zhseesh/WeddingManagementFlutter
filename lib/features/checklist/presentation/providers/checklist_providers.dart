import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/providers/app_providers.dart';
import 'package:weddingmanagementf/features/checklist/data/checklist_model.dart';
import 'package:weddingmanagementf/features/checklist/data/checklist_repository.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

final checklistRepositoryProvider = Provider<ChecklistRepository>(
  (ref) => ChecklistRepository(ref.watch(databaseHelperProvider)),
);

/// Filter: null = semua, 'active' = belum selesai, 'done' = selesai
final checklistFilterProvider = StateProvider<String?>((ref) => null);

final checklistListProvider =
    FutureProvider<List<ChecklistModel>>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  if (profile == null || profile.id == null) return const [];
  return ref.watch(checklistRepositoryProvider).listForProfile(profile.id!);
});