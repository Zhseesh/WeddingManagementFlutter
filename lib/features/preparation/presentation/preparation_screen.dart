import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/app/theme/app_theme.dart';
import 'package:weddingmanagementf/features/checklist/presentation/checklist_form_sheet.dart';
import 'package:weddingmanagementf/features/dowry/presentation/dowry_form_sheet.dart';
import 'package:weddingmanagementf/features/engagement/presentation/engagement_form_sheet.dart';
import 'package:weddingmanagementf/features/preparation/presentation/tabs/checklist_tab.dart';
import 'package:weddingmanagementf/features/preparation/presentation/tabs/dowry_tab.dart';
import 'package:weddingmanagementf/features/preparation/presentation/tabs/engagement_tab.dart';
import 'package:weddingmanagementf/features/preparation/presentation/tabs/reminder_tab.dart';
import 'package:weddingmanagementf/features/preparation/presentation/tabs/vendor_tab.dart';
import 'package:weddingmanagementf/features/reminders/presentation/reminder_form_sheet.dart';
import 'package:weddingmanagementf/features/vendors/presentation/vendor_form_sheet.dart';

class PreparationScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const PreparationScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends ConsumerState<PreparationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
    _tab.addListener(() => setState(() {}));
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
    }
  }

  static const _fabLabels = ['Vendor', 'Checklist', 'Lamaran', 'Seserahan', 'Pengingat'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Persiapan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text('Vendor, kebutuhan, dan pengingat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.muted)),
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
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Vendor'),
            Tab(text: 'Checklist'),
            Tab(text: 'Lamaran'),
            Tab(text: 'Seserahan'),
            Tab(text: 'Pengingat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          VendorTab(),
          ChecklistTab(),
          EngagementTab(),
          DowryTab(),
          ReminderTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAdd,
        icon: const Icon(Icons.add),
        label: Text(_fabLabels[_tab.index]),
      ),
    );
  }
}