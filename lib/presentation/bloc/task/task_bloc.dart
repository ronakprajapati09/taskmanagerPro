import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/task_category.dart';
import '../../../domain/entities/task_filter.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/usecases/task_usecases.dart';

part 'task_event.dart';
part 'task_state.dart';

/// Duration of the undo window for swipe-to-delete.
const Duration kUndoWindow = Duration(seconds: 5);

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasks getTasks;
  final AddTask addTask;
  final UpdateTask updateTask;
  final DeleteTask deleteTask;
  final ReorderTasks reorderTasks;
  final ToggleTaskCompletion toggleTaskCompletion;
  final SettingsRepository settingsRepository;
  final NotificationService notificationService;

  /// Active commit timers keyed by task id so undo can cancel them.
  final Map<String, Timer> _deleteTimers = {};

  TaskBloc({
    required this.getTasks,
    required this.addTask,
    required this.updateTask,
    required this.deleteTask,
    required this.reorderTasks,
    required this.toggleTaskCompletion,
    required this.settingsRepository,
    required this.notificationService,
  }) : super(const TaskState()) {
    on<TasksLoaded>(_onLoaded);
    on<TaskAdded>(_onAdded);
    on<TaskUpdated>(_onUpdated);
    on<TaskCompletionToggled>(_onToggled);
    on<TaskSoftDeleted>(_onSoftDeleted);
    on<TaskDeleteUndone>(_onDeleteUndone);
    on<TaskDeleteCommitted>(_onDeleteCommitted);
    on<TasksReordered>(_onReordered);
    on<FilterCategoryChanged>(_onCategoryChanged);
    on<FilterStatusChanged>(_onStatusChanged);
    on<FilterDueDateChanged>(_onDueDateChanged);
    on<SearchQueryChanged>(_onSearchChanged);
    on<FiltersCleared>(_onFiltersCleared);
  }

  // ---------------------------------------------------------------------------
  // Filtering
  // ---------------------------------------------------------------------------

  List<Task> _applyFilter(List<Task> tasks, TaskFilter filter) {
    final query = filter.searchQuery.trim().toLowerCase();
    return tasks.where((task) {
      if (filter.category != null && task.category != filter.category) {
        return false;
      }
      switch (filter.status) {
        case StatusFilter.pending:
          if (task.isCompleted) return false;
          break;
        case StatusFilter.done:
          if (!task.isCompleted) return false;
          break;
        case StatusFilter.all:
          break;
      }
      switch (filter.dueDate) {
        case DueDateFilter.today:
          if (!AppDateUtils.isToday(task.dueDate)) return false;
          break;
        case DueDateFilter.upcoming:
          if (!AppDateUtils.isUpcoming(task.dueDate)) return false;
          break;
        case DueDateFilter.overdue:
          if (!AppDateUtils.isOverdue(task.dueDate)) return false;
          break;
        case DueDateFilter.any:
          break;
      }
      if (query.isNotEmpty) {
        final inTitle = task.title.toLowerCase().contains(query);
        final inDesc = task.description.toLowerCase().contains(query);
        if (!inTitle && !inDesc) return false;
      }
      return true;
    }).toList(growable: false);
  }

  TaskState _withFiltered(TaskState base,
      {List<Task>? allTasks, TaskFilter? filter}) {
    final tasks = allTasks ?? base.allTasks;
    final filter0 = filter ?? base.filter;
    return base.copyWith(
      allTasks: tasks,
      filter: filter0,
      filteredTasks: _applyFilter(tasks, filter0),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> _onLoaded(TasksLoaded event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: TaskStatus.loading));
    try {
      final savedFilter = await settingsRepository.getFilter();
      final tasks = await getTasks();
      emit(_withFiltered(
        state.copyWith(status: TaskStatus.success),
        allTasks: tasks,
        filter: savedFilter,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TaskStatus.failure,
        errorMessage: 'Failed to load tasks: $e',
      ));
    }
  }

  Future<void> _onAdded(TaskAdded event, Emitter<TaskState> emit) async {
    try {
      await addTask(event.task);
      await _scheduleReminderIfNeeded(event.task);
      final updated = [...state.allTasks, event.task]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      emit(_withFiltered(state, allTasks: updated));
    } catch (e) {
      emit(state.copyWith(
          status: TaskStatus.failure, errorMessage: 'Failed to add task: $e'));
    }
  }

  Future<void> _onUpdated(TaskUpdated event, Emitter<TaskState> emit) async {
    try {
      await updateTask(event.task);
      // Reschedule reminder to reflect any change.
      await notificationService.cancelReminder(event.task.id);
      if (!event.task.isCompleted) {
        await _scheduleReminderIfNeeded(event.task);
      }
      final updated = state.allTasks
          .map((t) => t.id == event.task.id ? event.task : t)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      emit(_withFiltered(state, allTasks: updated));
    } catch (e) {
      emit(state.copyWith(
          status: TaskStatus.failure,
          errorMessage: 'Failed to update task: $e'));
    }
  }

  Future<void> _onToggled(
      TaskCompletionToggled event, Emitter<TaskState> emit) async {
    try {
      final updated = await toggleTaskCompletion(event.task);
      // Completing a task cancels its reminder; un-completing reschedules it.
      if (updated.isCompleted) {
        await notificationService.cancelReminder(updated.id);
      } else {
        await _scheduleReminderIfNeeded(updated);
      }
      final list =
          state.allTasks.map((t) => t.id == updated.id ? updated : t).toList();
      emit(_withFiltered(state, allTasks: list));
    } catch (e) {
      emit(state.copyWith(
          status: TaskStatus.failure,
          errorMessage: 'Failed to toggle task: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Delete with undo
  // ---------------------------------------------------------------------------

  void _onSoftDeleted(TaskSoftDeleted event, Emitter<TaskState> emit) {
    final index = state.allTasks.indexWhere((t) => t.id == event.taskId);
    if (index == -1) return;
    final task = state.allTasks[index];

    final remaining = [...state.allTasks]..removeAt(index);
    final pending = Map<String, PendingDelete>.from(state.pendingDeletes)
      ..[event.taskId] = PendingDelete(task, index);

    // Authoritative commit timer. Undo cancels it before it fires.
    _deleteTimers[event.taskId]?.cancel();
    _deleteTimers[event.taskId] = Timer(kUndoWindow, () {
      add(TaskDeleteCommitted(event.taskId));
    });

    emit(_withFiltered(
      state.copyWith(
        pendingDeletes: pending,
        softDeleteNonce: state.softDeleteNonce + 1,
        softDeletedTask: task,
      ),
      allTasks: remaining,
    ));
  }

  void _onDeleteUndone(TaskDeleteUndone event, Emitter<TaskState> emit) {
    final pending = state.pendingDeletes[event.taskId];
    if (pending == null) return;

    _deleteTimers.remove(event.taskId)?.cancel();

    final restored = [...state.allTasks];
    final index = pending.originalIndex.clamp(0, restored.length);
    restored.insert(index, pending.task);

    final newPending = Map<String, PendingDelete>.from(state.pendingDeletes)
      ..remove(event.taskId);

    emit(_withFiltered(
      state.copyWith(pendingDeletes: newPending),
      allTasks: restored,
    ));
  }

  Future<void> _onDeleteCommitted(
      TaskDeleteCommitted event, Emitter<TaskState> emit) async {
    _deleteTimers.remove(event.taskId)?.cancel();
    final pending = state.pendingDeletes[event.taskId];
    if (pending == null) return;

    try {
      await deleteTask(event.taskId);
      await notificationService.cancelReminder(event.taskId);
      // Re-persist ordering so sortOrder stays contiguous after removal.
      await reorderTasks(state.allTasks);
    } catch (e) {
      emit(state.copyWith(
          status: TaskStatus.failure,
          errorMessage: 'Failed to delete task: $e'));
    }

    final newPending = Map<String, PendingDelete>.from(state.pendingDeletes)
      ..remove(event.taskId);
    emit(state.copyWith(pendingDeletes: newPending));
  }

  // ---------------------------------------------------------------------------
  // Reordering
  // ---------------------------------------------------------------------------

  Future<void> _onReordered(
      TasksReordered event, Emitter<TaskState> emit) async {
    // Reordering operates on the filtered (visible) list indices. Map them back
    // to the full list and persist the resulting order immediately.
    final visible = [...state.filteredTasks];
    if (event.oldIndex < 0 || event.oldIndex >= visible.length) return;

    var newIndex = event.newIndex;
    if (newIndex > event.oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, visible.length - 1);

    final moved = visible.removeAt(event.oldIndex);
    visible.insert(newIndex, moved);

    // Rebuild the complete ordered list: visible tasks take the new order,
    // any tasks hidden by filters keep their relative position appended.
    final visibleIds = visible.map((t) => t.id).toSet();
    final hidden =
        state.allTasks.where((t) => !visibleIds.contains(t.id)).toList();
    final merged = [...visible, ...hidden];

    // Assign fresh contiguous sortOrder values.
    final reSorted = <Task>[];
    for (var i = 0; i < merged.length; i++) {
      reSorted.add(merged[i].copyWith(sortOrder: i));
    }

    emit(_withFiltered(state, allTasks: reSorted));

    try {
      await reorderTasks(reSorted);
    } catch (e) {
      emit(state.copyWith(
          status: TaskStatus.failure,
          errorMessage: 'Failed to save new order: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Filters (persisted on every change)
  // ---------------------------------------------------------------------------

  Future<void> _persistAndEmitFilter(
      TaskFilter filter, Emitter<TaskState> emit) async {
    emit(_withFiltered(state, filter: filter));
    await settingsRepository.saveFilter(filter);
  }

  Future<void> _onCategoryChanged(
      FilterCategoryChanged event, Emitter<TaskState> emit) async {
    final f = event.category == null
        ? state.filter.copyWith(clearCategory: true)
        : state.filter.copyWith(category: event.category);
    await _persistAndEmitFilter(f, emit);
  }

  Future<void> _onStatusChanged(
      FilterStatusChanged event, Emitter<TaskState> emit) async {
    await _persistAndEmitFilter(
        state.filter.copyWith(status: event.status), emit);
  }

  Future<void> _onDueDateChanged(
      FilterDueDateChanged event, Emitter<TaskState> emit) async {
    await _persistAndEmitFilter(
        state.filter.copyWith(dueDate: event.dueDate), emit);
  }

  Future<void> _onSearchChanged(
      SearchQueryChanged event, Emitter<TaskState> emit) async {
    await _persistAndEmitFilter(
        state.filter.copyWith(searchQuery: event.query), emit);
  }

  Future<void> _onFiltersCleared(
      FiltersCleared event, Emitter<TaskState> emit) async {
    await _persistAndEmitFilter(TaskFilter.empty, emit);
  }

  // ---------------------------------------------------------------------------

  Future<void> _scheduleReminderIfNeeded(Task task) async {
    if (task.reminderTime != null && !task.isCompleted) {
      await notificationService.scheduleReminder(
        taskId: task.id,
        title: task.title,
        body: task.description.isEmpty ? 'Task reminder' : task.description,
        time: task.reminderTime!,
      );
    }
  }

  @override
  Future<void> close() {
    for (final timer in _deleteTimers.values) {
      timer.cancel();
    }
    _deleteTimers.clear();
    return super.close();
  }
}

