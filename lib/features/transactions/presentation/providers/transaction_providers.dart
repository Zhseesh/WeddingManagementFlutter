import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/providers/app_providers.dart';
import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';
import 'package:weddingmanagementf/features/transactions/data/transaction_repository.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(databaseHelperProvider)),
);

/// Filter type aktif di tab Keuangan: null = semua, 'income', 'expense'
final transactionTypeFilterProvider =
    StateProvider<String?>((ref) => null);

final transactionListProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  if (profile == null || profile.id == null) return const [];
  final typeFilter = ref.watch(transactionTypeFilterProvider);
  return ref.watch(transactionRepositoryProvider).listForProfile(
        profile.id!,
        type: typeFilter,
      );
});

final transactionByIdProvider =
    FutureProvider.family<TransactionModel?, int>((ref, id) async {
  return ref.watch(transactionRepositoryProvider).getById(id);
});