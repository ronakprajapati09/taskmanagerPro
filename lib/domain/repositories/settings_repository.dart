import '../entities/task_filter.dart';

/// Persistence for small app settings: theme and active filters.
abstract class SettingsRepository {
  /// 'light' | 'dark' | 'system'. Read synchronously-cached value before the
  /// first frame to avoid a white flash.
  Future<String> getThemeMode();
  Future<void> saveThemeMode(String mode);

  Future<TaskFilter> getFilter();
  Future<void> saveFilter(TaskFilter filter);
}

