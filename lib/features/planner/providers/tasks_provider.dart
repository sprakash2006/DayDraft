import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notetracker/features/planner/models/task.dart';
import 'package:notetracker/shared/services/db_service.dart';
import 'package:notetracker/shared/services/notification_service.dart';

/// Currently selected date in the planner calendar.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Tasks for the selected date — derived synchronously from tasksProvider state.
/// No DB round-trip needed: mutations update in-memory state, this filters instantly.
final tasksForDateProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final date = ref.watch(selectedDateProvider);
  final target = DateTime(date.year, date.month, date.day);
  return ref.watch(tasksProvider).whenData((allTasks) => allTasks
      .where((t) => DateTime(t.date.year, t.date.month, t.date.day) == target)
      .toList());
});

final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);

class TasksNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    return DbService.instance.getAllTasks();
  }

  Future<void> saveTask(Task task) async {
    final isNew = task.id == null;
    if (isNew) task.createdAt = DateTime.now();
    await DbService.instance.saveTask(task);

    if (task.reminderEnabled) {
      await NotificationService.instance.scheduleTaskReminder(task);
    } else if (!isNew) {
      await NotificationService.instance.cancelReminder(task.id!);
    }

    // Update in-memory state immediately — no invalidation needed
    state = state.whenData((tasks) {
      if (isNew) return [...tasks, task];
      return tasks.map((t) => t.id == task.id ? task : t).toList();
    });
  }

  Future<void> deleteTask(int id) async {
    // Optimistic update: remove from state before DB call so UI is instant
    state = state.whenData((tasks) => tasks.where((t) => t.id != id).toList());
    await DbService.instance.deleteTask(id);
    await NotificationService.instance.cancelReminder(id);
  }

  Future<void> toggleDone(Task task) async {
    task.isDone = !task.isDone;
    // Optimistic update: reflect change immediately
    state = state.whenData(
        (tasks) => tasks.map((t) => t.id == task.id ? task : t).toList());
    await DbService.instance.saveTask(task);
  }
}
