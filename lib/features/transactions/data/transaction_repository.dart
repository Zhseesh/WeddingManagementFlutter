import 'package:weddingmanagementf/core/database/database_helper.dart';
import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper;
  TransactionRepository(this._dbHelper);

  Future<List<TransactionModel>> listForProfile(
    int profileId, {
    String? type,
    String? status,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>['profile_id = ?'];
    final args = <Object>[profileId];
    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status);
    }
    final result = await db.query(
      'transactions',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'transaction_date DESC, id DESC',
    );
    return result.map(TransactionModel.fromMap).toList();
  }

  Future<TransactionModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return TransactionModel.fromMap(result.first);
  }

  Future<int> insert(TransactionModel tx) async {
    final db = await _dbHelper.database;
    return db.insert('transactions', tx.toMap());
  }

  Future<void> voidTransaction(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      {
        'status': 'void',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}