  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';

  import '../../core/utils/date_utils.dart';
  import '../../domain/entities/task.dart';
  import '../../domain/entities/task_category.dart';
  import '../bloc/task/task_bloc.dart';

  /// Create or edit a task. Local form state uses [setState] (allowed for form
  /// fields); persistence goes through the TaskBloc / repository.
  class AddEditTaskPage extends StatefulWidget {
    final Task? existing;
    final TaskCategory? initialCategory;

    const AddEditTaskPage({super.key, this.existing, this.initialCategory});

    @override
    State<AddEditTaskPage> createState() => _AddEditTaskPageState();
  }

  class _AddEditTaskPageState extends State<AddEditTaskPage> {
    final _formKey = GlobalKey<FormState>();
    late final TextEditingController _titleController;
    late final TextEditingController _descController;

    late TaskCategory _category;
    DateTime? _dueDate;
    DateTime? _reminderTime;

    bool get _isEditing => widget.existing != null;

    @override
    void initState() {
      super.initState();
      final t = widget.existing;
      _titleController = TextEditingController(text: t?.title ?? '');
      _descController = TextEditingController(text: t?.description ?? '');
      _category = t?.category ?? widget.initialCategory ?? TaskCategory.personal;
      _dueDate = t?.dueDate;
      _reminderTime = t?.reminderTime;
    }

    @override
    void dispose() {
      _titleController.dispose();
      _descController.dispose();
      super.dispose();
    }

    Future<void> _pickDueDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: _dueDate ?? now,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 5),
      );
      if (picked != null) {
        setState(() => _dueDate =
            DateTime(picked.year, picked.month, picked.day, 9, 0));
      }
    }

    Future<void> _pickReminder() async {
      final base = _dueDate ?? DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: _reminderTime ?? base,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime(DateTime.now().year + 5),
      );
      if (date == null || !mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderTime ?? base),
      );
      if (time == null) return;
      setState(() {
        _reminderTime =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
      });
    }

    void _save() {
      if (!_formKey.currentState!.validate()) return;
      final now = DateTime.now();
      final bloc = context.read<TaskBloc>();

      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          category: _category,
          dueDate: _dueDate,
          reminderTime: _reminderTime,
          updatedAt: now,
          clearDueDate: _dueDate == null,
          clearReminder: _reminderTime == null,
        );
        bloc.add(TaskUpdated(updated));
      } else {
        // sortOrder: append to the end of the current list.
        final nextOrder = bloc.state.allTasks.length;
        final task = Task(
          id: 'task_${now.microsecondsSinceEpoch}',
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          category: _category,
          dueDate: _dueDate,
          reminderTime: _reminderTime,
          createdAt: now,
          updatedAt: now,
          sortOrder: nextOrder,
        );
        bloc.add(TaskAdded(task));
      }
      Navigator.of(context).pop();
    }

    @override
    Widget build(BuildContext context) {
      final scheme = Theme.of(context).colorScheme;
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Task' : 'New Task'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'What needs to be done?',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add more details (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              Text('Category', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskCategory.values.map((c) {
                  final selected = c == _category;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(c.label),
                    avatar: Icon(c.icon,
                        size: 18,
                        color: selected ? Colors.white : c.color),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: c.color,
                    backgroundColor: c.color.withAlpha(31),
                    onSelected: (_) => setState(() => _category = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _PickerTile(
                icon: Icons.event,
                label: 'Due date',
                value: _dueDate == null
                    ? 'Not set'
                    : AppDateUtils.formatDate(_dueDate!),
                onTap: _pickDueDate,
                onClear: _dueDate == null
                    ? null
                    : () => setState(() => _dueDate = null),
              ),
              const SizedBox(height: 12),
              _PickerTile(
                icon: Icons.notifications_active_outlined,
                label: 'Reminder',
                value: _reminderTime == null
                    ? 'Not set'
                    : AppDateUtils.formatDateTime(_reminderTime!),
                onTap: _pickReminder,
                onClear: _reminderTime == null
                    ? null
                    : () => setState(() => _reminderTime = null),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: FilledButton.icon(
            onPressed: _save,
            icon: Icon(_isEditing ? Icons.save : Icons.add_task),
            label: Text(_isEditing ? 'Save Changes' : 'Create Task'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      );
    }
  }

  class _PickerTile extends StatelessWidget {
    final IconData icon;
    final String label;
    final String value;
    final VoidCallback onTap;
    final VoidCallback? onClear;

    const _PickerTile({
      required this.icon,
      required this.label,
      required this.value,
      required this.onTap,
      this.onClear,
    });

    @override
    Widget build(BuildContext context) {
      final scheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Material(
        color: isDark ? const Color(0xFF171C24) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant)),
                      Text(value,
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: onClear,
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }


