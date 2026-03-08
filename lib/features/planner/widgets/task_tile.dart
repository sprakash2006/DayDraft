import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notetracker/features/planner/models/task.dart';
import 'package:notetracker/features/planner/providers/tasks_provider.dart';

class TaskTile extends ConsumerWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  // Solid priority accent colour
  Color _priorityAccent() => switch (task.priority) {
        TaskPriority.high => const Color(0xFFE53935),
        TaskPriority.medium => const Color(0xFFFB8C00),
        TaskPriority.low => const Color(0xFF43A047),
      };

  // Light tinted card background per priority
  Color _priorityBg() => switch (task.priority) {
        TaskPriority.high => const Color(0xFFFFEBEE),
        TaskPriority.medium => const Color(0xFFFFF8E1),
        TaskPriority.low => const Color(0xFFE8F5E9),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(tasksProvider.notifier);

    const titleColor = Color(0xFF212121);
    const doneColor = Color(0xFF9E9E9E);
    const subColor = Color(0xFF616161);

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
    final canToggle = !taskDate.isBefore(todayDate);

    final accent = _priorityAccent();
    final bg = task.isDone ? const Color(0xFFF5F5F5) : _priorityBg();

    final titleStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: task.isDone ? doneColor : titleColor,
      decoration: task.isDone ? TextDecoration.lineThrough : null,
      decorationColor: doneColor,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        // Uniform border is required when using borderRadius
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canToggle
              ? () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      insetPadding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(ctx).size.width * 0.15,
                          vertical: 24),
                      title: Text(task.isDone
                          ? 'Mark as incomplete?'
                          : 'Mark as done?'),
                      content: Text(task.isDone
                          ? 'Do you want to mark this task as incomplete?'
                          : 'Do you want to mark this task as done?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) notifier.toggleDone(task);
                }
              : null,
          child: Tooltip(
            message: canToggle
                ? ''
                : 'Tap the checkbox area to toggle (disabled for past days)',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 12),
                // Circular checkbox (visual only)
                Opacity(
                  opacity: canToggle ? 1.0 : 0.4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 2),
                      color: task.isDone ? accent : Colors.transparent,
                    ),
                    child: task.isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                // Title + meta
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(task.title, style: titleStyle),
                        if (task.timeMins >= 0 || task.reminderEnabled) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (task.timeMins >= 0) ...[
                                Icon(Icons.access_time,
                                    size: 12, color: subColor),
                                const SizedBox(width: 3),
                                Text(
                                  _formatTime(),
                                  style:
                                      TextStyle(fontSize: 12, color: subColor),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (task.reminderEnabled)
                                Icon(Icons.notifications_active,
                                    size: 12, color: accent),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Color(0xFFE53935)),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        insetPadding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(ctx).size.width * 0.15,
                            vertical: 24),
                        title: const Text('Delete task?'),
                        content: Text(
                            'Are you sure you want to delete "${task.title}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFE53935)),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) notifier.deleteTask(task.id!);
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime() {
    final dt = DateTime(0, 0, 0, task.hour!, task.minute!);
    return DateFormat.jm().format(dt);
  }
}
