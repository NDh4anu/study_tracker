// test/unit/services/task_local_db_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:study_tracker/features/tasks/models/task.dart';
import 'package:study_tracker/local/task_local_db.dart';

import '../../helpers/mock_data.dart';
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskLocalDb Tests', () {
    late TaskLocalDb localDb;

    setUpAll(() {
      // Initialize sqflite_ffi for testing
      TestHelpers.initializeSqfliteFfi();
    });

    setUp(() async {
      // Get fresh instance for each test
      localDb = TaskLocalDb();
      // Ensure database is initialized
      await localDb.database;
    });

    tearDown(() async {
      // Clean up after each test
      try {
        await localDb.clearAll();
      } catch (e) {
        // Ignore errors during cleanup
      }
    });

    // ===================================================================
    // Insert Tests
    // ===================================================================

    group('Insert Operations', () {
      test('insertTask should save task and return auto-generated localId', () async {
        final task = Task(
          title: 'New Task',
          description: 'Test description',
          userId: 'user123',
          priority: TaskPriority.high,
          category: TaskCategory.study,
          dueDate: DateTime(2024, 12, 25),
        );

        final localId = await localDb.insertTask(task);

        expect(localId, greaterThan(0));
        expect(localId, isA<int>());
      });

      test('insertTask should auto-populate createdAt if null', () async {
        final task = Task(
          title: 'Task without createdAt',
          description: 'Description',
          userId: 'user123',
          priority: TaskPriority.medium,
          category: TaskCategory.personal,
          createdAt: null,
        );

        final localId = await localDb.insertTask(task);
        final retrievedTasks = await localDb.getAllTasks();
        final savedTask = retrievedTasks.firstWhere((t) => t.localId == localId);

        expect(savedTask.createdAt, isNotNull);
      });

      test('insertTask should preserve all task fields', () async {
        final task = Task(
          serverId: 999,
          title: 'Complete Task',
          description: 'Full description',
          completed: true,
          userId: 'user456',
          createdAt: DateTime(2024, 12, 1, 10, 30),
          priority: TaskPriority.low,
          category: TaskCategory.project,
          dueDate: DateTime(2024, 12, 31),
          isSynced: true,
        );

        final localId = await localDb.insertTask(task);
        final retrievedTasks = await localDb.getAllTasks();
        final savedTask = retrievedTasks.firstWhere((t) => t.localId == localId);

        expect(savedTask.serverId, 999);
        expect(savedTask.title, 'Complete Task');
        expect(savedTask.description, 'Full description');
        expect(savedTask.completed, true);
        expect(savedTask.userId, 'user456');
        expect(savedTask.priority, TaskPriority.low);
        expect(savedTask.category, TaskCategory.project);
        expect(savedTask.isSynced, true);
        expect(savedTask.dueDate, isNotNull);
      });

      test('insertTask should handle multiple inserts with auto-increment', () async {
        final task1 = Task(title: 'Task 1');
        final task2 = Task(title: 'Task 2');
        final task3 = Task(title: 'Task 3');

        final id1 = await localDb.insertTask(task1);
        final id2 = await localDb.insertTask(task2);
        final id3 = await localDb.insertTask(task3);

        expect(id2, greaterThan(id1));
        expect(id3, greaterThan(id2));
      });
    });

    // ===================================================================
    // Retrieve Tests
    // ===================================================================

    group('Retrieve Operations', () {
      test('getAllTasks should return empty list when database is empty', () async {
        final tasks = await localDb.getAllTasks();
        expect(tasks, isEmpty);
      });

      test('getAllTasks should return all tasks ordered by created_at DESC', () async {
        final task1 = Task(
          title: 'Oldest',
          createdAt: DateTime(2024, 12, 1),
        );
        final task2 = Task(
          title: 'Middle',
          createdAt: DateTime(2024, 12, 10),
        );
        final task3 = Task(
          title: 'Newest',
          createdAt: DateTime(2024, 12, 15),
        );

        await localDb.insertTask(task1);
        await localDb.insertTask(task2);
        await localDb.insertTask(task3);

        final tasks = await localDb.getAllTasks();

        expect(tasks.length, 3);
        expect(tasks[0].title, 'Newest'); // Most recent first
        expect(tasks[1].title, 'Middle');
        expect(tasks[2].title, 'Oldest');
      });

      test('getUnsyncedTasks should return only unsynced tasks', () async {
        // Clear database first to avoid shared state
        await localDb.clearAll();
        
        final syncedTask = Task(
          title: 'Synced',
          description: 'desc',
          userId: 'user123',
          priority: TaskPriority.medium,
          category: TaskCategory.personal,
          isSynced: true,
          createdAt: DateTime(2024, 12, 1),
        );
        final unsyncedTask1 = Task(
          title: 'Unsynced 1',
          description: 'desc',
          userId: 'user123',
          priority: TaskPriority.medium,
          category: TaskCategory.personal,
          isSynced: false,
          createdAt: DateTime(2024, 12, 5),
        );
        final unsyncedTask2 = Task(
          title: 'Unsynced 2',
          description: 'desc',
          userId: 'user123',
          priority: TaskPriority.medium,
          category: TaskCategory.personal,
          isSynced: false,
          createdAt: DateTime(2024, 12, 3),
        );

        await localDb.insertTask(syncedTask);
        await localDb.insertTask(unsyncedTask1);
        await localDb.insertTask(unsyncedTask2);

        final unsyncedTasks = await localDb.getUnsyncedTasks();

        expect(unsyncedTasks.length, 2);
        expect(unsyncedTasks.every((t) => !t.isSynced), true);
        // Should be ordered by created_at ASC for syncing
        expect(unsyncedTasks[0].title, 'Unsynced 2'); // Oldest first
        expect(unsyncedTasks[1].title, 'Unsynced 1');
      });

      test('getUnsyncedTasks should return empty list if all synced', () async {
        final task1 = Task(title: 'Synced 1', isSynced: true);
        final task2 = Task(title: 'Synced 2', isSynced: true);

        await localDb.insertTask(task1);
        await localDb.insertTask(task2);

        final unsyncedTasks = await localDb.getUnsyncedTasks();

        expect(unsyncedTasks, isEmpty);
      });
    });

    // ===================================================================
    // Update Tests
    // ===================================================================

    group('Update Operations', () {
      test('updateTask should modify existing task', () async {
        final task = Task(
          title: 'Original Title',
          completed: false,
          priority: TaskPriority.medium,
        );

        final localId = await localDb.insertTask(task);
        final taskWithId = task.copyWith(localId: localId);

        final updatedTask = taskWithId.copyWith(
          title: 'Updated Title',
          completed: true,
          priority: TaskPriority.high,
        );

        final rowsAffected = await localDb.updateTask(updatedTask);

        expect(rowsAffected, 1);

        final retrievedTasks = await localDb.getAllTasks();
        final savedTask = retrievedTasks.firstWhere((t) => t.localId == localId);

        expect(savedTask.title, 'Updated Title');
        expect(savedTask.completed, true);
        expect(savedTask.priority, TaskPriority.high);
      });

      test('updateTask should return 0 if localId is null', () async {
        final task = Task(
          title: 'No Local ID',
          localId: null,
        );

        final rowsAffected = await localDb.updateTask(task);

        expect(rowsAffected, 0);
      });

      test('updateTask should update isSynced flag', () async {
        final task = Task(
          title: 'Task to sync',
          isSynced: false,
        );

        final localId = await localDb.insertTask(task);
        final taskWithId = task.copyWith(localId: localId);

        final syncedTask = taskWithId.copyWith(
          serverId: 999,
          isSynced: true,
        );

        await localDb.updateTask(syncedTask);

        final retrievedTasks = await localDb.getAllTasks();
        final savedTask = retrievedTasks.firstWhere((t) => t.localId == localId);

        expect(savedTask.isSynced, true);
        expect(savedTask.serverId, 999);
      });

      test('updateTask should not affect other tasks', () async {
        final task1 = Task(title: 'Task 1');
        final task2 = Task(title: 'Task 2');

        final id1 = await localDb.insertTask(task1);
        final id2 = await localDb.insertTask(task2);

        final updatedTask1 = task1.copyWith(
          localId: id1,
          title: 'Updated Task 1',
        );

        await localDb.updateTask(updatedTask1);

        final allTasks = await localDb.getAllTasks();
        final retrievedTask2 = allTasks.firstWhere((t) => t.localId == id2);

        expect(retrievedTask2.title, 'Task 2'); // Should be unchanged
      });
    });

    // ===================================================================
    // Delete Tests
    // ===================================================================

    group('Delete Operations', () {
      test('deleteTask should remove task from database', () async {
        final task = Task(title: 'Task to delete');
        final localId = await localDb.insertTask(task);

        final rowsDeleted = await localDb.deleteTask(localId);

        expect(rowsDeleted, 1);

        final remainingTasks = await localDb.getAllTasks();
        expect(remainingTasks.where((t) => t.localId == localId), isEmpty);
      });

      test('deleteTask should return 0 if task does not exist', () async {
        final rowsDeleted = await localDb.deleteTask(99999);
        expect(rowsDeleted, 0);
      });

      test('deleteTask should not affect other tasks', () async {
        final task1 = Task(title: 'Keep this');
        final task2 = Task(title: 'Delete this');
        final task3 = Task(title: 'Keep this too');

        final id1 = await localDb.insertTask(task1);
        final id2 = await localDb.insertTask(task2);
        final id3 = await localDb.insertTask(task3);

        await localDb.deleteTask(id2);

        final remainingTasks = await localDb.getAllTasks();

        expect(remainingTasks.length, 2);
        expect(remainingTasks.any((t) => t.localId == id1), true);
        expect(remainingTasks.any((t) => t.localId == id2), false);
        expect(remainingTasks.any((t) => t.localId == id3), true);
      });
    });

    // ===================================================================
    // Batch Operations Tests
    // ===================================================================

    group('Batch Operations', () {
      test('replaceAllTasks should clear and insert new tasks', () async {
        // Insert some initial tasks
        await localDb.insertTask(Task(title: 'Old Task 1'));
        await localDb.insertTask(Task(title: 'Old Task 2'));

        final initialTasks = await localDb.getAllTasks();
        expect(initialTasks.length, 2);

        // Replace with new tasks from server
        final serverTasks = [
          MockData.completedTask,
          MockData.pendingTask,
          MockData.overdueTask,
        ];

        await localDb.replaceAllTasks(serverTasks);

        final newTasks = await localDb.getAllTasks();

        expect(newTasks.length, 3);
        expect(newTasks.any((t) => t.title == 'Old Task 1'), false);
        expect(newTasks.any((t) => t.title == 'Old Task 2'), false);
        expect(newTasks.every((t) => t.isSynced), true); // All should be marked as synced
      });

      test('replaceAllTasks should handle empty list', () async {
        await localDb.insertTask(Task(title: 'Task 1'));
        await localDb.insertTask(Task(title: 'Task 2'));

        await localDb.replaceAllTasks([]);

        final tasks = await localDb.getAllTasks();
        expect(tasks, isEmpty);
      });

      test('replaceAllTasks should set localId to null for new inserts', () async {
        final tasksWithLocalIds = [
          MockData.completedTask.copyWith(localId: 999),
          MockData.pendingTask.copyWith(localId: 888),
        ];

        await localDb.replaceAllTasks(tasksWithLocalIds);

        final tasks = await localDb.getAllTasks();

        // localId should be regenerated by database auto-increment
        expect(tasks[0].localId, isNot(999));
        expect(tasks[1].localId, isNot(888));
        expect(tasks.every((t) => t.localId != null), true);
      });

      test('clearAll should remove all tasks', () async {
        await localDb.insertTask(Task(title: 'Task 1'));
        await localDb.insertTask(Task(title: 'Task 2'));
        await localDb.insertTask(Task(title: 'Task 3'));

        await localDb.clearAll();

        final tasks = await localDb.getAllTasks();
        expect(tasks, isEmpty);
      });
    });

    // ===================================================================
    // Data Integrity Tests
    // ===================================================================

    group('Data Integrity', () {
      test('should handle special characters in text fields', () async {
        final task = Task(
          title: 'Task with émojis 🎉 and spëcial çhars',
          description: 'Testing: <html>, "quotes", \'apostrophes\'',
        );

        final localId = await localDb.insertTask(task);
        final retrievedTasks = await localDb.getAllTasks();
        final savedTask = retrievedTasks.firstWhere((t) => t.localId == localId);

        expect(savedTask.title, contains('🎉'));
        expect(savedTask.description, contains('"quotes"'));
      });

      test('should handle very long strings', () async {
        final longString = 'A' * 10000;
        final task = Task(
          title: longString,
          description: longString,
        );

        final localId = await localDb.insertTask(task);
        final retrievedTasks = await localDb.getAllTasks();
        final savedTask = retrievedTasks.firstWhere((t) => t.localId == localId);

        expect(savedTask.title.length, 10000);
        expect(savedTask.description.length, 10000);
      });

      test('should handle null serverId correctly', () async {
        final task = Task(
          title: 'No server ID',
          serverId: null,
        );

        final localId = await localDb.insertTask(task);
        final retrievedTasks = await localDb.getAllTasks();
        final savedTask = retrievedTasks.firstWhere((t) => t.localId == localId);

        expect(savedTask.serverId, isNull);
      });

      test('should preserve date precision', () async {
        final specificDate = DateTime(2024, 12, 15, 10, 30, 45);
        final task = Task(
          title: 'Precise Date',
          createdAt: specificDate,
          dueDate: specificDate,
        );

        final localId = await localDb.insertTask(task);
        final retrievedTasks = await localDb.getAllTasks();
        final savedTask = retrievedTasks.firstWhere((t) => t.localId == localId);

        // Note: SQLite stores as ISO8601 string, may lose milliseconds
        expect(savedTask.createdAt?.year, specificDate.year);
        expect(savedTask.createdAt?.month, specificDate.month);
        expect(savedTask.createdAt?.day, specificDate.day);
        expect(savedTask.createdAt?.hour, specificDate.hour);
        expect(savedTask.createdAt?.minute, specificDate.minute);
      });
    });

    // ===================================================================
    // Concurrent Operations Tests
    // ===================================================================

    group('Concurrent Operations', () {
      test('should handle rapid sequential inserts', () async {
        final tasks = List.generate(
          100,
          (i) => Task(title: 'Task $i'),
        );

        final ids = <int>[];
        for (final task in tasks) {
          final id = await localDb.insertTask(task);
          ids.add(id);
        }

        expect(ids.length, 100);
        expect(ids.toSet().length, 100); // All IDs should be unique

        final allTasks = await localDb.getAllTasks();
        expect(allTasks.length, 100);
      });

      test('should handle interleaved operations', () async {
        final id1 = await localDb.insertTask(Task(title: 'Task 1'));
        final id2 = await localDb.insertTask(Task(title: 'Task 2'));

        await localDb.updateTask(Task(
          localId: id1,
          title: 'Updated Task 1',
        ));

        final id3 = await localDb.insertTask(Task(title: 'Task 3'));

        await localDb.deleteTask(id2);

        final tasks = await localDb.getAllTasks();

        expect(tasks.length, 2);
        expect(tasks.any((t) => t.title == 'Updated Task 1'), true);
        expect(tasks.any((t) => t.title == 'Task 3'), true);
      });
    });
  });
}
