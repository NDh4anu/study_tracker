// test/integration/auth_flow_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:study_tracker/features/auth/screens/login_screen.dart';
import 'package:study_tracker/providers/task_provider.dart';
import 'package:study_tracker/api/task_api.dart';

/// Integration tests for complete authentication and UI flows
/// 
/// These tests verify end-to-end UI scenarios focusing on the
/// authentication screen interactions without API calls.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {

    /// Helper to wrap widget with provider
    Widget makeTestableWidget(Widget child) {
      return ChangeNotifierProvider<TaskProvider>(
        create: (_) => TaskProvider(TaskApiService()),
        child: MaterialApp(
          home: child,
        ),
      );
    }

    // ===================================================================
    // Complete User Journey Tests
    // ===================================================================

    testWidgets('Complete authentication UI flow without API calls',
        (tester) async {
      // This test validates the complete UI flow without actual API calls
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Step 1: Verify initial login screen state
      expect(find.text('Study Tracker'), findsOneWidget);
      expect(find.text('Masuk ke akun Anda'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);

      // Step 2: Validate form shows errors on empty submission
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pump();

      expect(find.text('Email harus diisi'), findsOneWidget);
      expect(find.text('Password harus diisi'), findsOneWidget);

      // Step 3: Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'notanemail',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pump();

      expect(find.text('Email tidak valid'), findsOneWidget);

      // Step 4: Enter valid email but short password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pump();

      expect(find.text('Password minimal 6 karakter'), findsOneWidget);

      // Step 5: Switch to register mode
      await tester.tap(find.widgetWithText(TextButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Buat akun baru'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Daftar'), findsOneWidget);

      // Step 6: Switch back to login mode
      await tester.tap(find.widgetWithText(TextButton, 'Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Masuk ke akun Anda'), findsOneWidget);
    });

    testWidgets('Password visibility toggle', (tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Enter password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'secret123',
      );

      // Find and tap visibility toggle
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      final toggleButton = find.descendant(
        of: passwordField,
        matching: find.byType(IconButton),
      );

      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Password visibility should be toggled
      // (Visual verification would be needed in real scenario)
    });

    testWidgets('Multiple validation errors shown simultaneously',
        (tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Try to submit empty form
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pump();

      // Should show both errors
      expect(find.text('Email harus diisi'), findsOneWidget);
      expect(find.text('Password harus diisi'), findsOneWidget);
    });

    testWidgets('Validation errors clear on valid input', (tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Trigger validation errors
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pump();

      expect(find.text('Email harus diisi'), findsOneWidget);

      // Enter valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      
      // Enter valid password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      
      // Trigger revalidation by tapping submit again
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pumpAndSettle();

      // Validation errors should be gone (will show API error instead, but no field errors)
      expect(find.text('Email harus diisi'), findsNothing);
      expect(find.text('Password harus diisi'), findsNothing);
    });
  });
}
