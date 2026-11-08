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
import 'package:weddingmanagementf/features/installments/presentation/installment_form_screen.dart';
import 'package:weddingmanagementf/features/installments/presentation/installment_payment_form_screen.dart';
import 'package:weddingmanagementf/features/reports/presentation/reports_screen.dart';
import 'package:weddingmanagementf/features/profile/presentation/profile_screen.dart';
import 'package:weddingmanagementf/features/transactions/presentation/transaction_form_screen.dart';
import 'package:weddingmanagementf/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:weddingmanagementf/features/vendors/data/vendor_model.dart';
import 'package:weddingmanagementf/features/vendors/presentation/vendor_list_screen.dart';
import 'package:weddingmanagementf/features/vendors/presentation/vendor_form_screen.dart';
import 'package:weddingmanagementf/features/vendors/presentation/vendor_detail_screen.dart';
import 'package:weddingmanagementf/features/checklist/data/checklist_model.dart';
import 'package:weddingmanagementf/features/checklist/presentation/checklist_list_screen.dart';
import 'package:weddingmanagementf/features/checklist/presentation/checklist_form_screen.dart';
import 'package:weddingmanagementf/features/engagement/data/engagement_model.dart';
import 'package:weddingmanagementf/features/engagement/presentation/engagement_list_screen.dart';
import 'package:weddingmanagementf/features/engagement/presentation/engagement_form_screen.dart';
import 'package:weddingmanagementf/features/dowry/data/dowry_model.dart';
import 'package:weddingmanagementf/features/dowry/presentation/dowry_list_screen.dart';
import 'package:weddingmanagementf/features/dowry/presentation/dowry_form_screen.dart';
import 'package:weddingmanagementf/features/reminders/data/reminder_model.dart';
import 'package:weddingmanagementf/features/reminders/presentation/reminder_list_screen.dart';
import 'package:weddingmanagementf/features/reminders/presentation/reminder_form_screen.dart';

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
              GoRoute(
                path: 'checklists',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) => const ChecklistListScreen(),
              ),
              GoRoute(
                path: 'checklist/new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) => const ChecklistFormScreen(),
              ),
              GoRoute(
                path: 'checklist/edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final initial = s.extra as ChecklistModel?;
                  return ChecklistFormScreen(initial: initial);
                },
              ),
              GoRoute(
                path: 'engagement',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) => const EngagementListScreen(),
              ),
              GoRoute(
                path: 'engagement/new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) => const EngagementFormScreen(),
              ),
              GoRoute(
                path: 'engagement/edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final initial = s.extra as EngagementModel?;
                  return EngagementFormScreen(initial: initial);
                },
              ),
              GoRoute(
                path: 'dowry',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) => const DowryListScreen(),
              ),
              GoRoute(
                path: 'dowry/new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) => const DowryFormScreen(),
              ),
              GoRoute(
                path: 'dowry/edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final initial = s.extra as DowryModel?;
                  return DowryFormScreen(initial: initial);
                },
              ),
              GoRoute(
                path: 'reminders',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) => const ReminderListScreen(),
              ),
              GoRoute(
                path: 'reminder/new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) => const ReminderFormScreen(),
              ),
              GoRoute(
                path: 'reminder/edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final initial = s.extra as ReminderModel?;
                  return ReminderFormScreen(initial: initial);
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
              GoRoute(
                path: 'installment/new',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) => const InstallmentFormScreen(),
              ),
              GoRoute(
                path: 'installment/:id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final id = int.tryParse(s.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const Scaffold(
                      body: Center(child: Text('Cicilan tidak valid')),
                    );
                  }
                  return InstallmentDetailScreen(installmentId: id);
                },
              ),
              GoRoute(
                path: 'installment/:id/pay/:scheduleId',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final iid = int.tryParse(s.pathParameters['id'] ?? '');
                  final sid =
                      int.tryParse(s.pathParameters['scheduleId'] ?? '');
                  if (iid == null || sid == null) {
                    return const Scaffold(
                      body: Center(child: Text('Data tidak valid')),
                    );
                  }
                  return InstallmentPaymentFormScreen(
                    installmentId: iid,
                    scheduleId: sid,
                  );
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
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (c, s) {
                  final profile = s.extra as WeddingProfile?;
                  if (profile == null) {
                    return const Scaffold(
                      body: Center(child: Text('Profil tidak valid')),
                    );
                  }
                  return EditProfileScreen(profile: profile);
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