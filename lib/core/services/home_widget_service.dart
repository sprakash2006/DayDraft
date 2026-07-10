import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:notetracker/shared/services/db_service.dart';
import 'package:notetracker/shared/widgets/home_widget/today_task_widget.dart';

class HomeWidgetService {
  static const String _androidWidgetName = 'TaskWidgetProvider';

  static Future<void> updateWidget() async {
    try {
      // Ensure DB is initialized (especially if called from a background context)
      await DbService.instance.init();

      final now = DateTime.now();
      // Show incomplete timeless tasks that are due today.
      final allTasks = await DbService.instance.getAllTimelessTodos();
      final incompleteTasks = allTasks.where((t) {
        return !t.isDone &&
            t.dueAt.year == now.year &&
            t.dueAt.month == now.month &&
            t.dueAt.day == now.day;
      }).toList();

      // Render the Flutter widget to an image
      final snapshot = await HomeWidget.renderFlutterWidget(
        TodayTaskWidget(tasks: incompleteTasks),
        key: 'task_snapshot',
        logicalSize: const Size(600, 600),
        pixelRatio: 2.0,
      );

      if (snapshot != null) {
        await HomeWidget.saveWidgetData<String>('task_snapshot_path', snapshot.path);
        
        await HomeWidget.updateWidget(
          androidName: _androidWidgetName,
          qualifiedAndroidName: 'com.example.notetracker.$_androidWidgetName',
        );
      } else {
        debugPrint('HomeWidget: Snapshot rendering failed');
      }
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }
}
