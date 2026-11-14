import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final container = ProviderContainer();
  NotificationService.instance.attachContainer(container);

  await NotificationService.instance.init();
  unawaited(NotificationService.instance.rescheduleAllPending());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const WeddingApp(),
    ),
  );
}