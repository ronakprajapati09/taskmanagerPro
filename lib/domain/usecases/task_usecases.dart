import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use cases encapsulate single business actions and keep the BLoC thin.
/// Each is a small callable class delegating to the repository interface.

class GetTasks {
  final TaskRepository repository;
  const GetTasks(this.repository);

  Future<List<Task>> call() => repository.getTasks();
}

class AddTask {
  final TaskRepository repository;
  const AddTask(this.repository);

  Future<Task> call(Task task) => repository.addTask(task);
}

class UpdateTask {
  final TaskRepository repository;
  const UpdateTask(this.repository);

  Future<void> call(Task task) => repository.updateTask(task);
}

class DeleteTask {
  final TaskRepository repository;
  const DeleteTask(this.repository);

  Future<void> call(String id) => repository.deleteTask(id);
}

class ReorderTasks {
  final TaskRepository repository;
  const ReorderTasks(this.repository);

  Future<void> call(List<Task> orderedTasks) =>
      repository.reorderTasks(orderedTasks);
}

class ToggleTaskCompletion {
  final TaskRepository repository;
  const ToggleTaskCompletion(this.repository);

  Future<Task> call(Task task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );
    await repository.updateTask(updated);
    return updated;
  }
}

