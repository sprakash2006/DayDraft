import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notetracker/app.dart';
import 'package:notetracker/shared/services/db_service.dart';
import 'package:notetracker/shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DbService.instance.init();
  await NotificationService.instance.init();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
