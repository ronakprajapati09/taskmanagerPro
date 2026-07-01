import '../entities/task.dart';

/// Abstraction over task persistence. The domain layer depends only on this
/// interface; the concrete implementation lives in the data layer.
abstract class TaskRepository {
  /// Returns all tasks ordered by [Task.sortOrder] ascending.
  Future<List<Task>> getTasks();

  Future<Task> addTask(Task task);

  Future<void> updateTask(Task task);

  Future<void> deleteTask(String id);

  /// Persists the supplied ordering. The list is expected to already be in the
  /// desired visual order; implementations assign sortOrder by index.
  Future<void> reorderTasks(List<Task> orderedTasks);
}

