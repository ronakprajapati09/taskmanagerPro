import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todolisttask/data/datasources/task_local_datasource.dart';
import 'package:todolisttask/data/models/task_model.dart';
import 'package:todolisttask/data/repositories/task_repository_impl.dart';
import 'package:todolisttask/domain/entities/task.dart';
import 'package:todolisttask/domain/entities/task_category.dart';

class _MockLocalDataSource extends Mock implements TaskLocalDataSource {}

class _FakeTaskModel extends Fake implements TaskModel {}

Task _task({
  required String id,
  int sortOrder = 0,
  bool completed = false,
  TaskCategory category = TaskCategory.work,
}) {
  final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  return Task(
    id: id,
    title: 'Task $id',
    description: 'desc $id',
    category: category,
    isCompleted: completed,
    createdAt: now,
    updatedAt: now,
    sortOrder: sortOrder,
  );
}

void main() {
  late _MockLocalDataSource dataSource;
  late TaskRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_FakeTaskModel());
  });

  setUp(() {
    dataSource = _MockLocalDataSource();
    repository = TaskRepositoryImpl(dataSource);
  });

  group('TaskRepositoryImpl', () {
    test('getTasks maps models to entities in order', () async {
      when(() => dataSource.getTasks()).thenAnswer((_) async => [
            TaskModel.fromEntity(_task(id: 'a', sortOrder: 0)),
            TaskModel.fromEntity(_task(id: 'b', sortOrder: 1)),
          ]);

      final result = await repository.getTasks();

      expect(result, hasLength(2));
      expect(result.first, isA<Task>());
      expect(result.first.id, 'a');
      expect(result.last.id, 'b');
      verify(() => dataSource.getTasks()).called(1);
    });

    test('addTask inserts the mapped model and returns the task', () async {
      when(() => dataSource.insertTask(any())).thenAnswer((_) async {});
      final task = _task(id: 'x');

      final returned = await repository.addTask(task);

      expect(returned, task);
      verify(() => dataSource.insertTask(any())).called(1);
    });

    test('updateTask delegates to the data source', () async {
      when(() => dataSource.updateTask(any())).thenAnswer((_) async {});

      await repository.updateTask(_task(id: 'x', completed: true));

      verify(() => dataSource.updateTask(any())).called(1);
    });

    test('deleteTask delegates with the correct id', () async {
      when(() => dataSource.deleteTask(any())).thenAnswer((_) async {});

      await repository.deleteTask('x');

      verify(() => dataSource.deleteTask('x')).called(1);
    });

    test('reorderTasks persists the full ordered list', () async {
      when(() => dataSource.reorderTasks(any())).thenAnswer((_) async {});
      final ordered = [
        _task(id: 'a', sortOrder: 1),
        _task(id: 'b', sortOrder: 0),
      ];

      await repository.reorderTasks(ordered);

      final captured = verify(() => dataSource.reorderTasks(captureAny()))
          .captured
          .single as List<TaskModel>;
      expect(captured.map((m) => m.id).toList(), ['a', 'b']);
    });

    test('propagates errors from the data source', () async {
      when(() => dataSource.getTasks()).thenThrow(Exception('db error'));

      expect(repository.getTasks(), throwsException);
    });
  });

  group('TaskModel mapping', () {
    test('round-trips an entity through map without data loss', () {
      final original = _task(
        id: 'roundtrip',
        completed: true,
        category: TaskCategory.urgent,
        sortOrder: 5,
      ).copyWith(
        dueDate: DateTime.fromMillisecondsSinceEpoch(1700001111000),
        reminderTime: DateTime.fromMillisecondsSinceEpoch(1700002222000),
      );

      final restored =
          TaskModel.fromMap(TaskModel.fromEntity(original).toMap()).toEntity();

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.category, original.category);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.dueDate, original.dueDate);
      expect(restored.reminderTime, original.reminderTime);
      expect(restored.sortOrder, original.sortOrder);
    });
  });
}
