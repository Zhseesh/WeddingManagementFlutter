import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weddingmanagementf/core/providers/app_providers.dart';
import 'package:weddingmanagementf/features/backup/data/backup_service.dart';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseHelperProvider)),
);