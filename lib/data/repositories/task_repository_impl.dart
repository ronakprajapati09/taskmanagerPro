import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl(this.localDataSource);

  @override
  Future<List<Task>> getTasks() async {
    final models = await localDataSource.getTasks();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Task> addTask(Task task) async {
    await localDataSource.insertTask(TaskModel.fromEntity(task));
    return task;
  }

  @override
  Future<void> updateTask(Task task) async {
    await localDataSource.updateTask(TaskModel.fromEntity(task));
  }

  @override
  Future<void> deleteTask(String id) async {
    await localDataSource.deleteTask(id);
  }

  @override
  Future<void> reorderTasks(List<Task> orderedTasks) async {
    final models = orderedTasks.map(TaskModel.fromEntity).toList();
    await localDataSource.reorderTasks(models);
  }
}

