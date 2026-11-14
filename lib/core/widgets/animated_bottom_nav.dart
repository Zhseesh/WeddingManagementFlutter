import 'package:material_ui/material_ui.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';

class AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Beranda'),
    (icon: Icons.checklist_outlined, activeIcon: Icons.checklist, label: 'Persiapan'),
    (icon: Icons.wallet_outlined, activeIcon: Icons.wallet, label: 'Keuangan'),
    (icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Laporan'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: palette.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / 5;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    left: currentIndex * itemWidth + 4,
                    top: 4,
                    width: itemWidth - 8,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.softPrimary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      final isActive = i == currentIndex;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.elasticOut,
                                  scale: isActive ? 1.15 : 1.0,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      isActive ? _items[i].activeIcon : _items[i].icon,
                                      key: ValueKey('${i}_$isActive'),
                                      color: isActive ? scheme.primary : palette.muted,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isActive ? scheme.primary : palette.muted,
                                  ),
                                  child: Text(_items[i].label),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}