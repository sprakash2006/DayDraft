import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notetracker/features/planner/models/task.dart';
import 'package:notetracker/features/planner/providers/tasks_provider.dart';

class TaskEditorScreen extends ConsumerStatefulWidget {
  final Task? existingTask;
  final DateTime initialDate;

  const TaskEditorScreen({
    super.key,
    this.existingTask,
    required this.initialDate,
  });

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  late TaskPriority _priority;
  late bool _reminderEnabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _selectedDate = task?.date ?? widget.initialDate;
    _priority = task?.priority ?? TaskPriority.medium;
    _reminderEnabled = task?.reminderEnabled ?? false;

    if (task != null && task.timeMins >= 0) {
      _selectedTime = TimeOfDay(hour: task.hour!, minute: task.minute!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final task = widget.existingTask ?? Task();
    task.title = _titleController.text.trim();
    task.date =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    task.timeMins = _selectedTime != null
        ? _selectedTime!.hour * 60 + _selectedTime!.minute
        : -1;
    task.priority = _priority;
    task.reminderEnabled = _reminderEnabled && _selectedTime != null;

    await ref.read(tasksProvider.notifier).saveTask(task);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask == null ? 'New Task' : 'Edit Task'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              autofocus: true,
              style: theme.textTheme.titleMedium,
              decoration: const InputDecoration(
                hintText: 'Task title',
                border: OutlineInputBorder(),
                labelText: 'Title',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            const Divider(),

            // Time
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time_outlined),
              title: const Text('Time'),
              subtitle: Text(
                _selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'No time set',
              ),
              trailing: _selectedTime != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _selectedTime = null),
                    )
                  : null,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? TimeOfDay.now(),
                );
                if (picked != null) setState(() => _selectedTime = picked);
              },
            ),
            const Divider(),

            // Priority
            const SizedBox(height: 8),
            Text('Priority', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: const [
                ButtonSegment(value: TaskPriority.low, label: Text('Low')),
                ButtonSegment(
                    value: TaskPriority.medium, label: Text('Medium')),
                ButtonSegment(value: TaskPriority.high, label: Text('High')),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 16),

            // Reminder
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Reminder'),
              subtitle: _selectedTime == null
                  ? const Text('Set a time first to enable reminders')
                  : null,
              value: _reminderEnabled,
              onChanged: _selectedTime != null
                  ? (v) => setState(() => _reminderEnabled = v)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
