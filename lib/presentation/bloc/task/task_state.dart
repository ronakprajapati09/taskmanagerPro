part of 'task_bloc.dart';

enum TaskStatus { initial, loading, success, failure }

/// Holds a soft-deleted task plus the index it occupied so undo can restore
/// it exactly where it was.
class PendingDelete extends Equatable {
  final Task task;
  final int originalIndex;
  const PendingDelete(this.task, this.originalIndex);

  @override
  List<Object?> get props => [task, originalIndex];
}

class TaskState extends Equatable {
  final TaskStatus status;

  /// All visible (non soft-deleted) tasks ordered by sortOrder.
  final List<Task> allTasks;

  /// Result of applying [filter] to [allTasks].
  final List<Task> filteredTasks;

  final TaskFilter filter;
  final String? errorMessage;

  /// Soft-deleted tasks awaiting commit, keyed by task id.
  final Map<String, PendingDelete> pendingDeletes;

  /// One-shot signal for the UI to show the undo snackbar.
  final int softDeleteNonce;
  final Task? softDeletedTask;

  const TaskState({
    this.status = TaskStatus.initial,
    this.allTasks = const [],
    this.filteredTasks = const [],
    this.filter = TaskFilter.empty,
    this.errorMessage,
    this.pendingDeletes = const {},
    this.softDeleteNonce = 0,
    this.softDeletedTask,
  });

  TaskState copyWith({
    TaskStatus? status,
    List<Task>? allTasks,
    List<Task>? filteredTasks,
    TaskFilter? filter,
    String? errorMessage,
    Map<String, PendingDelete>? pendingDeletes,
    int? softDeleteNonce,
    Task? softDeletedTask,
  }) {
    return TaskState(
      status: status ?? this.status,
      allTasks: allTasks ?? this.allTasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
      pendingDeletes: pendingDeletes ?? this.pendingDeletes,
      softDeleteNonce: softDeleteNonce ?? this.softDeleteNonce,
      softDeletedTask: softDeletedTask ?? this.softDeletedTask,
    );
  }

  // ---- Derived stats used by the home + stats screens ----

  int get totalCount => allTasks.length;
  int get completedCount => allTasks.where((t) => t.isCompleted).length;
  int get pendingCount => totalCount - completedCount;

  List<Task> get todayTasks => allTasks
      .where((t) => AppDateUtils.isToday(t.dueDate))
      .toList(growable: false);

  /// Tasks due from tomorrow onwards, sorted by due date ascending.
  List<Task> get upcomingTasks => allTasks
      .where((t) => !t.isCompleted && AppDateUtils.isUpcoming(t.dueDate))
      .toList(growable: false)
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

  /// Fraction (0..1) of *today's* tasks that are complete. 0 when none.
  double get todayProgress {
    final today = todayTasks;
    if (today.isEmpty) return 0;
    final done = today.where((t) => t.isCompleted).length;
    return done / today.length;
  }

  int get overdueCount =>
      allTasks.where((t) => !t.isCompleted && AppDateUtils.isOverdue(t.dueDate)).length;

  @override
  List<Object?> get props => [
        status,
        allTasks,
        filteredTasks,
        filter,
        errorMessage,
        pendingDeletes,
        softDeleteNonce,
      ];
}

