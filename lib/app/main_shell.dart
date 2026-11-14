import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/providers/navigation_providers.dart';
import 'package:weddingmanagementf/core/widgets/animated_bottom_nav.dart';
import 'package:weddingmanagementf/features/dashboard/presentation/dashboard_screen.dart';
import 'package:weddingmanagementf/features/finance/presentation/finance_screen.dart';
import 'package:weddingmanagementf/features/preparation/presentation/preparation_screen.dart';
import 'package:weddingmanagementf/features/profile/presentation/profile_screen.dart';
import 'package:weddingmanagementf/features/reports/presentation/reports_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    // FIX: baca initial tab dari provider. Kalau cold start dari notifikasi,
    // mainTabProvider sudah di-set ke 1 di SplashScreen sebelum MainShell
    // mount. Tanpa initialPage, PageController selalu mulai dari 0 dan
    // PageView tidak pernah animasi ke tab tujuan (karena listener fire
    // saat hasClients masih false).
    final initialTab = ref.read(mainTabProvider);
    _pageController = PageController(initialPage: initialTab);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainTabProvider, (previous, next) {
      if (_pageController.hasClients &&
          (_pageController.page?.round() ?? 0) != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });

    final currentTab = ref.watch(mainTabProvider);

    return PopScope(
      canPop: currentTab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentTab != 0) {
          ref.read(mainTabProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => ref.read(mainTabProvider.notifier).state = i,
          children: const [
            _KeepAlive(child: DashboardScreen()),
            _KeepAlive(child: PreparationScreen()),
            _KeepAlive(child: FinanceScreen()),
            _KeepAlive(child: ReportsScreen()),
            _KeepAlive(child: ProfileScreen()),
          ],
        ),
        bottomNavigationBar: AnimatedBottomNav(
          currentIndex: currentTab,
          onTap: (i) => ref.read(mainTabProvider.notifier).state = i,
        ),
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}