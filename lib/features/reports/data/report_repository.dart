import 'package:weddingmanagementf/core/database/database_helper.dart';
import 'package:weddingmanagementf/features/reports/data/report_models.dart';
import 'package:weddingmanagementf/features/transactions/data/transaction_model.dart';

class ReportRepository {
  final DatabaseHelper _dbHelper;
  ReportRepository(this._dbHelper);

  Future<ReportData> getReport(int profileId, ReportFilter filter) async {
    final db = await _dbHelper.database;
    final start = filter.period.startIso;
    final end = filter.period.endIso;

    // --- 1. Income & Expense totals ---
    final typeClause =
        filter.type != null ? "AND type = '${filter.type}'" : '';
    final catClause = filter.categoryId != null
        ? "AND category_id = ${filter.categoryId}"
        : '';
    final totalsResult = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expense
      FROM transactions
      WHERE profile_id = ? AND status = 'posted'
        AND transaction_date >= ? AND transaction_date <= ?
        $typeClause $catClause
      ''',
      [profileId, start, end],
    );
    final totalIncome =
        (totalsResult.first['income'] as int?) ?? 0;
    final totalExpense =
        (totalsResult.first['expense'] as int?) ?? 0;

    // --- 2. Budget (all-time aktif) ---
    final budgetResult = await db.query(
      'budgets',
      columns: ['total_amount'],
      where: 'profile_id = ? AND is_active = 1',
      whereArgs: [profileId],
      limit: 1,
    );
    final totalBudget = budgetResult.isEmpty
        ? 0
        : (budgetResult.first['total_amount'] as int?) ?? 0;

    // --- 3. Per-category breakdown (filtered by period) ---
    final catsResult = await db.rawQuery(
      '''
      SELECT bc.id AS cat_id, bc.name,
             COALESCE(SUM(t.amount), 0) AS total,
             COUNT(t.id) AS cnt
      FROM budget_categories bc
      LEFT JOIN transactions t ON t.category_id = bc.id
        AND t.status = 'posted' AND t.type = 'expense'
        AND t.transaction_date >= ? AND t.transaction_date <= ?
      WHERE bc.budget_id = (
        SELECT id FROM budgets WHERE profile_id = ? AND is_active = 1 LIMIT 1
      )
      GROUP BY bc.id
      ORDER BY total DESC, bc.name ASC
      ''',
      [start, end, profileId],
    );
    final categories = catsResult
        .where((r) => (r['total'] as int?) != null || true)
        .map((r) => CategoryBreakdown(
              categoryId: r['cat_id'] as int?,
              name: r['name'] as String,
              total: (r['total'] as int?) ?? 0,
              transactionCount: (r['cnt'] as int?) ?? 0,
            ))
        .where((c) => c.total > 0 || c.transactionCount > 0)
        .toList();

    // --- 4. Vendor summary (all-time snapshot) ---
    final vendorsResult = await db.rawQuery(
      '''
      SELECT v.id, v.name, v.agreed_price,
             COALESCE(vps.total_paid, 0) AS paid,
             COALESCE(vps.remaining, v.agreed_price) AS remaining
      FROM vendors v
      LEFT JOIN v_vendor_payment_summary vps ON vps.vendor_id = v.id
      WHERE v.profile_id = ?
      ORDER BY v.agreed_price DESC
      ''',
      [profileId],
    );
    final vendors = vendorsResult
        .map((r) => VendorBreakdown(
              vendorId: r['id'] as int,
              name: r['name'] as String,
              agreedPrice: r['agreed_price'] as int,
              paid: (r['paid'] as int?) ?? 0,
              remaining: (r['remaining'] as int?) ?? 0,
            ))
        .toList();

    // --- 5. Installment summary (all-time snapshot) ---
    final instResult = await db.rawQuery(
      '''
      SELECT i.id, i.name, i.total_amount,
             COALESCE(vis.total_paid, 0) AS paid,
             COALESCE(vis.remaining, i.total_amount) AS remaining
      FROM installments i
      LEFT JOIN v_installment_summary vis ON vis.installment_id = i.id
      WHERE i.profile_id = ? AND i.status != 'cancelled'
      ORDER BY i.created_at DESC
      ''',
      [profileId],
    );
    final installments = instResult
        .map((r) => InstallmentBreakdown(
              id: r['id'] as int,
              name: r['name'] as String,
              totalAmount: r['total_amount'] as int,
              paid: (r['paid'] as int?) ?? 0,
              remaining: (r['remaining'] as int?) ?? 0,
            ))
        .toList();

    // --- 6. Transaction list (filtered) ---
    final txResult = await db.rawQuery(
      '''
      SELECT * FROM transactions
      WHERE profile_id = ? AND status IN ('posted', 'void')
        AND transaction_date >= ? AND transaction_date <= ?
        $typeClause $catClause
      ORDER BY transaction_date DESC, id DESC
      ''',
      [profileId, start, end],
    );
    final transactions = txResult.map(TransactionModel.fromMap).toList();

    return ReportData(
      filter: filter,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalBudget: totalBudget,
      categories: categories,
      vendors: vendors,
      installments: installments,
      transactions: transactions,
    );
  }
}