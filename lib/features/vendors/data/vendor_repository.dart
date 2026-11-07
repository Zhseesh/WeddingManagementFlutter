import 'package:sqflite/sqflite.dart';
import 'package:weddingmanagementf/core/database/database_helper.dart';
import 'package:weddingmanagementf/features/vendors/data/vendor_model.dart';

class VendorRepository {
  final DatabaseHelper _dbHelper;
  VendorRepository(this._dbHelper);

  Future<List<VendorWithPayment>> listVendors(int profileId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT v.*,
             COALESCE(vps.total_paid, 0) AS total_paid,
             COALESCE(vps.remaining, v.agreed_price) AS remaining
      FROM vendors v
      LEFT JOIN v_vendor_payment_summary vps ON vps.vendor_id = v.id
      WHERE v.profile_id = ?
      ORDER BY v.created_at DESC
      ''',
      [profileId],
    );
    return result.map(VendorWithPayment.fromJoinRow).toList();
  }

  Future<VendorDetail?> getVendorDetail(int vendorId) async {
    final db = await _dbHelper.database;
    final vendorResult = await db.rawQuery(
      '''
      SELECT v.*,
             COALESCE(vps.total_paid, 0) AS total_paid,
             COALESCE(vps.remaining, v.agreed_price) AS remaining
      FROM vendors v
      LEFT JOIN v_vendor_payment_summary vps ON vps.vendor_id = v.id
      WHERE v.id = ?
      LIMIT 1
      ''',
      [vendorId],
    );
    if (vendorResult.isEmpty) return null;
    final summary = VendorWithPayment.fromJoinRow(vendorResult.first);

    final paymentsResult = await db.rawQuery(
      '''
      SELECT t.id AS tx_id, t.amount, t.transaction_date, t.payment_method,
             t.description, t.status
      FROM vendor_payments vp
      JOIN transactions t ON vp.transaction_id = t.id
      WHERE vp.vendor_id = ?
      ORDER BY t.transaction_date DESC, t.id DESC
      ''',
      [vendorId],
    );

    final payments = paymentsResult.map((row) {
      return PaymentRecord(
        transactionId: row['tx_id'] as int,
        amount: row['amount'] as int,
        date: DateTime.parse(row['transaction_date'] as String),
        method: row['payment_method'] as String?,
        description: row['description'] as String?,
        status: row['status'] as String,
      );
    }).toList();

    return VendorDetail(summary: summary, payments: payments);
  }

  Future<int> insertVendor(VendorModel v) async {
    final db = await _dbHelper.database;
    return db.insert('vendors', v.toMap());
  }

  Future<void> updateVendor(VendorModel v) async {
    if (v.id == null) throw ArgumentError('Vendor id null');
    final db = await _dbHelper.database;
    final map = v.toMap()
      ..remove('created_at')
      ..remove('updated_at');
    map['updated_at'] = DateTime.now().toIso8601String();
    await db.update(
      'vendors',
      map,
      where: 'id = ?',
      whereArgs: [v.id],
    );
  }

  /// Rekam pembayaran: transaksi (expense) + relasi vendor_payments
  /// dalam SATU database transaction (atomik).
  /// Auto-update status vendor bila perlu.
  Future<int> recordPayment({
    required VendorModel vendor,
    required int amount,
    required DateTime date,
    required String paymentMethod,
    String? description,
  }) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      final now = DateTime.now().toIso8601String();

      // 1. Insert transaksi (sumber nominal satu-satunya)
      final txId = await txn.insert('transactions', {
        'profile_id': vendor.profileId,
        'category_id': vendor.categoryId,
        'type': 'expense',
        'amount': amount,
        'transaction_date': date.toIso8601String().substring(0, 10),
        'source': 'Pembayaran ${vendor.name}',
        'payment_method': paymentMethod,
        'description': description,
        'status': 'posted',
        'created_at': now,
        'updated_at': now,
      });

      // 2. Insert relasi (tidak menyimpan nominal)
      await txn.insert('vendor_payments', {
        'vendor_id': vendor.id,
        'transaction_id': txId,
        'created_at': now,
      });

      // 3. Cek total pembayaran posted saat ini
      final currentResult = await txn.rawQuery(
        '''
        SELECT COALESCE(SUM(t.amount), 0) AS total
        FROM vendor_payments vp
        JOIN transactions t ON vp.transaction_id = t.id
        WHERE vp.vendor_id = ? AND t.status = 'posted'
        ''',
        [vendor.id],
      );
      final currentTotal = Sqflite.firstIntValue(currentResult) ?? 0;

      // 4. Auto-update status
      if (vendor.agreedPrice > 0 && currentTotal >= vendor.agreedPrice) {
        await txn.update(
          'vendors',
          {'status': 'paid', 'updated_at': now},
          where: "id = ? AND status != 'cancelled'",
          whereArgs: [vendor.id],
        );
      } else if (currentTotal > 0) {
        await txn.update(
          'vendors',
          {'status': 'dp_paid', 'updated_at': now},
          where:
              "id = ? AND status IN ('not_contacted', 'negotiating', 'booked')",
          whereArgs: [vendor.id],
        );
      }

      return txId;
    });
  }

  Future<void> voidPayment(int transactionId) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      {'status': 'void', 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }
}