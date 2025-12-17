import 'package:flutter/material.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/tasks/screens/task_list_screen.dart';
import '../features/tasks/screens/add_task_screen.dart';
import 'app_routes.dart';

/// Route generator untuk handle navigation
///
/// CATATAN: Akan diperluas di pertemuan selanjutnya
class RouteGenerator {
  RouteGenerator._();

  /// Get screen widget by route name (for direct widget access)
  static Widget getScreen(String routeName) {
    switch (routeName) {
      case AppRoutes.splash:
        return const SplashScreen();
      case AppRoutes.login:
        return const LoginScreen();
      case AppRoutes.taskList:
        return const TaskListScreen();
      case AppRoutes.addTask:
        return const AddTaskScreen();
      default:
        return Scaffold(
          body: Center(
            child: Text('No route defined for $routeName'),
          ),
        );
    }
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case AppRoutes.taskList:
        return MaterialPageRoute(
          builder: (_) => const TaskListScreen(),
        );

      case AppRoutes.addTask:
        return MaterialPageRoute(
          builder: (_) => const AddTaskScreen(),
        );

      // Routes lain akan ditambahkan di sini sesuai kebutuhan

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
