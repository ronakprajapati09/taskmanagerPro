import 'package:equatable/equatable.dart';

import 'task_category.dart';

/// Core domain entity. Pure Dart, no persistence/UI annotations.
class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Position used for drag-and-drop ordering. Lower comes first.
  final int sortOrder;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.category = TaskCategory.other,
    this.isCompleted = false,
    this.dueDate,
    this.reminderTime,
    required this.createdAt,
    required this.updatedAt,
    required this.sortOrder,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskCategory? category,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
    bool clearDueDate = false,
    bool clearReminder = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      reminderTime: clearReminder ? null : (reminderTime ?? this.reminderTime),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        isCompleted,
        dueDate,
        reminderTime,
        createdAt,
        updatedAt,
        sortOrder,
      ];
}

