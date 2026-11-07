import 'package:weddingmanagementf/core/database/database_helper.dart';
import 'package:weddingmanagementf/features/engagement/data/engagement_model.dart';

class EngagementRepository {
  final DatabaseHelper _dbHelper;
  EngagementRepository(this._dbHelper);

  Future<List<EngagementModel>> listForProfile(int profileId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'engagement_items',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'due_date ASC, id DESC',
    );
    return result.map(EngagementModel.fromMap).toList();
  }

  Future<int> insert(EngagementModel m) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final map = m.toMap()
      ..remove('created_at')
      ..remove('updated_at');
    return db.insert('engagement_items', {
      ...map,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> update(EngagementModel m) async {
    if (m.id == null) throw ArgumentError('id null');
    final db = await _dbHelper.database;
    final map = m.toMap()
      ..remove('created_at')
      ..remove('updated_at');
    map['updated_at'] = DateTime.now().toIso8601String();
    await db.update('engagement_items', map,
        where: 'id = ?', whereArgs: [m.id]);
  }

  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('engagement_items', where: 'id = ?', whereArgs: [id]);
  }
}