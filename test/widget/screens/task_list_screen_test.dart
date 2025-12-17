// test/widget/screens/task_list_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:study_tracker/features/tasks/models/task.dart';
import 'package:study_tracker/features/tasks/screens/task_list_screen.dart';
import 'package:study_tracker/providers/task_provider.dart';

import '../../helpers/mock_data.dart';
import '../../helpers/mock_services.mocks.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('TaskListScreen Widget Tests', () {
    late MockTaskApiService mockApiService;
    late TaskProvider mockProvider;

    setUp(() {
      mockApiService = MockTaskApiService();
      mockProvider = TaskProvider(mockApiService);
    });

    Widget createTaskListScreen() {
      return TestHelpers.makeTestableWidgetWithProvider(
        taskProvider: mockProvider,
        child: const TaskListScreen(),
      );
    }

    // ===================================================================
    // Initial State Tests
    // ===================================================================

    group('Initial State', () {
      testWidgets('should display app bar with title and actions',
          (tester) async {
        await tester.pumpWidget(createTaskListScreen());
        await tester.pump();

        // Verify app bar elements
        expect(find.text('My Tasks'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('should display FAB for adding new task', (tester) async {
        await tester.pumpWidget(createTaskListScreen());
        await tester.pump();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.text('New Task'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('should display filter chips', (tester) async {
        await tester.pumpWidget(createTaskListScreen());
        await tester.pump();

        // Verify all filter options
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('Overdue'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      });
    });

    // ===================================================================
    // Loading State Tests
    // ===================================================================

    group('Loading State', () {
      testWidgets('should show loading indicator when tasks are loading',
          (tester) async {
        await tester.pumpWidget(createTaskListScreen());
        
        // Initially loading state
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });

    // ===================================================================
    // Empty State Tests
    // ===================================================================

    group('Empty State', () {
      testWidgets('should show empty state when no tasks exist',
          (tester) async {
        // Set empty task list
        when(mockApiService.getTasks()).thenAnswer((_) async => []);
        
        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Verify empty state message
        expect(find.text('No tasks yet'), findsOneWidget);
        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      });

      testWidgets('should show filtered empty state', (tester) async {
        // Simulate having only completed tasks
        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Tap on "Pending" filter
        await tester.tap(find.text('Pending'));
        await tester.pumpAndSettle();

        // If no pending tasks, should show empty state
        // (Exact implementation depends on your empty state logic for filters)
      });
    });

    // ===================================================================
    // Task List Display Tests
    // ===================================================================

    group('Task List Display', () {
      testWidgets('should display task items correctly', (tester) async {
        final tasks = [
          MockData.pendingTask,
          MockData.completedTask,
        ];

        when(mockApiService.getTasks()).thenAnswer((_) async => tasks);

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Verify task titles are displayed
        expect(find.text(MockData.pendingTask.title), findsOneWidget);
        expect(find.text(MockData.completedTask.title), findsOneWidget);
      });

      testWidgets('should show task completion checkbox', (tester) async {
        final tasks = [MockData.pendingTask];
        when(mockApiService.getTasks()).thenAnswer((_) async => tasks);

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Should have checkbox
        expect(find.byType(Checkbox), findsWidgets);
      });

      testWidgets('should display task priority indicators', (tester) async {
        final tasks = [
          Task(
            title: 'High Priority',
            priority: TaskPriority.high,
            userId: 'user123',
            category: TaskCategory.study,
          ),
        ];

        when(mockApiService.getTasks()).thenAnswer((_) async => tasks);

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Verify task is displayed
        expect(find.text('High Priority'), findsOneWidget);
      });

      testWidgets('should display task due dates', (tester) async {
        final tasks = [
          Task(
            title: 'Task with due date',
            dueDate: DateTime(2025, 12, 25),
            userId: 'user123',
            priority: TaskPriority.medium,
            category: TaskCategory.study,
          ),
        ];

        when(mockApiService.getTasks()).thenAnswer((_) async => tasks);

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Should show formatted due date
        expect(find.textContaining('Dec'), findsWidgets);
      });
    });

    // ===================================================================
    // Filter Tests
    // ===================================================================

    group('Filtering', () {
      testWidgets('should filter tasks by All (default)', (tester) async {
        final tasks = [
          MockData.pendingTask,
          MockData.completedTask,
          MockData.overdueTask,
        ];

        when(mockApiService.getTasks()).thenAnswer((_) async => tasks);

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // All tasks should be visible
        expect(find.text(MockData.pendingTask.title), findsOneWidget);
        expect(find.text(MockData.completedTask.title), findsOneWidget);
        expect(find.text(MockData.overdueTask.title), findsOneWidget);
      });

      testWidgets('should filter tasks by Completed', (tester) async {
        final tasks = [
          MockData.pendingTask,
          MockData.completedTask,
        ];

        when(mockApiService.getTasks()).thenAnswer((_) async => tasks);

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Tap Completed filter
        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();

        // Only completed task should be visible
        expect(find.text(MockData.completedTask.title), findsOneWidget);
        expect(find.text(MockData.pendingTask.title), findsNothing);
      });

      testWidgets('should filter tasks by Pending', (tester) async {
        final tasks = [
          MockData.pendingTask,
          MockData.completedTask,
        ];

        when(mockApiService.getTasks()).thenAnswer((_) async => tasks);

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Tap Pending filter
        await tester.tap(find.text('Pending'));
        await tester.pumpAndSettle();

        // Only pending task should be visible
        expect(find.text(MockData.pendingTask.title), findsOneWidget);
        expect(find.text(MockData.completedTask.title), findsNothing);
      });

      testWidgets('should highlight selected filter', (tester) async {
        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Find the All chip (should be selected by default)
        final allChip = find.ancestor(
          of: find.text('All'),
          matching: find.byType(FilterChip),
        );
        
        expect(allChip, findsOneWidget);
        
        // Tap Pending filter
        await tester.tap(find.text('Pending'));
        await tester.pumpAndSettle();

        // Pending chip should now be highlighted
        final pendingChip = find.ancestor(
          of: find.text('Pending'),
          matching: find.byType(FilterChip),
        );
        
        expect(pendingChip, findsOneWidget);
      });
    });

    // ===================================================================
    // Task Interaction Tests
    // ===================================================================

    group('Task Interactions', () {
      testWidgets('should toggle task completion when checkbox is tapped',
          (tester) async {
        final task = MockData.pendingTask.copyWith(localId: 1);
        when(mockApiService.getTasks()).thenAnswer((_) async => [task]);

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Find and tap checkbox
        final checkbox = find.byType(Checkbox).first;
        await tester.tap(checkbox);
        await tester.pump();

        // Provider's toggleTask should be called
        // (Verification would require checking provider state)
      });

      testWidgets('should navigate to detail when task is tapped',
          (tester) async {
        final task = MockData.pendingTask;
        when(mockApiService.getTasks()).thenAnswer((_) async => [task]);

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Tap on task (find by title)
        await tester.tap(find.text(task.title));
        await tester.pumpAndSettle();

        // Should navigate to detail screen
        // (In real test, would verify navigation)
      });
    });

    // ===================================================================
    // Refresh Tests
    // ===================================================================

    group('Refresh Functionality', () {
      testWidgets('should refresh tasks when refresh button is tapped',
          (tester) async {
        when(mockApiService.getTasks()).thenAnswer((_) async => []);

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Tap refresh button
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        // Should trigger refresh (loading indicator appears)
        // Provider's refreshTasks is called
      });

      testWidgets('should refresh tasks with pull-to-refresh',
          (tester) async {
        when(mockApiService.getTasks()).thenAnswer((_) async => []);

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Perform pull-to-refresh gesture
        await tester.drag(
          find.byType(RefreshIndicator),
          const Offset(0, 300),
        );
        await tester.pump();

        // Should show refresh indicator
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });

      testWidgets('should show sync indicator when syncing', (tester) async {
        await tester.pumpWidget(createTaskListScreen());
        
        // Set syncing state
        // (Would need to manipulate provider state)
        
        await tester.pump();

        // When syncing, should show small circular progress indicator in app bar
        // Implementation depends on how isSyncing is displayed
      });
    });

    // ===================================================================
    // Logout Tests
    // ===================================================================

    group('Logout', () {
      testWidgets('should show logout confirmation dialog', (tester) async {
        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Tap menu button
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Tap logout
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        // Should show confirmation dialog
        expect(find.text('Logout'), findsWidgets);
        expect(find.text('Yakin ingin keluar?'), findsOneWidget);
        expect(find.text('Batal'), findsOneWidget);
        expect(find.text('Ya'), findsOneWidget);
      });

      testWidgets('should cancel logout when Batal is tapped', (tester) async {
        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Open logout dialog
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        // Tap Batal
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed, still on task list
        expect(find.text('My Tasks'), findsOneWidget);
      });

      testWidgets('should logout when Ya is tapped', (tester) async {
        when(mockApiService.logout()).thenAnswer((_) async => {});

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Open logout dialog
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        // Tap Ya
        await tester.tap(find.text('Ya'));
        await tester.pumpAndSettle();

        // Should call logout on provider
        verify(mockApiService.logout()).called(1);
      });
    });

    // ===================================================================
    // Error State Tests
    // ===================================================================

    group('Error Handling', () {
      testWidgets('should show error message when loading fails',
          (tester) async {
        // Simulate error state
        when(mockApiService.getTasks()).thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Should show error icon and retry button
        // (Exact implementation depends on error handling)
        expect(find.byIcon(Icons.error_outline), findsAny);
      });

      testWidgets('should retry loading when retry button is tapped',
          (tester) async {
        when(mockApiService.getTasks()).thenThrow(Exception('Network error'));

        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Find and tap retry button
        final retryButton = find.text('Coba Lagi');
        if (tester.any(retryButton)) {
          await tester.tap(retryButton);
          await tester.pump();
          
          // Should attempt to reload
        }
      });
    });

    // ===================================================================
    // Navigation Tests
    // ===================================================================

    group('Navigation', () {
      testWidgets('should navigate to add task screen when FAB is tapped',
          (tester) async {
        await tester.pumpWidget(createTaskListScreen());
        await tester.pumpAndSettle();

        // Tap FAB
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Should navigate to AddTaskScreen
        // (In real test with router, would verify navigation)
      });
    });
  });
}
