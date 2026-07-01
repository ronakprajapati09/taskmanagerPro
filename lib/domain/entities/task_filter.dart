import 'package:equatable/equatable.dart';

import 'task_category.dart';

/// Completion status filter.
enum StatusFilter {
  all,
  pending,
  done;

  String get storageKey => name;

  String get label {
    switch (this) {
      case StatusFilter.all:
        return 'All';
      case StatusFilter.pending:
        return 'Pending';
      case StatusFilter.done:
        return 'Done';
    }
  }

  static StatusFilter fromStorage(String? value) {
    return StatusFilter.values.firstWhere(
      (s) => s.storageKey == value,
      orElse: () => StatusFilter.all,
    );
  }
}

/// Due-date range filter.
enum DueDateFilter {
  any,
  today,
  upcoming,
  overdue;

  String get storageKey => name;

  String get label {
    switch (this) {
      case DueDateFilter.any:
        return 'Any date';
      case DueDateFilter.today:
        return 'Today';
      case DueDateFilter.upcoming:
        return 'Upcoming';
      case DueDateFilter.overdue:
        return 'Overdue';
    }
  }

  static DueDateFilter fromStorage(String? value) {
    return DueDateFilter.values.firstWhere(
      (d) => d.storageKey == value,
      orElse: () => DueDateFilter.any,
    );
  }
}

/// Immutable description of the currently applied filters.
/// Persisted between sessions through the settings repository.
class TaskFilter extends Equatable {
  final TaskCategory? category; // null == all categories
  final StatusFilter status;
  final DueDateFilter dueDate;
  final String searchQuery;

  const TaskFilter({
    this.category,
    this.status = StatusFilter.all,
    this.dueDate = DueDateFilter.any,
    this.searchQuery = '',
  });

  static const TaskFilter empty = TaskFilter();

  bool get isActive =>
      category != null ||
      status != StatusFilter.all ||
      dueDate != DueDateFilter.any ||
      searchQuery.trim().isNotEmpty;

  TaskFilter copyWith({
    TaskCategory? category,
    StatusFilter? status,
    DueDateFilter? dueDate,
    String? searchQuery,
    bool clearCategory = false,
  }) {
    return TaskFilter(
      category: clearCategory ? null : (category ?? this.category),
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [category, status, dueDate, searchQuery];
}

