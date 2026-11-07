import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/wedding_profile/presentation/providers/wedding_profile_providers.dart';

enum AppInitState { needsOnboarding, needsSetup, ready }

const _kOnboardingDoneKey = 'onboarding_done';

final appInitProvider = FutureProvider<AppInitState>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool(_kOnboardingDoneKey) ?? false;
  if (!onboardingDone) return AppInitState.needsOnboarding;

  final profile =
      await ref.watch(weddingProfileRepositoryProvider).getActiveProfile();
  if (profile == null) return AppInitState.needsSetup;

  return AppInitState.ready;
});

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDoneKey, true);
}