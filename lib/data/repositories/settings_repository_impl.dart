import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/task_category.dart';
import '../../domain/entities/task_filter.dart';
import '../../domain/repositories/settings_repository.dart';

/// Settings persistence backed by SharedPreferences.
/// Only small values (theme, filters) live here — tasks use SQLite.
class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences prefs;

  SettingsRepositoryImpl(this.prefs);

  static const _kThemeMode = 'settings.themeMode';
  static const _kFilterCategory = 'settings.filter.category';
  static const _kFilterStatus = 'settings.filter.status';
  static const _kFilterDueDate = 'settings.filter.dueDate';
  static const _kFilterSearch = 'settings.filter.search';

  @override
  Future<String> getThemeMode() async {
    return prefs.getString(_kThemeMode) ?? 'system';
  }

  @override
  Future<void> saveThemeMode(String mode) async {
    await prefs.setString(_kThemeMode, mode);
  }

  @override
  Future<TaskFilter> getFilter() async {
    final categoryKey = prefs.getString(_kFilterCategory);
    return TaskFilter(
      category: categoryKey == null
          ? null
          : TaskCategory.fromStorage(categoryKey),
      status: StatusFilter.fromStorage(prefs.getString(_kFilterStatus)),
      dueDate: DueDateFilter.fromStorage(prefs.getString(_kFilterDueDate)),
      searchQuery: prefs.getString(_kFilterSearch) ?? '',
    );
  }

  @override
  Future<void> saveFilter(TaskFilter filter) async {
    if (filter.category == null) {
      await prefs.remove(_kFilterCategory);
    } else {
      await prefs.setString(_kFilterCategory, filter.category!.storageKey);
    }
    await prefs.setString(_kFilterStatus, filter.status.storageKey);
    await prefs.setString(_kFilterDueDate, filter.dueDate.storageKey);
    await prefs.setString(_kFilterSearch, filter.searchQuery);
  }
}

