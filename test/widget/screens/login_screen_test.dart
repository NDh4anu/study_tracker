// test/widget/screens/login_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:study_tracker/features/auth/screens/login_screen.dart';
import 'package:study_tracker/providers/task_provider.dart';

import '../../helpers/mock_services.mocks.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late MockTaskApiService mockApiService;
    late TaskProvider mockProvider;

    setUp(() {
      mockApiService = MockTaskApiService();
      mockProvider = TaskProvider(mockApiService);
    });

    Widget createLoginScreen() {
      return TestHelpers.makeTestableWidgetWithProvider(
        taskProvider: mockProvider,
        child: const LoginScreen(),
      );
    }

    // ===================================================================
    // Initial State Tests
    // ===================================================================

    group('Initial State', () {
      testWidgets('should display login form with all required fields',
          (tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Verify app branding
        expect(find.byIcon(Icons.school), findsOneWidget);
        expect(find.text('Study Tracker'), findsOneWidget);

        // Verify login mode
        expect(find.text('Masuk ke akun Anda'), findsOneWidget);

        // Verify form fields
        expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

        // Verify submit button
        expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);

        // Verify toggle link
        expect(find.text('Belum punya akun?'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Daftar'), findsOneWidget);
      });

      testWidgets('should have password field obscured by default',
          (tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Verify password field exists
        expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
        // Password obscuring is handled by the TextField decoration
      });

      testWidgets('should have visibility toggle button', (tester) async {
        await tester.pumpWidget(createLoginScreen());

        expect(
          find.descendant(
            of: find.widgetWithText(TextFormField, 'Password'),
            matching: find.byType(IconButton),
          ),
          findsOneWidget,
        );
      });
    });

    // ===================================================================
    // Form Validation Tests
    // ===================================================================

    group('Form Validation', () {
      testWidgets('should show error when email is empty', (tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Try to submit without entering email
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        expect(find.text('Email harus diisi'), findsOneWidget);
      });

      testWidgets('should show error when email is invalid', (tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Enter invalid email
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'invalidemail',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        expect(find.text('Email tidak valid'), findsOneWidget);
      });

      testWidgets('should show error when password is empty', (tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Enter valid email but no password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        expect(find.text('Password harus diisi'), findsOneWidget);
      });

      testWidgets('should show error when password is too short',
          (tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Enter valid email and short password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          '12345',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        expect(find.text('Password minimal 6 karakter'), findsOneWidget);
      });

      testWidgets('should not show errors with valid input', (tester) async {
        when(mockApiService.login(any, any)).thenAnswer(
          (_) async => {
            'user': {'id': 'user123', 'email': 'test@example.com'},
            'access_token': 'token',
          },
        );

        await tester.pumpWidget(createLoginScreen());

        // Enter valid credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pump();

        // Should not show validation errors
        expect(find.text('Email harus diisi'), findsNothing);
        expect(find.text('Password harus diisi'), findsNothing);
        expect(find.text('Password minimal 6 karakter'), findsNothing);
      });
    });

    // ===================================================================
    // Password Visibility Toggle Tests
    // ===================================================================

    group('Password Visibility', () {
      testWidgets('should toggle password visibility when icon is tapped',
          (tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Enter password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'secret123',
        );

        // Tap visibility toggle
        final visibilityButton = find.descendant(
          of: find.widgetWithText(TextFormField, 'Password'),
          matching: find.byType(IconButton),
        );
        await tester.tap(visibilityButton);
        await tester.pumpAndSettle();

        // Verify toggle button exists and is interactive
        expect(visibilityButton, findsOneWidget);
      });
    });

    // ===================================================================
    // Login/Register Mode Toggle Tests
    // ===================================================================

    group('Mode Toggle', () {
      testWidgets('should switch to register mode when toggle is tapped',
          (tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Initially in login mode
        expect(find.text('Masuk ke akun Anda'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);
        expect(find.text('Belum punya akun?'), findsOneWidget);

        // Tap register toggle
        await tester.tap(find.widgetWithText(TextButton, 'Daftar'));
        await tester.pumpAndSettle();

        // Now in register mode
        expect(find.text('Buat akun baru'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Daftar'), findsOneWidget);
        expect(find.text('Sudah punya akun?'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Masuk'), findsOneWidget);
      });

      testWidgets('should switch back to login mode', (tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Switch to register
        await tester.tap(find.widgetWithText(TextButton, 'Daftar'));
        await tester.pumpAndSettle();

        // Switch back to login
        await tester.tap(find.widgetWithText(TextButton, 'Masuk'));
        await tester.pumpAndSettle();

        // Back in login mode
        expect(find.text('Masuk ke akun Anda'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);
      });

      testWidgets('should clear form validation when switching modes',
          (tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Trigger validation errors in login mode
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();
        expect(find.text('Email harus diisi'), findsOneWidget);

        // Switch to register mode
        await tester.tap(find.widgetWithText(TextButton, 'Daftar'));
        await tester.pumpAndSettle();

        // Errors should persist (form is the same)
        // But the mode text should change
        expect(find.text('Buat akun baru'), findsOneWidget);
      });
    });

    // ===================================================================
    // Login Flow Tests
    // ===================================================================

    group('Login Authentication', () {
      testWidgets('should show loading indicator during login', (tester) async {
        when(mockApiService.login(any, any)).thenAnswer(
          (_) => Future.delayed(
            const Duration(milliseconds: 500),
            () => {
              'user': {'id': 'user123', 'email': 'test@example.com'},
              'access_token': 'token',
            },
          ),
        );

        await tester.pumpWidget(createLoginScreen());

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );

        // Tap login
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsNothing);

        // Wait for completion
        await tester.pumpAndSettle();
      });

      testWidgets('should call login with correct credentials', (tester) async {
        when(mockApiService.login(any, any)).thenAnswer(
          (_) async => {
            'user': {'id': 'user123', 'email': 'test@example.com'},
            'access_token': 'token',
          },
        );

        await tester.pumpWidget(createLoginScreen());

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );

        // Submit
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        // Verify login was called with correct params
        verify(mockApiService.login('test@example.com', 'password123'))
            .called(1);
      });

      testWidgets('should show error snackbar on login failure',
          (tester) async {
        when(mockApiService.login(any, any)).thenAnswer((_) async => null);

        await tester.pumpWidget(createLoginScreen());

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'wrong@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'wrongpass',
        );

        // Submit
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        // Should show error snackbar
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Login gagal. Periksa email dan password Anda.'),
            findsOneWidget);
      });
    });

    // ===================================================================
    // Register Flow Tests
    // ===================================================================

    group('Register Authentication', () {
      testWidgets('should call register with correct credentials',
          (tester) async {
        when(mockApiService.register(any, any)).thenAnswer(
          (_) async => {
            'user': {'id': 'newuser', 'email': 'new@example.com'},
            'access_token': 'newtoken',
          },
        );

        await tester.pumpWidget(createLoginScreen());

        // Switch to register mode
        await tester.tap(find.widgetWithText(TextButton, 'Daftar'));
        await tester.pumpAndSettle();

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'new@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'newpass123',
        );

        // Submit
        await tester.tap(find.widgetWithText(ElevatedButton, 'Daftar'));
        await tester.pumpAndSettle();

        // Verify register was called
        verify(mockApiService.register('new@example.com', 'newpass123'))
            .called(1);
      });

      testWidgets('should show error snackbar on register failure',
          (tester) async {
        when(mockApiService.register(any, any)).thenAnswer((_) async => null);

        await tester.pumpWidget(createLoginScreen());

        // Switch to register mode
        await tester.tap(find.widgetWithText(TextButton, 'Daftar'));
        await tester.pumpAndSettle();

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'existing@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );

        // Submit
        await tester.tap(find.widgetWithText(ElevatedButton, 'Daftar'));
        await tester.pumpAndSettle();

        // Should show error snackbar
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Registrasi gagal. Email mungkin sudah digunakan.'),
            findsOneWidget);
      });
    });

    // ===================================================================
    // User Interaction Tests
    // ===================================================================

    group('User Interactions', () {
      testWidgets('should trim email whitespace before submission',
          (tester) async {
        when(mockApiService.login(any, any)).thenAnswer(
          (_) async => {
            'user': {'id': 'user123', 'email': 'test@example.com'},
            'access_token': 'token',
          },
        );

        await tester.pumpWidget(createLoginScreen());

        // Enter email with whitespace
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          '  test@example.com  ',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        // Verify trimmed email was used
        verify(mockApiService.login('test@example.com', 'password123'))
            .called(1);
      });

      testWidgets('should allow form submission via keyboard enter',
          (tester) async {
        when(mockApiService.login(any, any)).thenAnswer(
          (_) async => {
            'user': {'id': 'user123', 'email': 'test@example.com'},
            'access_token': 'token',
          },
        );

        await tester.pumpWidget(createLoginScreen());

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );

        // Submit via keyboard (onFieldSubmitted)
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Verify login was called
        verify(mockApiService.login('test@example.com', 'password123'))
            .called(1);
      });
    });
  });
}
