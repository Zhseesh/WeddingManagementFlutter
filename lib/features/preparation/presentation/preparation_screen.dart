import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/core/providers/navigation_providers.dart';
import 'package:weddingmanagementf/features/checklist/presentation/checklist_form_sheet.dart';
import 'package:weddingmanagementf/features/dowry/presentation/dowry_form_sheet.dart';
import 'package:weddingmanagementf/features/engagement/presentation/engagement_form_sheet.dart';
import 'package:weddingmanagementf/features/guests/presentation/guest_form_sheet.dart';
import 'package:weddingmanagementf/features/preparation/presentation/tabs/checklist_tab.dart';
import 'package:weddingmanagementf/features/preparation/presentation/tabs/dowry_tab.dart';
import 'package:weddingmanagementf/features/preparation/presentation/tabs/engagement_tab.dart';
import 'package:weddingmanagementf/features/preparation/presentation/tabs/guest_tab.dart';
import 'package:weddingmanagementf/features/preparation/presentation/tabs/reminder_tab.dart';
import 'package:weddingmanagementf/features/preparation/presentation/tabs/vendor_tab.dart';
import 'package:weddingmanagementf/features/reminders/presentation/reminder_form_sheet.dart';
import 'package:weddingmanagementf/features/vendors/presentation/vendor_form_sheet.dart';

class PreparationScreen extends ConsumerStatefulWidget {
  const PreparationScreen({super.key});

  @override
  ConsumerState<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends ConsumerState<PreparationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(prepTabProvider).clamp(0, 5);
    _tab = TabController(length: 6, vsync: this, initialIndex: initialIndex);

    _tab.addListener(() {
      if (mounted) {
        setState(() {});
        if (ref.read(prepTabProvider) != _tab.index) {
          ref.read(prepTabProvider.notifier).state = _tab.index;
        }
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _onAdd() {
    switch (_tab.index) {
      case 0:
        showVendorFormSheet(context);
      case 1:
        showChecklistFormSheet(context);
      case 2:
        showEngagementFormSheet(context);
      case 3:
        showDowryFormSheet(context);
      case 4:
        showReminderFormSheet(context);
      case 5:
        showGuestAddDialog(context, ref);
    }
  }

  static const _fabLabels = [
    'Vendor',
    'Checklist',
    'Lamaran',
    'Seserahan',
    'Pengingat',
    'Tamu',
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(prepTabProvider, (previous, next) {
      if (mounted && _tab.index != next) {
        _tab.animateTo(next);
      }
    });

    final targetIndex = ref.watch(prepTabProvider).clamp(0, 5);
    if (_tab.index != targetIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tab.index != targetIndex) {
          _tab.animateTo(targetIndex);
        }
      });
    }

    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Persiapan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text('Vendor, kebutuhan, dan pengingat',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.muted)),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.muted,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Vendor'),
            Tab(text: 'Checklist'),
            Tab(text: 'Lamaran'),
            Tab(text: 'Seserahan'),
            Tab(text: 'Pengingat'),
            Tab(text: 'Tamu'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tab,
            children: const [
              VendorTab(),
              ChecklistTab(),
              EngagementTab(),
              DowryTab(),
              ReminderTab(),
              GuestTab(),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: IgnorePointer(
              ignoring: isKeyboardOpen || _tab.indexIsChanging,
              child: AnimatedSlide(
                offset: isKeyboardOpen ? const Offset(0, 0.5) : Offset.zero,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: isKeyboardOpen ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: FloatingActionButton.extended(
                    onPressed: _onAdd,
                    icon: const Icon(Icons.add),
                    label: Text(_fabLabels[_tab.index]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}