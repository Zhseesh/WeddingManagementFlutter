import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/providers/app_providers.dart';
import 'package:weddingmanagementf/features/guests/data/guest_model.dart';
import 'package:weddingmanagementf/features/guests/data/guest_repository.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

final guestRepositoryProvider = Provider<GuestRepository>(
  (ref) => GuestRepository(ref.watch(databaseHelperProvider)),
);

final guestListProvider = FutureProvider<List<GuestModel>>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  if (profile == null || profile.id == null) return const [];
  return ref.watch(guestRepositoryProvider).listForProfile(profile.id!);
});