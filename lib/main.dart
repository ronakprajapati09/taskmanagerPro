import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/task/task_bloc.dart';
import 'presentation/bloc/theme/theme_cubit.dart';
import 'presentation/pages/root_shell.dart';
import 'presentation/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire up repositories, data sources and use cases.
  await AppDependencies.init();

  // Initialise notifications (bonus feature). Failure here must not block boot.
  await AppDependencies.notificationService.init();

  // IMPORTANT: load the saved theme *before* runApp so the very first frame
  // already paints with the correct brightness — no white flash on cold start.
  final savedThemeString =
      await AppDependencies.settingsRepository.getThemeMode();
  final initialThemeMode = ThemeCubit.parse(savedThemeString);

  runApp(TaskManagerApp(initialThemeMode: initialThemeMode));
}

class TaskManagerApp extends StatelessWidget {
  final ThemeMode initialThemeMode;

  const TaskManagerApp({super.key, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(
            AppDependencies.settingsRepository,
            initialThemeMode,
          ),
        ),
        BlocProvider<TaskBloc>(
          create: (_) => TaskBloc(
            getTasks: AppDependencies.getTasks,
            addTask: AppDependencies.addTask,
            updateTask: AppDependencies.updateTask,
            deleteTask: AppDependencies.deleteTask,
            reorderTasks: AppDependencies.reorderTasks,
            toggleTaskCompletion: AppDependencies.toggleTaskCompletion,
            settingsRepository: AppDependencies.settingsRepository,
            notificationService: AppDependencies.notificationService,
          )..add(const TasksLoaded()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Task Manager Pro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            home: const _AppEntry(),
          );
        },
      ),
    );
  }
}

/// Decides whether to show the splash screen first or go straight to the shell.
/// On first launch it shows [SplashPage]; once the splash completes it
/// transitions to [RootShell] with a smooth fade.
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _splashDone = false;

  void _onSplashComplete() {
    if (mounted) setState(() => _splashDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: _splashDone
          ? const RootShell(key: ValueKey('shell'))
          : SplashPage(
              key: const ValueKey('splash'),
              onComplete: _onSplashComplete,
            ),
    );
  }
}

