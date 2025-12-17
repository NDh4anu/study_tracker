import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'routes/route_generator.dart';
import 'routes/app_routes.dart';

/// Root widget untuk StudyTracker app
class StudyTrackerApp extends StatelessWidget {
  const StudyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // Theme - apply custom theme yang sudah dibuat
      theme: AppTheme.lightTheme,

      // Routing dengan auth-aware home
      onGenerateRoute: RouteGenerator.generateRoute,
      
      // Auth-aware home screen
      home: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          // Route based on authentication state
          if (taskProvider.isAuthenticated) {
            // Navigate to task list and load tasks
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (taskProvider.tasks.isEmpty && !taskProvider.isTaskLoading) {
                taskProvider.loadTasksOfflineFirst();
              }
            });
            return RouteGenerator.getScreen(AppRoutes.taskList);
          } else {
            return RouteGenerator.getScreen(AppRoutes.login);
          }
        },
      ),
    );
  }
}
