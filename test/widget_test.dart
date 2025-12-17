// Basic Flutter widget test for StudyTracker app
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:study_tracker/app.dart';
import 'package:study_tracker/api/task_api.dart';
import 'package:study_tracker/providers/task_provider.dart';

void main() {
  testWidgets('StudyTracker app smoke test', (WidgetTester tester) async {
    // Create TaskApiService and TaskProvider for test
    final taskApi = TaskApiService();
    final taskProvider = TaskProvider(taskApi);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: taskProvider,
        child: const StudyTrackerApp(),
      ),
    );

    // Verify that the app starts (shows login screen since not authenticated)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
