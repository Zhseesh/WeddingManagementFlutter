import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final databaseProvider = FutureProvider((ref) async {
  final helper = ref.watch(databaseHelperProvider);
  return helper.database;
});