import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:study_tracker/api/task_api.dart';
import 'package:study_tracker/providers/task_provider.dart';
import 'package:study_tracker/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Indonesian locale for date formatting
  await initializeDateFormatting('id_ID', null);

  // Initialize API service
  final apiService = TaskApiService();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final taskProvider = TaskProvider(apiService);
        taskProvider.checkSession(); // Check saved session on app start
        return taskProvider;
      },
      child: const StudyTrackerApp(),
    ),
  );
}
