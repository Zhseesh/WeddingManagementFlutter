import 'package:weddingmanagementf/core/database/database_helper.dart';
import 'package:weddingmanagementf/core/services/notification_service.dart';
import 'package:weddingmanagementf/features/reminders/data/reminder_model.dart';

class ReminderRepository {
  final DatabaseHelper _dbHelper;
  final NotificationService _notif;

  ReminderRepository(this._dbHelper) : _notif = NotificationService.instance;

  Future<List<ReminderModel>> listForProfile(int profileId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'reminders',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'reminder_date ASC',
    );
    return result.map(ReminderModel.fromMap).toList();
  }

  Future<int> insert(ReminderModel m) async {
    final db = await _dbHelper.database;
    final id = await db.insert('reminders', m.toMap());
    if (m.isEnabled && !m.isCompleted) {
      await _notif.schedule(
        id: id,
        title: m.title,
        body: m.description ?? 'Pengingat pernikahan',
        when: m.reminderDate,
        payload: NotificationService.reminderPayload,
      );
    }
    return id;
  }

  Future<void> update(ReminderModel m) async {
    if (m.id == null) throw ArgumentError('id null');
    final db = await _dbHelper.database;
    await db.update(
      'reminders',
      m.toMap(),
      where: 'id = ?',
      whereArgs: [m.id],
    );

    await _notif.cancel(m.id!);
    if (m.isEnabled && !m.isCompleted) {
      await _notif.schedule(
        id: m.id!,
        title: m.title,
        body: m.description ?? 'Pengingat pernikahan',
        when: m.reminderDate,
        payload: NotificationService.reminderPayload,
      );
    }
  }

  Future<void> toggleEnabled(ReminderModel m) async {
    await update(m.copyWith(isEnabled: !m.isEnabled));
  }

  Future<void> toggleCompleted(ReminderModel m) async {
    await update(m.copyWith(isCompleted: !m.isCompleted));
  }

  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
    await _notif.cancel(id);
  }
}