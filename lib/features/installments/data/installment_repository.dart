import 'package:sqflite/sqflite.dart';
import 'package:weddingmanagementf/core/database/database_helper.dart';
import 'package:weddingmanagementf/features/installments/data/installment_model.dart';

class InstallmentRepository {
  final DatabaseHelper _dbHelper;
  InstallmentRepository(this._dbHelper);

  Future<List<InstallmentWithSummary>> listInstallments(int profileId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT i.*,
             COALESCE(vis.total_paid, 0) AS total_paid,
             COALESCE(vis.remaining, i.total_amount) AS remaining,
             (SELECT MIN(s.due_date) FROM installment_schedules s
              WHERE s.installment_id = i.id AND s.status != 'paid') AS next_due_date
      FROM installments i
      LEFT JOIN v_installment_summary vis ON vis.installment_id = i.id
      WHERE i.profile_id = ?
      ORDER BY i.created_at DESC
      ''',
      [profileId],
    );
    return result.map(InstallmentWithSummary.fromJoinRow).toList();
  }

  Future<InstallmentDetail?> getDetail(int installmentId) async {
    final db = await _dbHelper.database;
    final instResult = await db.rawQuery(
      '''
      SELECT i.*,
             COALESCE(vis.total_paid, 0) AS total_paid,
             COALESCE(vis.remaining, i.total_amount) AS remaining,
             (SELECT MIN(s.due_date) FROM installment_schedules s
              WHERE s.installment_id = i.id AND s.status != 'paid') AS next_due_date
      FROM installments i
      LEFT JOIN v_installment_summary vis ON vis.installment_id = i.id
      WHERE i.id = ?
      LIMIT 1
      ''',
      [installmentId],
    );
    if (instResult.isEmpty) return null;
    final summary = InstallmentWithSummary.fromJoinRow(instResult.first);

    final schedResult = await db.rawQuery(
      '''
      SELECT s.*,
             COALESCE((SELECT SUM(t.amount) FROM installment_payments ip
                       JOIN transactions t ON ip.transaction_id = t.id
                       WHERE ip.schedule_id = s.id AND t.status = 'posted'), 0) AS total_paid
      FROM installment_schedules s
      WHERE s.installment_id = ?
      ORDER BY s.sequence_number ASC
      ''',
      [installmentId],
    );

    final payResult = await db.rawQuery(
      '''
      SELECT ip.schedule_id, t.id AS tx_id, t.amount, t.transaction_date,
             t.payment_method, t.description, t.status
      FROM installment_payments ip
      JOIN transactions t ON ip.transaction_id = t.id
      JOIN installment_schedules s ON ip.schedule_id = s.id
      WHERE s.installment_id = ?
      ORDER BY t.transaction_date DESC, t.id DESC
      ''',
      [installmentId],
    );

    final paymentsBySchedule = <int, List<InstallmentPaymentRecord>>{};
    for (final row in payResult) {
      final sid = row['schedule_id'] as int;
      paymentsBySchedule.putIfAbsent(sid, () => []).add(
            InstallmentPaymentRecord(
              transactionId: row['tx_id'] as int,
              amount: row['amount'] as int,
              date: DateTime.parse(row['transaction_date'] as String),
              method: row['payment_method'] as String?,
              description: row['description'] as String?,
              status: row['status'] as String,
            ),
          );
    }

    final schedules = schedResult.map((row) {
      final schedule = ScheduleModel.fromMap(row);
      return ScheduleWithPayments(
        schedule: schedule,
        totalPaid: (row['total_paid'] as int?) ?? 0,
        payments: paymentsBySchedule[schedule.id] ?? const [],
      );
    }).toList();

    return InstallmentDetail(summary: summary, schedules: schedules);
  }

  Future<ScheduleModel?> getScheduleById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'installment_schedules',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ScheduleModel.fromMap(result.first);
  }

  Future<int> getSchedulePaidAmount(int scheduleId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(t.amount), 0) AS total
      FROM installment_payments ip
      JOIN transactions t ON ip.transaction_id = t.id
      WHERE ip.schedule_id = ? AND t.status = 'posted'
      ''',
      [scheduleId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Insert installment + schedules sekaligus (atomik).
  Future<int> createInstallment({
    required InstallmentModel installment,
    required List<ScheduleModel> schedules,
  }) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();
      final map = installment.toMap()
        ..remove('created_at')
        ..remove('updated_at');
      final id = await txn.insert('installments', {
        ...map,
        'created_at': now,
        'updated_at': now,
      });
      for (var i = 0; i < schedules.length; i++) {
        final s = schedules[i];
        await txn.insert('installment_schedules', {
          'installment_id': id,
          'sequence_number': i + 1,
          'due_date': s.dueDate.toIso8601String().substring(0, 10),
          'amount': s.amount,
          'status': s.status,
        });
      }
      return id;
    });
  }

  Future<void> addSchedule({
    required int installmentId,
    required DateTime dueDate,
    required int amount,
  }) async {
    final db = await _dbHelper.database;
    final seqResult = await db.rawQuery(
      'SELECT COALESCE(MAX(sequence_number), 0) AS m FROM installment_schedules WHERE installment_id = ?',
      [installmentId],
    );
    final maxSeq = Sqflite.firstIntValue(seqResult) ?? 0;
    await db.insert('installment_schedules', {
      'installment_id': installmentId,
      'sequence_number': maxSeq + 1,
      'due_date': dueDate.toIso8601String().substring(0, 10),
      'amount': amount,
      'status': 'pending',
    });
  }

  /// Catat pembayaran untuk termin tertentu.
  Future<int> recordSchedulePayment({
    required ScheduleModel schedule,
    required int profileId,
    int? categoryId,
    required int amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();

      // 1. Insert transaksi
      final txId = await txn.insert('transactions', {
        'profile_id': profileId,
        'category_id': categoryId,
        'type': 'expense',
        'amount': amount,
        'transaction_date': date.toIso8601String().substring(0, 10),
        'source': 'Pembayaran cicilan',
        'payment_method': paymentMethod,
        'description': description,
        'status': 'posted',
        'created_at': now,
        'updated_at': now,
      });

      // 2. Insert relasi
      await txn.insert('installment_payments', {
        'schedule_id': schedule.id,
        'transaction_id': txId,
        'created_at': now,
      });

      // 3. Update status schedule
      final paidResult = await txn.rawQuery(
        '''
        SELECT COALESCE(SUM(t.amount), 0) AS total
        FROM installment_payments ip
        JOIN transactions t ON ip.transaction_id = t.id
        WHERE ip.schedule_id = ? AND t.status = 'posted'
        ''',
        [schedule.id],
      );
      final paid = Sqflite.firstIntValue(paidResult) ?? 0;
      final newStatus =
          paid >= schedule.amount ? 'paid' : (paid > 0 ? 'partial' : 'pending');
      await txn.update(
        'installment_schedules',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [schedule.id],
      );

      // 4. Update status installment kalau semua termin lunas
      await _recalcInstallmentStatus(txn, schedule.installmentId, now);

      return txId;
    });
  }

  Future<void> voidSchedulePayment({
    required int transactionId,
    required int scheduleId,
    required int installmentId,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      await txn.update(
        'transactions',
        {'status': 'void', 'updated_at': now},
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      final schedResult = await txn.query(
        'installment_schedules',
        where: 'id = ?',
        whereArgs: [scheduleId],
        limit: 1,
      );
      if (schedResult.isEmpty) return;
      final schedAmount = schedResult.first['amount'] as int;

      final paidResult = await txn.rawQuery(
        '''
        SELECT COALESCE(SUM(t.amount), 0) AS total
        FROM installment_payments ip
        JOIN transactions t ON ip.transaction_id = t.id
        WHERE ip.schedule_id = ? AND t.status = 'posted'
        ''',
        [scheduleId],
      );
      final paid = Sqflite.firstIntValue(paidResult) ?? 0;
      final newStatus = paid >= schedAmount
          ? 'paid'
          : (paid > 0 ? 'partial' : 'pending');
      await txn.update(
        'installment_schedules',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [scheduleId],
      );

      await _recalcInstallmentStatus(txn, installmentId, now);
    });
  }

  Future<void> cancelInstallment(int installmentId) async {
    final db = await _dbHelper.database;
    await db.update(
      'installments',
      {
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [installmentId],
    );
  }

  Future<void> _recalcInstallmentStatus(
    Transaction txn,
    int installmentId,
    String now,
  ) async {
    final rows = await txn.query(
      'installment_schedules',
      columns: ['status'],
      where: 'installment_id = ?',
      whereArgs: [installmentId],
    );
    if (rows.isEmpty) return;
    final allPaid = rows.every((r) => r['status'] == 'paid');
    final newStatus = allPaid ? 'completed' : 'active';
    await txn.update(
      'installments',
      {'status': newStatus, 'updated_at': now},
      where: "id = ? AND status != 'cancelled'",
      whereArgs: [installmentId],
    );
  }
}