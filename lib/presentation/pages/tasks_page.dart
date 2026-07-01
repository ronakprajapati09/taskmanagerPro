import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/router/page_transitions.dart';
import '../../domain/entities/task_category.dart';
import '../../domain/entities/task_filter.dart';
import '../bloc/task/task_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_tile.dart';
import 'add_edit_task_page.dart';

/// Full task list with debounced search, filters and drag-and-drop reordering.
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Reflect any persisted search query in the field.
    final query = context.read<TaskBloc>().state.filter.searchQuery;
    _searchController.text = query;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<TaskBloc>().add(SearchQueryChanged(value));
    });
  }

  void _openEdit(task) {
    Navigator.of(context).push(
      AppPageRoutes.slideUp(
        BlocProvider.value(
          value: context.read<TaskBloc>(),
          child: AddEditTaskPage(existing: task),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilters(),
            Expanded(
              child: BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  if (state.status == TaskStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == TaskStatus.failure) {
                    return EmptyState(
                      icon: Icons.error_outline,
                      title: 'Something went wrong',
                      message: state.errorMessage ??
                          'We could not load your tasks.',
                      actionLabel: 'Retry',
                      onAction: () =>
                          context.read<TaskBloc>().add(const TasksLoaded()),
                    );
                  }
                  return _buildList(state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text('My Tasks',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          BlocBuilder<TaskBloc, TaskState>(
            buildWhen: (a, b) => a.filter != b.filter,
            builder: (context, state) {
              if (!state.filter.isActive) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () =>
                    context.read<TaskBloc>().add(const FiltersCleared()),
                icon: const Icon(Icons.filter_alt_off, size: 18),
                label: const Text('Clear'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search tasks…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<TaskBloc>().add(const SearchQueryChanged(''));
                    setState(() {});
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return BlocBuilder<TaskBloc, TaskState>(
      buildWhen: (a, b) => a.filter != b.filter,
      builder: (context, state) {
        final filter = state.filter;
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Status filter chips.
              for (final status in StatusFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status.label),
                    selected: filter.status == status,
                    onSelected: (_) => context
                        .read<TaskBloc>()
                        .add(FilterStatusChanged(status)),
                  ),
                ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 10),
                color: Theme.of(context).dividerColor,
              ),
              // Category filter chips.
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: filter.category == null,
                  onSelected: (_) => context
                      .read<TaskBloc>()
                      .add(const FilterCategoryChanged(null)),
                ),
              ),
              for (final cat in TaskCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(cat.icon, size: 16, color: cat.color),
                    label: Text(cat.label),
                    selected: filter.category == cat,
                    onSelected: (_) => context
                        .read<TaskBloc>()
                        .add(FilterCategoryChanged(cat)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(TaskState state) {
    if (state.allTasks.isEmpty) {
      return const EmptyState(
        icon: Icons.checklist_rtl,
        title: 'No tasks yet',
        message: 'Tap the + button to create your first task.',
      );
    }
    if (state.filteredTasks.isEmpty) {
      final searching = state.filter.searchQuery.trim().isNotEmpty;
      return EmptyState(
        icon: searching ? Icons.search_off : Icons.filter_alt_off,
        title: searching ? 'No search results' : 'No tasks match your filters',
        message: searching
            ? 'Try a different search term.'
            : 'Adjust or clear your filters to see more tasks.',
        actionLabel: 'Clear filters',
        onAction: () => context.read<TaskBloc>().add(const FiltersCleared()),
      );
    }

    final tasks = state.filteredTasks;
    // Reordering is only meaningful with the default (no-filter) ordering.
    final canReorder = !state.filter.isActive;

    if (!canReorder) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskTile(
            key: ValueKey(task.id),
            task: task,
            onToggle: () =>
                context.read<TaskBloc>().add(TaskCompletionToggled(task)),
            onTap: () => _openEdit(task),
            onSwipeDelete: () =>
                context.read<TaskBloc>().add(TaskSoftDeleted(task.id)),
          );
        },
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      buildDefaultDragHandles: false,
      itemCount: tasks.length,
      onReorder: (oldIndex, newIndex) => context
          .read<TaskBloc>()
          .add(TasksReordered(oldIndex, newIndex)),
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        elevation: 6,
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          key: ValueKey(task.id),
          padding: const EdgeInsets.only(bottom: 10),
          child: TaskTile(
            task: task,
            reorderIndex: index,
            onToggle: () =>
                context.read<TaskBloc>().add(TaskCompletionToggled(task)),
            onTap: () => _openEdit(task),
            onSwipeDelete: () =>
                context.read<TaskBloc>().add(TaskSoftDeleted(task.id)),
          ),
        );
      },
    );
  }
}

