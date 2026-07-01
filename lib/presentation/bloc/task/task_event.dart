part of 'task_bloc.dart';

sealed class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class TasksLoaded extends TaskEvent {
  const TasksLoaded();
}

class TaskAdded extends TaskEvent {
  final Task task;
  const TaskAdded(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskUpdated extends TaskEvent {
  final Task task;
  const TaskUpdated(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskCompletionToggled extends TaskEvent {
  final Task task;
  const TaskCompletionToggled(this.task);

  @override
  List<Object?> get props => [task];
}

/// Optimistically hides the task and starts the undo window.
class TaskSoftDeleted extends TaskEvent {
  final String taskId;
  const TaskSoftDeleted(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// Restores a soft-deleted task at its original position.
class TaskDeleteUndone extends TaskEvent {
  final String taskId;
  const TaskDeleteUndone(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// Commits the deletion to the database after the undo window expires.
class TaskDeleteCommitted extends TaskEvent {
  final String taskId;
  const TaskDeleteCommitted(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class TasksReordered extends TaskEvent {
  final int oldIndex;
  final int newIndex;
  const TasksReordered(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class FilterCategoryChanged extends TaskEvent {
  final TaskCategory? category;
  const FilterCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class FilterStatusChanged extends TaskEvent {
  final StatusFilter status;
  const FilterStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class FilterDueDateChanged extends TaskEvent {
  final DueDateFilter dueDate;
  const FilterDueDateChanged(this.dueDate);

  @override
  List<Object?> get props => [dueDate];
}

class SearchQueryChanged extends TaskEvent {
  final String query;
  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class FiltersCleared extends TaskEvent {
  const FiltersCleared();
}

