import 'dart:convert';

import 'package:weddingmanagementf/core/database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper;
  BackupService(this._dbHelper);

  static const int schemaVersion = 1;
  static const String appId = 'weddingmanagementf';

  static const List<String> tables = [
    'settings',
    'wedding_profiles',
    'guests', // BARU — child dari wedding_profiles
    'budgets',
    'budget_categories',
    'vendors',
    'transactions',
    'vendor_payments',
    'installments',
    'installment_schedules',
    'installment_payments',
    'engagement_items',
    'dowry_items',
    'checklists',
    'reminders',
    'attachments',
  ];

  static const List<String> _deleteOrder = [
    'installment_payments',
    'vendor_payments',
    'installment_schedules',
    'installments',
    'vendors',
    'transactions',
    'budget_categories',
    'budgets',
    'checklists',
    'engagement_items',
    'dowry_items',
    'reminders',
    'attachments',
    'guests', // BARU — harus dihapus sebelum wedding_profiles
    'wedding_profiles',
    'settings',
  ];

  Future<String> exportToJson() async {
    final db = await _dbHelper.database;
    final data = <String, dynamic>{};
    for (final t in tables) {
      data[t] = await db.query(t);
    }
    final out = {
      'schema_version': schemaVersion,
      'app': appId,
      'exported_at': DateTime.now().toIso8601String(),
      'data': data,
    };
    return const JsonEncoder.withIndent('  ').convert(out);
  }

  String? validateJson(String raw) {
    late final dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      return 'File bukan JSON yang valid.';
    }
    if (parsed is! Map<String, dynamic>) {
      return 'Format file tidak dikenali.';
    }
    if (parsed['app'] != appId) {
      return 'File bukan backup dari aplikasi ini.';
    }
    final v = parsed['schema_version'];
    if (v is! int) {
      return 'Versi skema tidak ada di file backup.';
    }
    if (v != schemaVersion) {
      return 'Versi skema tidak didukung (file: $v, aplikasi: $schemaVersion).';
    }
    final data = parsed['data'];
    if (data is! Map<String, dynamic>) {
      return 'File backup tidak memiliki bagian "data".';
    }
    for (final t in tables) {
      if (!data.containsKey(t)) {
        return 'File backup kehilangan tabel "$t".';
      }
    }
    return null;
  }

  Future<void> importFromJson(String raw) async {
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    final data = (parsed['data'] as Map).cast<String, dynamic>();

    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      for (final t in _deleteOrder) {
        await txn.delete(t);
      }
      for (final t in tables) {
        final rows = data[t];
        if (rows is! List) continue;
        for (final row in rows) {
          final map = (row as Map).cast<String, dynamic>();
          await txn.insert(t, map);
        }
      }
    });
  }
}