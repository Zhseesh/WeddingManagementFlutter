import '../../../../core/database/database_helper.dart';
import 'wedding_profile_model.dart';

class WeddingProfileRepository {
  final DatabaseHelper _dbHelper;

  WeddingProfileRepository(this._dbHelper);

  Future<WeddingProfile?> getActiveProfile() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'wedding_profiles',
      where: 'is_active = 1',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return WeddingProfile.fromMap(result.first);
  }

  Future<int> createProfileWithDefaults({
    required WeddingProfile profile,
    required int initialBudget,
  }) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();

      // 1. Insert profile
      final profileMap = profile.toMap();
      final profileId = await txn.insert('wedding_profiles', {
        ...profileMap,
        'created_at': now,
        'updated_at': now,
      });

      // 2. Insert budget aktif
      final budgetId = await txn.insert('budgets', {
        'profile_id': profileId,
        'name': 'Anggaran Utama',
        'total_amount': initialBudget,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });

      // 3. Seed kategori default
      final categories = <Map<String, dynamic>>[
        {'name': 'Catering', 'sort_order': 1},
        {'name': 'Dekorasi', 'sort_order': 2},
        {'name': 'Dokumentasi', 'sort_order': 3},
        {'name': 'Gedung', 'sort_order': 4},
        {'name': 'Busana & Rias', 'sort_order': 5},
        {'name': 'Undangan', 'sort_order': 6},
        {'name': 'Lainnya', 'sort_order': 7},
      ];
      for (final cat in categories) {
        await txn.insert('budget_categories', {
          'budget_id': budgetId,
          'name': cat['name'],
          'allocated_amount': 0,
          'sort_order': cat['sort_order'],
          'created_at': now,
          'updated_at': now,
        });
      }

      // 4. Seed checklist default
      final checklists = <String>[
        'Persiapan dokumen KUA',
        'Cek kesehatan pra-nikah',
        'Booking venue',
        'Pilih katering',
        'Pilih fotografer & videografer',
        'Beli cincin pernikahan',
        'Persiapkan seserahan',
      ];
      for (var i = 0; i < checklists.length; i++) {
        await txn.insert('checklists', {
          'profile_id': profileId,
          'title': checklists[i],
          'category': 'Umum',
          'priority': 'medium',
          'status': 'pending',
          'is_default': 1,
          'created_at': now,
          'updated_at': now,
        });
      }

      return profileId;
    });
  }
}