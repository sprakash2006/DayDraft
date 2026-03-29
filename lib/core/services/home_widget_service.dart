import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:notetracker/features/planner/models/task.dart';
import 'package:notetracker/shared/services/db_service.dart';
import 'package:notetracker/shared/widgets/home_widget/today_task_widget.dart';
import 'package:path_provider/path_provider.dart';

class HomeWidgetService {
  static const String _groupId = 'group.com.example.notetracker';
  static const String _androidWidgetName = 'TaskWidgetProvider';

  static Future<void> updateWidget() async {
    try {
      // Ensure DB is initialized (especially if called from a background context)
      await DbService.instance.init();
      
      final now = DateTime.now();
      // Fetch all tasks and filter in Dart for reliability across timezones/formats
      final allTasks = await DbService.instance.getAllTasks();
      final todayTasks = allTasks.where((t) {
        return t.date.year == now.year &&
               t.date.month == now.month &&
               t.date.day == now.day;
      }).toList();
      
      final incompleteTasks = todayTasks.where((t) => !t.isDone).toList();

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
