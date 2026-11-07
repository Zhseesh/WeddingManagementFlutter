import 'package:weddingmanagementf/core/database/database_helper.dart';
import 'package:weddingmanagementf/features/dowry/data/dowry_model.dart';

class DowryRepository {
  final DatabaseHelper _dbHelper;
  DowryRepository(this._dbHelper);

  Future<List<DowryModel>> listForProfile(int profileId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'dowry_items',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'id DESC',
    );
    return result.map(DowryModel.fromMap).toList();
  }

  Future<int> insert(DowryModel m) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final map = m.toMap()
      ..remove('created_at')
      ..remove('updated_at');
    return db.insert('dowry_items', {
      ...map,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> update(DowryModel m) async {
    if (m.id == null) throw ArgumentError('id null');
    final db = await _dbHelper.database;
    final map = m.toMap()
      ..remove('created_at')
      ..remove('updated_at');
    map['updated_at'] = DateTime.now().toIso8601String();
    await db.update('dowry_items', map, where: 'id = ?', whereArgs: [m.id]);
  }

  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('dowry_items', where: 'id = ?', whereArgs: [id]);
  }
}