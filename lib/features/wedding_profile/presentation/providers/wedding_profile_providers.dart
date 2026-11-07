import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/wedding_profile_model.dart';
import '../../data/wedding_profile_repository.dart';

final weddingProfileRepositoryProvider = Provider<WeddingProfileRepository>(
  (ref) => WeddingProfileRepository(ref.watch(databaseHelperProvider)),
);

final activeWeddingProfileProvider = FutureProvider<WeddingProfile?>(
  (ref) async => ref.watch(weddingProfileRepositoryProvider).getActiveProfile(),
);