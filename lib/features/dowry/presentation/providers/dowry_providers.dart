import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/providers/app_providers.dart';
import 'package:weddingmanagementf/features/dowry/data/dowry_model.dart';
import 'package:weddingmanagementf/features/dowry/data/dowry_repository.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

final dowryRepositoryProvider = Provider<DowryRepository>(
  (ref) => DowryRepository(ref.watch(databaseHelperProvider)),
);

final dowryListProvider = FutureProvider<List<DowryModel>>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  if (profile == null || profile.id == null) return const [];
  return ref.watch(dowryRepositoryProvider).listForProfile(profile.id!);
});

/// Filter: null = semua, 'active' = belum dibeli, 'done' = sudah dibeli
final dowryFilterProvider = StateProvider<String?>((ref) => null);