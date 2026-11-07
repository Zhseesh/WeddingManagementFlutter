import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/providers/app_providers.dart';
import 'package:weddingmanagementf/features/budget/data/budget_model.dart';
import 'package:weddingmanagementf/features/budget/data/budget_repository.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(ref.watch(databaseHelperProvider)),
);

final activeBudgetProvider = FutureProvider<BudgetModel?>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  if (profile == null || profile.id == null) return null;
  return ref.watch(budgetRepositoryProvider).getActiveBudget(profile.id!);
});

final budgetSummaryProvider = FutureProvider<BudgetSummary?>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  if (profile == null || profile.id == null) return null;
  return ref.watch(budgetRepositoryProvider).getSummary(profile.id!);
});

final categorySpendingProvider =
    FutureProvider<List<CategorySpending>>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  final budget = await ref.watch(activeBudgetProvider.future);
  if (profile == null ||
      profile.id == null ||
      budget == null ||
      budget.id == null) {
    return const [];
  }
  return ref
      .watch(budgetRepositoryProvider)
      .getCategorySpending(profile.id!, budget.id!);
});

final budgetCategoriesProvider =
    FutureProvider<List<BudgetCategoryModel>>((ref) async {
  final budget = await ref.watch(activeBudgetProvider.future);
  if (budget == null || budget.id == null) return const [];
  return ref.watch(budgetRepositoryProvider).listCategories(budget.id!);
});