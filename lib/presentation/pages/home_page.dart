import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/router/page_transitions.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_filter.dart';
import '../bloc/task/task_bloc.dart';
import '../bloc/theme/theme_cubit.dart';
import '../widgets/app_card.dart';
import '../widgets/progress_ring.dart';
import '../widgets/task_tile.dart';
import 'add_edit_task_page.dart';

/// Dashboard / home screen: greeting, today's progress ring, quick stats and
/// the list of tasks due today.
class HomePage extends StatelessWidget {
  final VoidCallback onSeeAllTasks;

  /// Called when a stat chip is tapped. The caller should switch to the Tasks
  /// tab and apply [status] + [dueDate] filters accordingly.
  final void Function(StatusFilter status, DueDateFilter dueDate)
      onStatChipTapped;

  const HomePage({
    super.key,
    required this.onSeeAllTasks,
    required this.onStatChipTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state.status == TaskStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                _greeting(context),
                const SizedBox(height: 10),
                _progressAppCard(context, state),
                const SizedBox(height: 16),
                _statRow(context, state),
                const SizedBox(height: 10),
                _todayHeader(context, state),
                const SizedBox(height: 0),
                ..._todayTasks(context, state),
                const SizedBox(height:0),
                _upcomingHeader(context, state),
                const SizedBox(height: 0),
                ..._upcomingTasks(context, state),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(AppDateUtils.formatDate(DateTime.now()),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const _ThemeToggleButton(),
      ],
    );
  }

  Widget _progressAppCard(BuildContext context, TaskState state) {
    final scheme = Theme.of(context).colorScheme;
    final today = state.todayTasks;
    final completed = today.where((t) => t.isCompleted).length;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            ProgressRing(
              progress: state.todayProgress,
              size: 120,
              strokeWidth: 12,
              caption: 'Today',
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Progress",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    today.isEmpty
                        ? 'No tasks due today. Enjoy your day!'
                        : '$completed of ${today.length} tasks completed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(BuildContext context, TaskState state) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.list_alt,
          label: 'Total',
          value: '${state.totalCount}',
          color: const Color(0xFF4C6FFF),
          onTap: () => onStatChipTapped(StatusFilter.all, DueDateFilter.any),
        ),
        const SizedBox(width: 12),
        _StatChip(
          icon: Icons.pending_actions,
          label: 'Pending',
          value: '${state.pendingCount}',
          color: const Color(0xFFFFA62B),
          onTap: () =>
              onStatChipTapped(StatusFilter.pending, DueDateFilter.any),
        ),
        const SizedBox(width: 12),
        _StatChip(
          icon: Icons.event_busy,
          label: 'Overdue',
          value: '${state.overdueCount}',
          color: const Color(0xFFFF5A5F),
          onTap: () =>
              onStatChipTapped(StatusFilter.pending, DueDateFilter.overdue),
        ),
      ],
    );
  }

  Widget _todayHeader(BuildContext context, TaskState state) {
    return Row(
      children: [
        Text('Due Today',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(onPressed: onSeeAllTasks, child: const Text('See all')),
      ],
    );
  }

  List<Widget> _todayTasks(BuildContext context, TaskState state) {
    final today = state.todayTasks;
    if (today.isEmpty) {
      return [
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.wb_sunny_outlined,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Nothing due today. Tap + to plan something.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return today
        .map<Widget>((task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TaskTile(
                key: ValueKey('home_${task.id}'),
                task: task,
                onToggle: () =>
                    context.read<TaskBloc>().add(TaskCompletionToggled(task)),
                onTap: () => _openEdit(context, task),
                onSwipeDelete: () =>
                    context.read<TaskBloc>().add(TaskSoftDeleted(task.id)),
              ),
            ))
        .toList();
  }

  void _openEdit(BuildContext context, Task task) {
    Navigator.of(context).push(
      AppPageRoutes.slideUp(
        BlocProvider.value(
          value: context.read<TaskBloc>(),
          child: AddEditTaskPage(existing: task),
        ),
      ),
    );
  }

  // ── Upcoming section ──────────────────────────────────────────────────────

  Widget _upcomingHeader(BuildContext context, TaskState state) {
    return Row(
      children: [
        Text('Upcoming',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(
          onPressed: () =>
              onStatChipTapped(StatusFilter.pending, DueDateFilter.upcoming),
          child: const Text('See all'),
        ),
      ],
    );
  }

  List<Widget> _upcomingTasks(BuildContext context, TaskState state) {
    final upcoming = state.upcomingTasks;

    if (upcoming.isEmpty) {
      return [
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'No upcoming tasks. You\'re all caught up!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // Group tasks by their date label (Tomorrow / In X days / date string).
    final Map<String, List<Task>> grouped = {};
    for (final task in upcoming) {
      final label = AppDateUtils.relativeLabel(task.dueDate!);
      grouped.putIfAbsent(label, () => []).add(task);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      // Date group header.
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.key,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      );
      // Tasks under that date.
      for (final task in entry.value) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TaskTile(
              key: ValueKey('upcoming_${task.id}'),
              task: task,
              onToggle: () =>
                  context.read<TaskBloc>().add(TaskCompletionToggled(task)),
              onTap: () => _openEdit(context, task),
              onSwipeDelete: () =>
                  context.read<TaskBloc>().add(TaskSoftDeleted(task.id)),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    final platformBrightness = MediaQuery.of(context).platformBrightness;
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system && platformBrightness == Brightness.dark);
    return IconButton.filledTonal(
      tooltip: 'Toggle theme',
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      onPressed: () =>
          context.read<ThemeCubit>().toggle(platformBrightness),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 8),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


