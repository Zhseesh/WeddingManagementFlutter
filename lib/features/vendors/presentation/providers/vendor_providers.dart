import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/providers/app_providers.dart';
import 'package:weddingmanagementf/features/vendors/data/vendor_model.dart';
import 'package:weddingmanagementf/features/vendors/data/vendor_repository.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

final vendorRepositoryProvider = Provider<VendorRepository>(
  (ref) => VendorRepository(ref.watch(databaseHelperProvider)),
);

final vendorListProvider =
    FutureProvider<List<VendorWithPayment>>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  if (profile == null || profile.id == null) return const [];
  return ref.watch(vendorRepositoryProvider).listVendors(profile.id!);
});

final vendorDetailProvider =
    FutureProvider.family<VendorDetail?, int>((ref, id) async {
  return ref.watch(vendorRepositoryProvider).getVendorDetail(id);
});

/// Filter status aktif di list vendor
final vendorStatusFilterProvider = StateProvider<VendorStatus?>((ref) => null);

/// Search query
final vendorSearchQueryProvider = StateProvider<String>((ref) => '');