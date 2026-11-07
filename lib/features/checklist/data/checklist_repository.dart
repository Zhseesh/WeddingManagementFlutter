import 'package:weddingmanagementf/core/database/database_helper.dart';
import 'package:weddingmanagementf/features/checklist/data/checklist_model.dart';

class ChecklistRepository {
  final DatabaseHelper _dbHelper;
  ChecklistRepository(this._dbHelper);

  Future<List<ChecklistModel>> listForProfile(int profileId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'checklists',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'due_date ASC, id ASC',
    );
    return result.map(ChecklistModel.fromMap).toList();
  }

  Future<int> insert(ChecklistModel m) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final map = m.toMap()
      ..remove('created_at')
      ..remove('updated_at');
    return db.insert('checklists', {
      ...map,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> update(ChecklistModel m) async {
    if (m.id == null) throw ArgumentError('id null');
    final db = await _dbHelper.database;
    final map = m.toMap()
      ..remove('created_at')
      ..remove('updated_at');
    map['updated_at'] = DateTime.now().toIso8601String();
    await db.update('checklists', map, where: 'id = ?', whereArgs: [m.id]);
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _dbHelper.database;
    await db.update(
      'checklists',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('checklists', where: 'id = ?', whereArgs: [id]);
  }
}