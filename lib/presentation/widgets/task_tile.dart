import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/date_utils.dart';
import '../../domain/entities/task.dart';
import 'app_card.dart';

/// A single task row. Wrapped in a [Dismissible] for swipe-to-delete.
/// The delete is reported via [onSwipeDelete]; actual DB removal is deferred
/// by the bloc so it can be undone.
class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onSwipeDelete;

  /// Optional drag handle index for reorderable lists.
  final int? reorderIndex;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onSwipeDelete,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue =
        !task.isCompleted && AppDateUtils.isOverdue(task.dueDate);

    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onSwipeDelete();
      },
      background: _swipeBackground(scheme),
      child: AppCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _CompletionCheckbox(
                  isCompleted: task.isCompleted,
                  color: task.category.color,
                  onTap: onToggle,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _CategoryChip(task: task),
                          if (task.dueDate != null) ...[
                            const SizedBox(width: 8),
                            _DueChip(
                              dueDate: task.dueDate!,
                              overdue: overdue,
                              hasReminder: task.reminderTime != null,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (reorderIndex != null)
                  ReorderableDragStartListener(
                    index: reorderIndex!,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.drag_handle,
                          color: scheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeBackground(ColorScheme scheme) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Delete',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Icon(Icons.delete_outline, color: Colors.white),
        ],
      ),
    );
  }
}

class _CompletionCheckbox extends StatelessWidget {
  final bool isCompleted;
  final Color color;
  final VoidCallback onTap;

  const _CompletionCheckbox({
    required this.isCompleted,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isCompleted ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? color : color.withAlpha(153),
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Task task;
  const _CategoryChip({required this.task});

  @override
  Widget build(BuildContext context) {
    final color = task.category.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(task.category.icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            task.category.label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  final DateTime dueDate;
  final bool overdue;
  final bool hasReminder;

  const _DueChip({
    required this.dueDate,
    required this.overdue,
    required this.hasReminder,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = overdue ? scheme.error : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(overdue ? Icons.event_busy : Icons.event,
            size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          AppDateUtils.relativeLabel(dueDate),
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        if (hasReminder) ...[
          const SizedBox(width: 6),
          Icon(Icons.notifications_active_outlined, size: 13, color: color),
        ],
      ],
    );
  }
}


