import '../../domain/entities/task.dart';
import '../../domain/entities/task_category.dart';

/// Data-layer representation responsible for DB row <-> entity mapping.
/// Domain entities stay free of any persistence concerns.
class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int isCompleted;
  final int? dueDate;
  final int? reminderTime;
  final int createdAt;
  final int updatedAt;
  final int sortOrder;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isCompleted,
    this.dueDate,
    this.reminderTime,
    required this.createdAt,
    required this.updatedAt,
    required this.sortOrder,
  });

  factory TaskModel.fromMap(Map<String, Object?> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      category: map['category'] as String,
      isCompleted: (map['isCompleted'] as int?) ?? 0,
      dueDate: map['dueDate'] as int?,
      reminderTime: map['reminderTime'] as int?,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
      sortOrder: (map['sortOrder'] as int?) ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'isCompleted': isCompleted,
      'dueDate': dueDate,
      'reminderTime': reminderTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'sortOrder': sortOrder,
    };
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.category.storageKey,
      isCompleted: task.isCompleted ? 1 : 0,
      dueDate: task.dueDate?.millisecondsSinceEpoch,
      reminderTime: task.reminderTime?.millisecondsSinceEpoch,
      createdAt: task.createdAt.millisecondsSinceEpoch,
      updatedAt: task.updatedAt.millisecondsSinceEpoch,
      sortOrder: task.sortOrder,
    );
  }

  Task toEntity() {
    return Task(
      id: id,
      title: title,
      description: description,
      category: TaskCategory.fromStorage(category),
      isCompleted: isCompleted == 1,
      dueDate: dueDate == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dueDate!),
      reminderTime: reminderTime == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(reminderTime!),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      sortOrder: sortOrder,
    );
  }
}

