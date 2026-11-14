import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:weddingmanagementf/app/main_shell.dart';
import 'package:weddingmanagementf/features/wedding_profile/data/wedding_profile_model.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/edit_profile_screen.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/onboarding_screen.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/setup_profile_screen.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/splash_screen.dart';
import 'package:weddingmanagementf/features/installments/presentation/installment_detail_screen.dart';
import 'package:weddingmanagementf/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:weddingmanagementf/features/vendors/presentation/vendor_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    GoRoute(path: '/setup-profile', builder: (c, s) => const SetupProfileScreen()),

    // Main shell — Beranda, Persiapan, Keuangan, Laporan, Profil
    GoRoute(path: '/app', builder: (c, s) => const MainShell()),

    // Nested pages (dipush di atas MainShell, bukan bagian dari tab)
    GoRoute(
      path: '/preparation/vendor/:id',
      builder: (c, s) {
        final id = int.tryParse(s.pathParameters['id'] ?? '');
        if (id == null) {
          return const Scaffold(body: Center(child: Text('Vendor tidak valid')));
        }
        return VendorDetailScreen(vendorId: id);
      },
    ),
    GoRoute(
      path: '/finance/transaction/:id',
      builder: (c, s) {
        final id = int.tryParse(s.pathParameters['id'] ?? '');
        if (id == null) {
          return const Scaffold(body: Center(child: Text('Transaksi tidak valid')));
        }
        return TransactionDetailScreen(transactionId: id);
      },
    ),
    GoRoute(
      path: '/finance/installment/:id',
      builder: (c, s) {
        final id = int.tryParse(s.pathParameters['id'] ?? '');
        if (id == null) {
          return const Scaffold(body: Center(child: Text('Cicilan tidak valid')));
        }
        return InstallmentDetailScreen(installmentId: id);
      },
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (c, s) {
        final p = s.extra as WeddingProfile?;
        if (p == null) {
          return const Scaffold(body: Center(child: Text('Profil tidak valid')));
        }
        return EditProfileScreen(profile: p);
      },
    ),
  ],
);