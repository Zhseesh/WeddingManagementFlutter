class DatabaseSchema {
  static const String dbName = 'wedding_planner.db';
  static const int dbVersion = 1;

  static const String tableWeddingProfiles = 'wedding_profiles';
  static const String tableBudgets = 'budgets';
  static const String tableBudgetCategories = 'budget_categories';
  static const String tableVendors = 'vendors';
  static const String tableTransactions = 'transactions';
  static const String tableVendorPayments = 'vendor_payments';
  static const String tableInstallments = 'installments';
  static const String tableInstallmentSchedules = 'installment_schedules';
  static const String tableInstallmentPayments = 'installment_payments';
  static const String tableEngagementItems = 'engagement_items';
  static const String tableDowryItems = 'dowry_items';
  static const String tableChecklists = 'checklists';
  static const String tableReminders = 'reminders';
  static const String tableAttachments = 'attachments';
  static const String tableSettings = 'settings';

  static const List<String> createTableQueries = [
    // 1. Wedding Profiles
    '''
    CREATE TABLE $tableWeddingProfiles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      partner_one TEXT NOT NULL,
      partner_two TEXT NOT NULL,
      wedding_date TEXT,
      engagement_date TEXT,
      wedding_location TEXT,
      notes TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    ''',
    // 2. Budgets
    '''
    CREATE TABLE $tableBudgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      total_amount INTEGER NOT NULL CHECK(total_amount >= 0),
      is_active INTEGER NOT NULL DEFAULT 1,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES $tableWeddingProfiles(id) ON DELETE CASCADE
    )
    ''',
    // 3. Budget Categories
    '''
    CREATE TABLE $tableBudgetCategories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      budget_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      allocated_amount INTEGER NOT NULL CHECK(allocated_amount >= 0),
      icon TEXT,
      color TEXT,
      sort_order INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (budget_id) REFERENCES $tableBudgets(id) ON DELETE CASCADE,
      UNIQUE(budget_id, name)
    )
    ''',
    // 4. Vendors
    '''
    CREATE TABLE $tableVendors (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      category_id INTEGER,
      name TEXT NOT NULL,
      contact_name TEXT,
      phone TEXT,
      address TEXT,
      agreed_price INTEGER NOT NULL DEFAULT 0 CHECK(agreed_price >= 0),
      booking_date TEXT,
      event_date TEXT,
      status TEXT NOT NULL DEFAULT 'not_contacted' CHECK(status IN ('not_contacted', 'negotiating', 'booked', 'dp_paid', 'paid', 'cancelled')),
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES $tableWeddingProfiles(id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES $tableBudgetCategories(id) ON DELETE SET NULL
    )
    ''',
    // 5. Transactions
    '''
    CREATE TABLE $tableTransactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      category_id INTEGER,
      type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
      amount INTEGER NOT NULL CHECK(amount > 0),
      transaction_date TEXT NOT NULL,
      source TEXT,
      payment_method TEXT,
      description TEXT,
      status TEXT NOT NULL DEFAULT 'posted' CHECK(status IN ('posted', 'void')),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES $tableWeddingProfiles(id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES $tableBudgetCategories(id) ON DELETE SET NULL
    )
    ''',
    // 6. Vendor Payments
    '''
    CREATE TABLE $tableVendorPayments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      vendor_id INTEGER NOT NULL,
      transaction_id INTEGER NOT NULL UNIQUE,
      created_at TEXT NOT NULL,
      FOREIGN KEY (vendor_id) REFERENCES $tableVendors(id) ON DELETE CASCADE,
      FOREIGN KEY (transaction_id) REFERENCES $tableTransactions(id) ON DELETE CASCADE
    )
    ''',
    // 7. Installments
    '''
    CREATE TABLE $tableInstallments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      vendor_id INTEGER,
      name TEXT NOT NULL,
      total_amount INTEGER NOT NULL CHECK(total_amount > 0),
      start_date TEXT,
      notes TEXT,
      status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'completed', 'cancelled')),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES $tableWeddingProfiles(id) ON DELETE CASCADE,
      FOREIGN KEY (vendor_id) REFERENCES $tableVendors(id) ON DELETE SET NULL
    )
    ''',
    // 8. Installment Schedules
    '''
    CREATE TABLE $tableInstallmentSchedules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      installment_id INTEGER NOT NULL,
      sequence_number INTEGER NOT NULL,
      due_date TEXT NOT NULL,
      amount INTEGER NOT NULL CHECK(amount > 0),
      status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'partial', 'paid', 'overdue')),
      FOREIGN KEY (installment_id) REFERENCES $tableInstallments(id) ON DELETE CASCADE,
      UNIQUE(installment_id, sequence_number)
    )
    ''',
    // 9. Installment Payments
    '''
    CREATE TABLE $tableInstallmentPayments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      schedule_id INTEGER NOT NULL,
      transaction_id INTEGER NOT NULL UNIQUE,
      created_at TEXT NOT NULL,
      FOREIGN KEY (schedule_id) REFERENCES $tableInstallmentSchedules(id) ON DELETE CASCADE,
      FOREIGN KEY (transaction_id) REFERENCES $tableTransactions(id) ON DELETE CASCADE
    )
    ''',
    // 10. Engagement Items
    '''
    CREATE TABLE $tableEngagementItems (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      category TEXT,
      quantity INTEGER NOT NULL DEFAULT 1 CHECK(quantity > 0),
      estimated_price INTEGER DEFAULT 0 CHECK(estimated_price >= 0),
      actual_price INTEGER DEFAULT 0 CHECK(actual_price >= 0),
      status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'in_progress', 'completed', 'cancelled')),
      due_date TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES $tableWeddingProfiles(id) ON DELETE CASCADE
    )
    ''',
    // 11. Dowry Items
    '''
    CREATE TABLE $tableDowryItems (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      category TEXT,
      quantity INTEGER NOT NULL DEFAULT 1 CHECK(quantity > 0),
      estimated_price INTEGER DEFAULT 0 CHECK(estimated_price >= 0),
      actual_price INTEGER DEFAULT 0 CHECK(actual_price >= 0),
      status TEXT NOT NULL DEFAULT 'not_purchased' CHECK(status IN ('not_purchased', 'in_progress', 'purchased', 'cancelled')),
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES $tableWeddingProfiles(id) ON DELETE CASCADE
    )
    ''',
    // 12. Checklists
    '''
    CREATE TABLE $tableChecklists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      category TEXT,
      description TEXT,
      priority TEXT NOT NULL DEFAULT 'medium' CHECK(priority IN ('low', 'medium', 'high')),
      due_date TEXT,
      status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'in_progress', 'completed')),
      is_default INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES $tableWeddingProfiles(id) ON DELETE CASCADE
    )
    ''',
    // 13. Reminders
    '''
    CREATE TABLE $tableReminders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      reminder_date TEXT NOT NULL,
      reference_type TEXT,
      reference_id INTEGER,
      is_enabled INTEGER NOT NULL DEFAULT 1,
      is_completed INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES $tableWeddingProfiles(id) ON DELETE CASCADE
    )
    ''',
    // 14. Attachments
    '''
    CREATE TABLE $tableAttachments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL,
      reference_type TEXT NOT NULL,
      reference_id INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      file_path TEXT NOT NULL,
      mime_type TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (profile_id) REFERENCES $tableWeddingProfiles(id) ON DELETE CASCADE
    )
    ''',
    // 15. Settings
    '''
    CREATE TABLE $tableSettings (
      key TEXT PRIMARY KEY,
      value TEXT,
      updated_at TEXT NOT NULL
    )
    '''
  ];

  static const List<String> createIndexQueries = [
    'CREATE INDEX idx_transactions_profile ON $tableTransactions(profile_id);',
    'CREATE INDEX idx_transactions_date ON $tableTransactions(transaction_date);',
    'CREATE INDEX idx_transactions_category ON $tableTransactions(category_id);',
    'CREATE INDEX idx_transactions_type_status ON $tableTransactions(type, status);',
    'CREATE INDEX idx_vendors_profile ON $tableVendors(profile_id);',
    'CREATE INDEX idx_vendor_payments_vendor ON $tableVendorPayments(vendor_id);',
    'CREATE INDEX idx_installments_profile ON $tableInstallments(profile_id);',
    'CREATE INDEX idx_installment_schedules_due ON $tableInstallmentSchedules(due_date, status);',
    'CREATE INDEX idx_checklists_profile ON $tableChecklists(profile_id);',
    'CREATE INDEX idx_reminders_date ON $tableReminders(reminder_date, is_enabled);',
    'CREATE INDEX idx_attachments_ref ON $tableAttachments(reference_type, reference_id);',
    'CREATE UNIQUE INDEX idx_budget_active_profile ON $tableBudgets(profile_id) WHERE is_active = 1;'
  ];

  static const List<String> createViewQueries = [
    // v_financial_summary
    '''
    CREATE VIEW v_financial_summary AS
    SELECT 
      profile_id,
      COALESCE(SUM(CASE WHEN type = 'income' AND status = 'posted' THEN amount ELSE 0 END), 0) AS total_income,
      COALESCE(SUM(CASE WHEN type = 'expense' AND status = 'posted' THEN amount ELSE 0 END), 0) AS total_expense
    FROM $tableTransactions
    GROUP BY profile_id;
    ''',
    // v_budget_summary
    '''
    CREATE VIEW v_budget_summary AS
    SELECT 
      b.profile_id,
      b.id AS budget_id,
      b.total_amount,
      COALESCE((SELECT SUM(t.amount) FROM $tableTransactions t WHERE t.profile_id = b.profile_id AND t.type = 'expense' AND t.status = 'posted'), 0) AS total_expense,
      b.total_amount - COALESCE((SELECT SUM(t.amount) FROM $tableTransactions t WHERE t.profile_id = b.profile_id AND t.type = 'expense' AND t.status = 'posted'), 0) AS remaining_budget
    FROM $tableBudgets b
    WHERE b.is_active = 1;
    ''',
    // v_vendor_payment_summary
    '''
    CREATE VIEW v_vendor_payment_summary AS
    SELECT 
      v.id AS vendor_id,
      v.profile_id,
      v.name,
      v.agreed_price,
      COALESCE((SELECT SUM(t.amount) FROM $tableVendorPayments vp JOIN $tableTransactions t ON vp.transaction_id = t.id WHERE vp.vendor_id = v.id AND t.status = 'posted'), 0) AS total_paid,
      v.agreed_price - COALESCE((SELECT SUM(t.amount) FROM $tableVendorPayments vp JOIN $tableTransactions t ON vp.transaction_id = t.id WHERE vp.vendor_id = v.id AND t.status = 'posted'), 0) AS remaining
    FROM $tableVendors v;
    ''',
    // v_installment_summary
    '''
    CREATE VIEW v_installment_summary AS
    SELECT 
      i.id AS installment_id,
      i.profile_id,
      i.name,
      i.total_amount,
      COALESCE((SELECT SUM(t.amount) FROM $tableInstallmentPayments ip JOIN $tableTransactions t ON ip.transaction_id = t.id JOIN $tableInstallmentSchedules s ON ip.schedule_id = s.id WHERE s.installment_id = i.id AND t.status = 'posted'), 0) AS total_paid,
      i.total_amount - COALESCE((SELECT SUM(t.amount) FROM $tableInstallmentPayments ip JOIN $tableTransactions t ON ip.transaction_id = t.id JOIN $tableInstallmentSchedules s ON ip.schedule_id = s.id WHERE s.installment_id = i.id AND t.status = 'posted'), 0) AS remaining
    FROM $tableInstallments i;
    '''
  ];

  static const List<String> createTriggerQueries = [
    // Trigger validasi Vendor Payments harus expense dan profil sama
    '''
    CREATE TRIGGER trg_vendor_payment_validate
    BEFORE INSERT ON $tableVendorPayments
    FOR EACH ROW
    BEGIN
      SELECT CASE
        WHEN (SELECT type FROM $tableTransactions WHERE id = NEW.transaction_id) != 'expense' THEN
          RAISE(ABORT, 'Vendor payment transaction must be an expense')
        WHEN (SELECT profile_id FROM $tableTransactions WHERE id = NEW.transaction_id) != 
             (SELECT profile_id FROM $tableVendors WHERE id = NEW.vendor_id) THEN
          RAISE(ABORT, 'Transaction profile does not match vendor profile')
      END;
    END;
    ''',
    // Trigger validasi Installment Payments harus expense dan profil sama
    '''
    CREATE TRIGGER trg_installment_payment_validate
    BEFORE INSERT ON $tableInstallmentPayments
    FOR EACH ROW
    BEGIN
      SELECT CASE
        WHEN (SELECT type FROM $tableTransactions WHERE id = NEW.transaction_id) != 'expense' THEN
          RAISE(ABORT, 'Installment payment transaction must be an expense')
        WHEN (SELECT profile_id FROM $tableTransactions WHERE id = NEW.transaction_id) != 
             (SELECT i.profile_id FROM $tableInstallmentSchedules s JOIN $tableInstallments i ON s.installment_id = i.id WHERE s.id = NEW.schedule_id) THEN
          RAISE(ABORT, 'Transaction profile does not match installment profile')
      END;
    END;
    '''
  ];
}