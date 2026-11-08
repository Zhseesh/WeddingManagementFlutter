import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/providers/app_providers.dart';
import 'package:weddingmanagementf/features/reminders/data/reminder_model.dart';
import 'package:weddingmanagementf/features/reminders/data/reminder_repository.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => ReminderRepository(ref.watch(databaseHelperProvider)),
);

/// Filter: null = semua, 'active' = belum selesai, 'done' = selesai
final reminderFilterProvider = StateProvider<String?>((ref) => null);

final reminderListProvider = FutureProvider<List<ReminderModel>>((ref) async {
  final profile = await ref.watch(activeWeddingProfileProvider.future);
  if (profile == null || profile.id == null) return const [];
  return ref.watch(reminderRepositoryProvider).listForProfile(profile.id!);
});