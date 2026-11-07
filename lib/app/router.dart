import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/onboarding_screen.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/setup_profile_screen.dart';
import 'package:weddingmanagementf/features/wedding_profile/presentation/splash_screen.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/dashboard_screen.dart';
import 'package:weddingmanagementf/features/preparation/presentation/preparation_screen.dart';
import 'package:weddingmanagementf/features/finance/presentation/finance_screen.dart';
import 'package:weddingmanagementf/features/reports/presentation/reports_screen.dart';
import 'package:weddingmanagementf/features/profile/presentation/profile_screen.dart';
import 'package:weddingmanagementf/features/transactions/presentation/transaction_form_screen.dart';
import 'package:weddingmanagementf/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:weddingmanagementf/features/vendors/data/vendor_model.dart';
import 'package:weddingmanagementf/features/vendors/presentation/vendor_list_screen.dart';
import 'package:weddingmanagementf/features/vendors/presentation/vendor_form_screen.dart';
import 'package:weddingmanagementf/features/vendors/presentation/vendor_detail_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    GoRoute(
      path: '/setup-profile',
      builder: (c, s) => const SetupProfileScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (c, s, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/dashboard',
            builder: (c, s) => const DashboardScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/preparation',
            builder: (c, s) => const PreparationScreen(),
            routes: [
              GoRoute(
                path: 'vendors',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) => const VendorListScreen(),
              ),
              GoRoute(
                path: 'vendor/new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) => const VendorFormScreen(),
              ),
              GoRoute(
                path: 'vendor/edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final initial = s.extra as VendorModel?;
                  return VendorFormScreen(initial: initial);
                },
              ),
              GoRoute(
                path: 'vendor/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final id = int.tryParse(s.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const Scaffold(
                      body: Center(child: Text('Vendor tidak valid')),
                    );
                  }
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
                path: 'transaction/new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) => const TransactionFormScreen(),
              ),
              GoRoute(
                path: 'transaction/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final id = int.tryParse(s.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const Scaffold(
                      body: Center(child: Text('Transaksi tidak valid')),
                    );
                  }
                  return TransactionDetailScreen(transactionId: id);
                },
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/reports',
            builder: (c, s) => const ReportsScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (c, s) => const ProfileScreen(),
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
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Persiapan',
          ),
          NavigationDestination(
            icon: Icon(Icons.wallet_outlined),
            selectedIcon: Icon(Icons.wallet),
            label: 'Keuangan',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}