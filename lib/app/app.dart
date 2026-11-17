import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/app/theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'router.dart';

class WeddingApp extends ConsumerWidget { // 👈 Ubah jadi ConsumerWidget
  const WeddingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(themeColorProvider); // 👈 Pantau warna

    return MaterialApp.router(
      title: 'Wedding Planner & Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(accentColor),
      darkTheme: AppTheme.darkTheme(accentColor),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}