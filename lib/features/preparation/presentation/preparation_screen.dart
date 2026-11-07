import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PreparationScreen extends StatelessWidget {
  const PreparationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const items = <_PrepItem>[
      _PrepItem(
        title: 'Vendor',
        description: 'Kelola vendor, pembayaran, dan DP',
        icon: Icons.store,
        route: '/preparation/vendors',
      ),
      _PrepItem(
        title: 'Lamaran',
        description: 'Kebutuhan lamaran',
        icon: Icons.favorite_border,
        route: '/preparation/engagement',
      ),
      _PrepItem(
        title: 'Seserahan',
        description: 'Daftar seserahan',
        icon: Icons.card_giftcard,
        route: '/preparation/dowry',
      ),
      _PrepItem(
        title: 'Checklist',
        description: 'Tugas persiapan',
        icon: Icons.checklist,
        route: '/preparation/checklists',
      ),
      _PrepItem(
        title: 'Pengingat',
        description: 'Notifikasi & jadwal',
        icon: Icons.alarm,
        route: null,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Persiapan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Modul Persiapan',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PrepCard(item: item),
              )),
          const SizedBox(height: 16),
          Text(
            'Modul Pengingat akan segera tersedia.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _PrepItem {
  final String title;
  final String description;
  final IconData icon;
  final String? route;
  const _PrepItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });
}

class _PrepCard extends StatelessWidget {
  final _PrepItem item;
  const _PrepCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = item.route != null;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? () => context.push(item.route!) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: enabled
                      ? Color.lerp(scheme.surface, scheme.primary, 0.12)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color: enabled ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: enabled
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!enabled)
                Chip(
                  label: const Text('Segera'),
                  visualDensity: VisualDensity.compact,
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                )
              else
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}