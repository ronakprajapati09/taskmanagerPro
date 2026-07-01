import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/database_helper.dart';
import '../../data/datasources/task_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/task_usecases.dart';
import '../services/notification_service.dart';

/// Tiny manual service locator. Keeps wiring in one place without pulling in a
/// heavier DI package. Call [AppDependencies.init] once before runApp().
class AppDependencies {
  AppDependencies._();

  static late final SettingsRepository settingsRepository;
  static late final TaskRepository taskRepository;

  static late final GetTasks getTasks;
  static late final AddTask addTask;
  static late final UpdateTask updateTask;
  static late final DeleteTask deleteTask;
  static late final ReorderTasks reorderTasks;
  static late final ToggleTaskCompletion toggleTaskCompletion;

  static final NotificationService notificationService =
      NotificationService.instance;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    settingsRepository = SettingsRepositoryImpl(prefs);

    final localDataSource = TaskLocalDataSourceImpl(DatabaseHelper.instance);
    taskRepository = TaskRepositoryImpl(localDataSource);

    getTasks = GetTasks(taskRepository);
    addTask = AddTask(taskRepository);
    updateTask = UpdateTask(taskRepository);
    deleteTask = DeleteTask(taskRepository);
    reorderTasks = ReorderTasks(taskRepository);
    toggleTaskCompletion = ToggleTaskCompletion(taskRepository);
  }
}

