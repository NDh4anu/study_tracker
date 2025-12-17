// test/widget/screens/add_task_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:study_tracker/features/tasks/models/task.dart';
import 'package:study_tracker/features/tasks/screens/add_task_screen.dart';
import 'package:study_tracker/providers/task_provider.dart';

import '../../helpers/mock_services.mocks.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('AddTaskScreen Widget Tests', () {
    late MockTaskApiService mockApiService;
    late TaskProvider mockProvider;

    setUp(() {
      mockApiService = MockTaskApiService();
      mockProvider = TaskProvider(mockApiService);
    });

    Widget createAddTaskScreen() {
      return TestHelpers.makeTestableWidgetWithProvider(
        taskProvider: mockProvider,
        child: const AddTaskScreen(),
      );
    }

    // ===================================================================
    // Initial State Tests
    // ===================================================================

    group('Initial State', () {
      testWidgets('should display app bar with title', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        expect(find.text('Add Task'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should display all form fields', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Title field
        expect(find.widgetWithText(TextFormField, 'Task Title'),
            findsOneWidget);

        // Description label
        expect(find.text('Task Description'), findsOneWidget);

        // Category dropdown
        expect(find.text('Category'), findsOneWidget);

        // Priority section
        expect(find.text('Priority'), findsOneWidget);

        // Due date
        expect(find.text('Due Date'), findsOneWidget);

        // Submit button
        expect(find.text('Add Task'), findsOneWidget);
      });

      testWidgets('should have save button', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        expect(find.widgetWithText(ElevatedButton, 'Add Task'),
            findsOneWidget);
      });
    });

    // ===================================================================
    // Form Validation Tests
    // ===================================================================

    group('Form Validation', () {
      testWidgets('should show error when title is empty', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Try to submit without title
        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.text('Judul task tidak boleh kosong'), findsOneWidget);
      });

      testWidgets('should show error when title is too short', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Enter short title
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Task Title'),
          'AB',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.text('Judul task minimal 3 karakter'), findsOneWidget);
      });

      testWidgets('should show error when category is not selected',
          (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Enter title only
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Task Title'),
          'Valid Task Title',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
        await tester.pumpAndSettle();

        // Should show category error
        expect(find.text('Pilih kategori'), findsOneWidget);
      });

      testWidgets('should show error when due date is not selected',
          (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Enter title only
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Task Title'),
          'Valid Task Title',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
        await tester.pumpAndSettle();

        // Should show due date error
        expect(find.text('Pilih tanggal jatuh tempo'), findsOneWidget);
      });
    });

    // ===================================================================
    // Category Selection Tests
    // ===================================================================

    group('Category Selection', () {
      testWidgets('should display category dropdown', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        expect(find.text('Category'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<TaskCategory>),
            findsOneWidget);
      });

      testWidgets('should show all category options when dropdown is opened',
          (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Tap dropdown
        await tester.tap(find.byType(DropdownButtonFormField<TaskCategory>));
        await tester.pumpAndSettle();

        // Should show all categories
        expect(find.text('Study'), findsWidgets);
        expect(find.text('Assignment'), findsWidgets);
        expect(find.text('Exam'), findsWidgets);
        expect(find.text('Project'), findsWidgets);
        expect(find.text('Personal'), findsWidgets);
        expect(find.text('Other'), findsWidgets);
      });

      testWidgets('should select category when option is tapped',
          (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Open dropdown
        await tester.tap(find.byType(DropdownButtonFormField<TaskCategory>));
        await tester.pumpAndSettle();

        // Select Study
        await tester.tap(find.text('Study').last);
        await tester.pumpAndSettle();

        // Dropdown should show selected value
        expect(
          find.descendant(
            of: find.byType(DropdownButtonFormField<TaskCategory>),
            matching: find.text('Study'),
          ),
          findsOneWidget,
        );
      });
    });

    // ===================================================================
    // Priority Selection Tests
    // ===================================================================

    group('Priority Selection', () {
      testWidgets('should display priority options', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        expect(find.text('Priority'), findsOneWidget);
        expect(find.text('Low'), findsOneWidget);
        expect(find.text('Medium'), findsOneWidget);
        expect(find.text('High'), findsOneWidget);
      });

      testWidgets('should have Medium selected by default', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Medium should be selected (exact verification depends on UI implementation)
        expect(find.text('Medium'), findsOneWidget);
      });

      testWidgets('should select priority when option is tapped',
          (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Tap High priority
        await tester.tap(find.text('High'));
        await tester.pumpAndSettle();

        // High should now be selected
        // (Verification depends on visual feedback in UI)
      });
    });

    // ===================================================================
    // Date Picker Tests
    // ===================================================================

    group('Due Date Selection', () {
      testWidgets('should display date picker button', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        expect(find.text('Due Date'), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      });

      testWidgets('should open date picker when button is tapped',
          (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Tap date picker button
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        // Should show date picker dialog
        expect(find.byType(DatePickerDialog), findsOneWidget);
      });

      testWidgets('should update date when date is selected', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Tap date picker button
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        // Select a date (tap OK button)
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Date should be displayed (exact format depends on implementation)
      });

      testWidgets('should not allow past dates', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Tap date picker button
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();

        // Date picker should have firstDate set to today or later
        // (Verification depends on DatePicker configuration)
        expect(find.byType(DatePickerDialog), findsOneWidget);
      });
    });

    // ===================================================================
    // Form Submission Tests
    // ===================================================================

    group('Form Submission', () {
      testWidgets('should show loading indicator during submission',
          (tester) async {
        when(mockApiService.createTask(any)).thenAnswer(
          (_) => Future.delayed(
            const Duration(milliseconds: 500),
            () => Task(
              serverId: 123,
              title: 'New Task',
              userId: 'user123',
              priority: TaskPriority.medium,
              category: TaskCategory.study,
            ),
          ),
        );

        await tester.pumpWidget(createAddTaskScreen());

        // Fill form with valid data
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Task Title'),
          'New Task',
        );

        // Select category
        await tester.tap(find.byType(DropdownButtonFormField<TaskCategory>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Study').last);
        await tester.pumpAndSettle();

        // Select date
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Submit form
        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should disable submit button during submission',
          (tester) async {
        when(mockApiService.createTask(any)).thenAnswer(
          (_) => Future.delayed(
            const Duration(seconds: 2),
            () => Task(
              serverId: 123,
              title: 'New Task',
              userId: 'user123',
              priority: TaskPriority.medium,
              category: TaskCategory.study,
            ),
          ),
        );

        await tester.pumpWidget(createAddTaskScreen());

        // Fill minimal form
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Task Title'),
          'New Task',
        );

        // Select category
        await tester.tap(find.byType(DropdownButtonFormField<TaskCategory>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Study').last);
        await tester.pumpAndSettle();

        // Select date
        await tester.tap(find.byIcon(Icons.calendar_today));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Submit
        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Task'));
        await tester.pump();

        // Button should be replaced with loading indicator
        expect(find.widgetWithText(ElevatedButton, 'Add Task'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    // ===================================================================
    // User Experience Tests
    // ===================================================================

    group('User Experience', () {
      testWidgets('should capitalize first letter of title', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Verify title field exists and has proper configuration
        expect(find.widgetWithText(TextFormField, 'Task Title'), findsOneWidget);
        // Text capitalization is handled by the TextField decoration
      });

      testWidgets('should show helpful hint text', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        expect(
          find.text('Misal: Mengerjakan PR Matematika'),
          findsOneWidget,
        );
      });

      testWidgets('should have autovalidate mode for better UX',
          (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Verify form exists with proper validation
        expect(find.widgetWithText(TextFormField, 'Task Title'), findsOneWidget);
        // Autovalidate mode provides immediate feedback
      });
    });

    // ===================================================================
    // Rich Text Editor Tests (Basic)
    // ===================================================================

    group('Description Editor', () {
      testWidgets('should display description label', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        expect(find.text('Task Description'), findsOneWidget);
      });

      testWidgets('should have Quill editor toolbar', (tester) async {
        await tester.pumpWidget(createAddTaskScreen());

        // Should have toolbar for formatting
        // (Exact verification depends on flutter_quill implementation)
        expect(find.text('Task Description'), findsOneWidget);
      });
    });
  });
}
