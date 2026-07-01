import 'package:sqflite/sqflite.dart';

import '../models/task_model.dart';
import 'database_helper.dart';

/// Low-level data source. The only place raw SQLite calls live.
abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getTasks();
  Future<void> insertTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<void> reorderTasks(List<TaskModel> orderedTasks);
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final DatabaseHelper dbHelper;

  TaskLocalDataSourceImpl(this.dbHelper);

  @override
  Future<List<TaskModel>> getTasks() async {
    final db = await dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableTasks,
      orderBy: 'sortOrder ASC',
    );
    return rows.map(TaskModel.fromMap).toList();
  }

  @override
  Future<void> insertTask(TaskModel task) async {
    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.tableTasks,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final db = await dbHelper.database;
    await db.update(
      DatabaseHelper.tableTasks,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      DatabaseHelper.tableTasks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> reorderTasks(List<TaskModel> orderedTasks) async {
    final db = await dbHelper.database;
    // Single transaction => atomic + off the UI isolate.
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var i = 0; i < orderedTasks.length; i++) {
        batch.update(
          DatabaseHelper.tableTasks,
          {'sortOrder': i},
          where: 'id = ?',
          whereArgs: [orderedTasks[i].id],
        );
      }
      await batch.commit(noResult: true);
    });
  }
}

