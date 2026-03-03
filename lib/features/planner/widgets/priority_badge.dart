import 'package:flutter/material.dart';
import 'package:notetracker/features/planner/models/task.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (priority) {
      TaskPriority.high => (Colors.red.shade400, 'High'),
      TaskPriority.medium => (Colors.orange.shade400, 'Medium'),
      TaskPriority.low => (Colors.green.shade400, 'Low'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
