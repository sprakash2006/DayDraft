import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notetracker/app.dart';
import 'package:notetracker/shared/services/db_service.dart';
import 'package:notetracker/shared/services/notification_service.dart';
import 'package:notetracker/core/services/home_widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DbService.instance.init();
  await NotificationService.instance.init();
  
  // Refresh the home widget on startup to ensure it's up to date
  await HomeWidgetService.updateWidget();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
