import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_schema.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseSchema.dbName);

    return openDatabase(
      path,
      version: DatabaseSchema.dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode=WAL');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final query in DatabaseSchema.createTableQueries) {
      batch.execute(query);
    }
    for (final query in DatabaseSchema.createIndexQueries) {
      batch.execute(query);
    }
    for (final query in DatabaseSchema.createViewQueries) {
      batch.execute(query);
    }
    for (final query in DatabaseSchema.createTriggerQueries) {
      batch.execute(query);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    assert(oldVersion < newVersion);
    assert(db.isOpen);

    // v1 → v2: tambah tabel `guests` untuk fitur Tamu Undangan.
    if (oldVersion < 2) {
      final batch = db.batch();
      batch.execute(DatabaseSchema.createGuestsTableQuery);
      batch.execute(DatabaseSchema.createGuestsIndexQuery);
      await batch.commit(noResult: true);
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}