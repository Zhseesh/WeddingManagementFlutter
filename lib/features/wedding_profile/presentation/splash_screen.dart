import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:weddingmanagementf/core/services/notification_service.dart';
import '../../../app/app_init.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    try {
      final state = await ref.read(appInitProvider.future);
      if (!mounted) return;
      switch (state) {
        case AppInitState.needsOnboarding:
          NotificationService.instance.consumePendingPayload();
          context.go('/onboarding');
        case AppInitState.needsSetup:
          NotificationService.instance.consumePendingPayload();
          context.go('/setup-profile');
        case AppInitState.ready:
          final payload = NotificationService.instance.consumePendingPayload();
          if (payload != null) {
            NotificationService.instance.handlePayload(payload);
          }
          context.go('/app');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inisialisasi gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.heart, size: 96, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                'Wedding Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Persiapan & Keuangan dalam satu tempat',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}