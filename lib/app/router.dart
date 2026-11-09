import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:weddingmanagementf/features/wedding_profile/data/wedding_profile_model.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/edit_profile_screen.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/onboarding_screen.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/setup_profile_screen.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/splash_screen.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/dashboard_screen.dart';
import 'package:weddingmanagementf/features/preparation/presentation/preparation_screen.dart';
import 'package:weddingmanagementf/features/finance/presentation/finance_screen.dart';
import 'package:weddingmanagementf/features/installments/presentation/installment_detail_screen.dart';
import 'package:weddingmanagementf/features/reports/presentation/reports_screen.dart';
import 'package:weddingmanagementf/features/profile/presentation/profile_screen.dart';
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
    StatefulShellRoute.indexedStack(
      builder: (c, s, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/preparation',
            builder: (c, s) {
              final tabParam = s.uri.queryParameters['tab'];
              final initialIndex = int.tryParse(tabParam ?? '0') ?? 0;
              return PreparationScreen(
                key: ValueKey('prep-$initialIndex'),
                initialTabIndex: initialIndex,
              );
            },
            routes: [
              GoRoute(
                path: 'vendor/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final id = int.tryParse(s.pathParameters['id'] ?? '');
                  if (id == null) return const Scaffold(body: Center(child: Text('Vendor tidak valid')));
                  return VendorDetailScreen(vendorId: id);
                },
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/finance',
            builder: (c, s) => const FinanceScreen(),
            routes: [
              GoRoute(
                path: 'transaction/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final id = int.tryParse(s.pathParameters['id'] ?? '');
                  if (id == null) return const Scaffold(body: Center(child: Text('Transaksi tidak valid')));
                  return TransactionDetailScreen(transactionId: id);
                },
              ),
              GoRoute(
                path: 'installment/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final id = int.tryParse(s.pathParameters['id'] ?? '');
                  if (id == null) return const Scaffold(body: Center(child: Text('Cicilan tidak valid')));
                  return InstallmentDetailScreen(installmentId: id);
                },
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/reports', builder: (c, s) => const ReportsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (c, s) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final p = s.extra as WeddingProfile?;
                  if (p == null) return const Scaffold(body: Center(child: Text('Profil tidak valid')));
                  return EditProfileScreen(profile: p);
                },
              ),
            ],
          ),
        ]),
      ],
    ),
  ],
);

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Persiapan'),
          NavigationDestination(icon: Icon(Icons.wallet_outlined), selectedIcon: Icon(Icons.wallet), label: 'Keuangan'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Laporan'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}