import 'package:weddingmanagementf/core/database/database_helper.dart';
import 'package:weddingmanagementf/features/budget/data/budget_model.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper;
  BudgetRepository(this._dbHelper);

  Future<BudgetModel?> getActiveBudget(int profileId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'budgets',
      where: 'profile_id = ? AND is_active = 1',
      whereArgs: [profileId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return BudgetModel.fromMap(result.first);
  }

  Future<BudgetSummary?> getSummary(int profileId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'v_budget_summary',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    final row = result.first;
    return BudgetSummary(
      totalBudget: (row['total_amount'] as int?) ?? 0,
      totalExpense: (row['total_expense'] as int?) ?? 0,
      remaining: (row['remaining_budget'] as int?) ?? 0,
    );
  }

  Future<void> updateTotalAmount(int budgetId, int newTotal) async {
    final db = await _dbHelper.database;
    await db.update(
      'budgets',
      {
        'total_amount': newTotal,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [budgetId],
    );
  }

  Future<List<BudgetCategoryModel>> listCategories(int budgetId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'budget_categories',
      where: 'budget_id = ?',
      whereArgs: [budgetId],
      orderBy: 'sort_order ASC, id ASC',
    );
    return result.map(BudgetCategoryModel.fromMap).toList();
  }

  Future<List<CategorySpending>> getCategorySpending(
    int profileId,
    int budgetId,
  ) async {
    final db = await _dbHelper.database;
    final cats = await listCategories(budgetId);
    final spendResult = await db.rawQuery(
      '''
      SELECT category_id, SUM(amount) AS total
      FROM transactions
      WHERE profile_id = ? AND type = 'expense' AND status = 'posted'
        AND category_id IS NOT NULL
      GROUP BY category_id
      ''',
      [profileId],
    );
    final spendMap = <int, int>{};
    for (final row in spendResult) {
      final cid = row['category_id'] as int?;
      final total = row['total'] as int?;
      if (cid != null && total != null) spendMap[cid] = total;
    }
    return cats
        .map((c) => CategorySpending(
              category: c,
              spent: c.id != null ? (spendMap[c.id!] ?? 0) : 0,
            ))
        .toList();
  }

  Future<int> createCategory({
    required int budgetId,
    required String name,
    required int allocatedAmount,
    int sortOrder = 0,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return db.insert('budget_categories', {
      'budget_id': budgetId,
      'name': name,
      'allocated_amount': allocatedAmount,
      'sort_order': sortOrder,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updateCategoryAllocation(int categoryId, int newAmount) async {
    final db = await _dbHelper.database;
    await db.update(
      'budget_categories',
      {
        'allocated_amount': newAmount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }
}