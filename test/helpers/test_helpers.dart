// test/helpers/test_helpers.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_tracker/providers/task_provider.dart';

/// Helper functions untuk testing
class TestHelpers {
  /// Initialize sqflite_ffi untuk testing database
  static void initializeSqfliteFfi() {
    // Initialize ffi implementation
    sqfliteFfiInit();
    // Set global factory untuk testing
    databaseFactory = databaseFactoryFfi;
  }

  /// Wrap widget dengan MaterialApp untuk testing
  static Widget makeTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  /// Wrap widget dengan MaterialApp dan Provider untuk testing
  static Widget makeTestableWidgetWithProvider({
    required Widget child,
    required TaskProvider taskProvider,
  }) {
    return ChangeNotifierProvider<TaskProvider>.value(
      value: taskProvider,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// Pump widget dan tunggu semua animations selesai
  static Future<void> pumpAndSettleWidget(
    WidgetTester tester,
    Widget widget, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle(timeout);
  }

  /// Find text yang mungkin overflow (dalam Flexible, Expanded, etc.)
  static Finder findTextContaining(String text) {
    return find.byWidgetPredicate(
      (widget) => widget is Text && widget.data?.contains(text) == true,
    );
  }

  /// Find widget by key dengan type checking
  static Finder findByKeyAndType<T extends Widget>(String key) {
    return find.byWidgetPredicate(
      (widget) => widget.key == Key(key) && widget is T,
    );
  }

  /// Simulate delay (untuk async operations)
  static Future<void> delay([Duration duration = const Duration(milliseconds: 100)]) {
    return Future.delayed(duration);
  }

  /// Verify widget exists dan visible
  static void verifyWidgetVisible(WidgetTester tester, Finder finder) {
    expect(finder, findsOneWidget);
    expect(tester.widget(finder), isNotNull);
  }

  /// Tap widget dan tunggu animations
  static Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enter text ke TextField dan tunggu
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Scroll until widget visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder item,
    Finder scrollable, {
    double delta = 100,
  }) async {
    await tester.scrollUntilVisible(
      item,
      delta,
      scrollable: scrollable,
    );
  }

  /// Verify SnackBar dengan message tertentu
  static void verifySnackBar(String message) {
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(message), findsOneWidget);
  }

  /// Verify CircularProgressIndicator ada
  static void verifyLoadingIndicator() {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// Verify AlertDialog ada dengan title tertentu
  static void verifyAlertDialog(String title) {
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(title), findsOneWidget);
  }

  /// Get in-memory database path untuk testing
  static String getTestDatabasePath() {
    return inMemoryDatabasePath;
  }

  /// Create test database dengan initial schema
  static Future<Database> createTestDatabase() async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE tasks_local (
              local_id INTEGER PRIMARY KEY AUTOINCREMENT,
              server_id INTEGER,
              title TEXT NOT NULL,
              description TEXT,
              completed INTEGER NOT NULL DEFAULT 0,
              user_id TEXT NOT NULL,
              created_at TEXT,
              priority TEXT DEFAULT 'medium',
              category TEXT DEFAULT 'personal',
              due_date TEXT,
              is_synced INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      ),
    );
    return db;
  }

  /// Clean up test database
  static Future<void> closeTestDatabase(Database db) async {
    await db.close();
  }
}
