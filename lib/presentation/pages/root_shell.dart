import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/router/page_transitions.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/entities/task_filter.dart';
import '../bloc/task/task_bloc.dart';
import '../widgets/animated_fab.dart';
import '../widgets/undo_countdown_snackbar.dart';
import 'add_edit_task_page.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';
import 'tasks_page.dart';

/// App scaffold hosting the bottom navigation bar, the expandable FAB and the
/// global undo-snackbar listener.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  int _lastSoftDeleteNonce = 0;
  final _fabKey = GlobalKey<AnimatedFabState>();

  void _goToTasks() => setState(() => _index = 1);

  /// Switch to the Tasks tab and apply the given filters immediately.
  void _goToTasksWithFilter(StatusFilter status, DueDateFilter dueDate) {
    // First clear existing filters, then apply the requested ones.
    final bloc = context.read<TaskBloc>();
    bloc.add(const FiltersCleared());
    if (status != StatusFilter.all) {
      bloc.add(FilterStatusChanged(status));
    }
    if (dueDate != DueDateFilter.any) {
      bloc.add(FilterDueDateChanged(dueDate));
    }
    setState(() => _index = 1);
  }

  void _openCreate(TaskCategory category) {
    Navigator.of(context).push(
      AppPageRoutes.slideUp(
        BlocProvider.value(
          value: context.read<TaskBloc>(),
          child: AddEditTaskPage(initialCategory: category),
        ),
      ),
    );
  }

  void _handleSoftDelete(BuildContext context, TaskState state) {
    if (state.softDeleteNonce == _lastSoftDeleteNonce) return;
    _lastSoftDeleteNonce = state.softDeleteNonce;
    final task = state.softDeletedTask;
    if (task == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: kUndoWindow,
        backgroundColor: const Color(0xFF2A2F3A),
        content: UndoCountdownContent(
          taskTitle: task.title,
          duration: kUndoWindow,
          onUndo: () {
            messenger.hideCurrentSnackBar();
            context.read<TaskBloc>().add(TaskDeleteUndone(task.id));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onSeeAllTasks: _goToTasks,
        onStatChipTapped: _goToTasksWithFilter,
      ),
      const TasksPage(),
      const StatsPage(),
      const SettingsPage(),
    ];

    final showFab = _index == 0 || _index == 1;

    return BlocListener<TaskBloc, TaskState>(
      listenWhen: (a, b) => a.softDeleteNonce != b.softDeleteNonce,
      listener: _handleSoftDelete,
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(index: _index, children: pages),
            if (showFab)
              Positioned(
                right: 16,
                bottom: 16,
                left: 16,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: AnimatedFab(
                    key: _fabKey,
                    actions: [
                      FabAction(
                        icon: TaskCategory.work.icon,
                        label: 'Work task',
                        color: TaskCategory.work.color,
                        onTap: () => _openCreate(TaskCategory.work),
                      ),
                      FabAction(
                        icon: TaskCategory.personal.icon,
                        label: 'Personal task',
                        color: TaskCategory.personal.color,
                        onTap: () => _openCreate(TaskCategory.personal),
                      ),
                      FabAction(
                        icon: TaskCategory.urgent.icon,
                        label: 'Urgent task',
                        color: TaskCategory.urgent.color,
                        onTap: () => _openCreate(TaskCategory.urgent),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            _fabKey.currentState?.close();
            setState(() => _index = i);
          },
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist),
                label: 'Tasks'),
            NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Stats'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

