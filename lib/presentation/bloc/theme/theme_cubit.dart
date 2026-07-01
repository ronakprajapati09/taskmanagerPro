import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/settings_repository.dart';

/// Owns the active [ThemeMode]. Seeded synchronously with the value loaded
/// before runApp() so the first frame already uses the correct theme
/// (no white flash on cold start).
class ThemeCubit extends Cubit<ThemeMode> {
  final SettingsRepository settingsRepository;

  ThemeCubit(this.settingsRepository, ThemeMode initial) : super(initial);

  static ThemeMode parse(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    await settingsRepository.saveThemeMode(serialize(mode));
  }

  Future<void> toggle(Brightness platformBrightness) async {
    final isDark = state == ThemeMode.dark ||
        (state == ThemeMode.system && platformBrightness == Brightness.dark);
    await setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}

