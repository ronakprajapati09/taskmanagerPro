import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema. A single shared instance is reused
/// for the whole app. All sqflite operations run off the UI isolate internally.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'task_manager_pro.db';
  static const _dbVersion = 1;

  static const tableTasks = 'tasks';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        dueDate INTEGER,
        reminderTime INTEGER,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        sortOrder INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_tasks_sortOrder ON $tableTasks (sortOrder)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future schema migrations are handled here keyed by version.
  }

  /// Closes the connection. Useful in tests.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

