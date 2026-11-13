import 'package:weddingmanagementf/core/database/database_helper.dart';
import 'package:weddingmanagementf/features/guests/data/guest_model.dart';

class GuestRepository {
  final DatabaseHelper _dbHelper;
  GuestRepository(this._dbHelper);

  /// Urut dari yang paling awal ditambah, supaya renumber otomatis stabil.
  Future<List<GuestModel>> listForProfile(int profileId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'guests',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'created_at ASC, id ASC',
    );
    return result.map(GuestModel.fromMap).toList();
  }

  Future<int> insert(GuestModel m) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final map = m.toMap()
      ..remove('created_at')
      ..remove('updated_at');
    return db.insert('guests', {
      ...map,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> update(GuestModel m) async {
    if (m.id == null) throw ArgumentError('id null');
    final db = await _dbHelper.database;
    final map = m.toMap()
      ..remove('created_at')
      ..remove('updated_at');
    map['updated_at'] = DateTime.now().toIso8601String();
    await db.update('guests', map, where: 'id = ?', whereArgs: [m.id]);
  }

  Future<void> updateInvited(int id, bool isInvited) async {
    final db = await _dbHelper.database;
    await db.update(
      'guests',
      {
        'is_invited': isInvited ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('guests', where: 'id = ?', whereArgs: [id]);
  }
}