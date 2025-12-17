// test/unit/models/task_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:study_tracker/features/tasks/models/task.dart';

import '../../helpers/mock_data.dart';

void main() {
  group('Task Model Tests', () {
    // ===================================================================
    // JSON Serialization Tests (toJson / fromJson)
    // ===================================================================

    group('JSON Serialization', () {
      test('toJson should convert Task to JSON Map correctly', () {
        final task = Task(
          serverId: 101,
          title: 'Test Task',
          description: 'Test Description',
          completed: false,
          userId: 'user123',
          priority: TaskPriority.high,
          category: TaskCategory.study,
          dueDate: DateTime(2024, 12, 25),
        );

        final json = task.toJson();

        expect(json['title'], 'Test Task');
        expect(json['description'], 'Test Description');
        expect(json['completed'], false);
        expect(json['user_id'], 'user123');
        expect(json['priority'], 'high');
        expect(json['category'], 'study');
        expect(json['due_date'], '2024-12-25T00:00:00.000');
        expect(json['id'], 101); // serverId should be included in JSON
      });

      test('toJson should not include serverId if null', () {
        final task = Task(
          title: 'Local Task',
          description: 'No server ID yet',
          completed: false,
          userId: 'user123',
        );

        final json = task.toJson();

        expect(json.containsKey('id'), false);
        expect(json['title'], 'Local Task');
      });

      test('fromJson should create Task from valid JSON', () {
        final json = MockData.taskJsonFromServer;
        final task = Task.fromJson(json);

        expect(task.serverId, 101);
        expect(task.title, 'Task from API');
        expect(task.description, 'This came from the server');
        expect(task.completed, false);
        expect(task.userId, 'user123');
        expect(task.priority, TaskPriority.high);
        expect(task.category, TaskCategory.study);
        expect(task.dueDate, isNotNull);
        expect(task.createdAt, isNotNull);
      });

      test('fromJson should handle null/missing fields gracefully', () {
        final json = {
          'id': 202,
          'title': 'Minimal Task',
          // Missing: description, user_id, priority, category, due_date, created_at
        };

        final task = Task.fromJson(json);

        expect(task.serverId, 202);
        expect(task.title, 'Minimal Task');
        expect(task.description, ''); // Should default to empty string
        expect(task.userId, ''); // Should default to empty string
        expect(task.completed, false); // Should default to false
        expect(task.priority, TaskPriority.medium); // Default priority
        expect(task.category, TaskCategory.personal); // Default category
        expect(task.dueDate, isNull);
        expect(task.createdAt, isNull);
      });

      test('fromJson should handle invalid date strings', () {
        final json = {
          'id': 303,
          'title': 'Task with bad dates',
          'due_date': 'not-a-date',
          'created_at': 'invalid-timestamp',
        };

        final task = Task.fromJson(json);

        expect(task.serverId, 303);
        expect(task.dueDate, isNull); // Should gracefully handle invalid date
        expect(task.createdAt, isNull);
      });

      test('fromJson should parse priority enum correctly', () {
        final highPriorityJson = {'title': 'High', 'priority': 'high'};
        final mediumPriorityJson = {'title': 'Medium', 'priority': 'medium'};
        final lowPriorityJson = {'title': 'Low', 'priority': 'low'};

        expect(Task.fromJson(highPriorityJson).priority, TaskPriority.high);
        expect(Task.fromJson(mediumPriorityJson).priority, TaskPriority.medium);
        expect(Task.fromJson(lowPriorityJson).priority, TaskPriority.low);
      });

      test('fromJson should parse category enum correctly', () {
        final studyJson = {'title': 'Study', 'category': 'study'};
        final assignmentJson = {'title': 'Assignment', 'category': 'assignment'};
        final projectJson = {'title': 'Project', 'category': 'project'};
        final personalJson = {'title': 'Personal', 'category': 'personal'};

        expect(Task.fromJson(studyJson).category, TaskCategory.study);
        expect(Task.fromJson(assignmentJson).category, TaskCategory.assignment);
        expect(Task.fromJson(projectJson).category, TaskCategory.project);
        expect(Task.fromJson(personalJson).category, TaskCategory.personal);
      });

      test('fromJson should default to medium/personal for invalid enum values', () {
        final invalidJson = {
          'title': 'Invalid Enums',
          'priority': 'ultra-high', // Invalid
          'category': 'work', // Invalid
        };

        final task = Task.fromJson(invalidJson);

        expect(task.priority, TaskPriority.medium);
        expect(task.category, TaskCategory.personal);
      });
    });

    // ===================================================================
    // SQLite Map Conversion Tests (toMap / fromMap)
    // ===================================================================

    group('SQLite Map Conversion', () {
      test('toMap should convert Task to SQLite Map correctly', () {
        final task = Task(
          localId: 5,
          serverId: 105,
          title: 'DB Task',
          description: 'In database',
          completed: true,
          userId: 'user456',
          priority: TaskPriority.low,
          category: TaskCategory.project,
          dueDate: DateTime(2024, 12, 31),
          createdAt: DateTime(2024, 12, 15),
          isSynced: true,
        );

        final map = task.toMap();

        expect(map['local_id'], 5);
        expect(map['server_id'], 105);
        expect(map['title'], 'DB Task');
        expect(map['description'], 'In database');
        expect(map['completed'], 1); // Boolean stored as integer
        expect(map['user_id'], 'user456');
        expect(map['priority'], 'low');
        expect(map['category'], 'project');
        expect(map['due_date'], isNotNull);
        expect(map['created_at'], isNotNull);
        expect(map['is_synced'], 1); // Boolean stored as integer
      });

      test('toMap should handle null values correctly', () {
        final task = Task(
          title: 'Minimal DB Task',
          // All optional fields null/default
        );

        final map = task.toMap();

        expect(map['local_id'], isNull);
        expect(map['server_id'], isNull);
        expect(map['title'], 'Minimal DB Task');
        expect(map['completed'], 0); // false -> 0
        expect(map['is_synced'], 0); // false -> 0
        expect(map['due_date'], isNull);
        expect(map['created_at'], isNull);
      });

      test('fromMap should create Task from SQLite Map', () {
        final map = MockData.taskMapFromDb;
        final task = Task.fromMap(map);

        expect(task.localId, 1);
        expect(task.serverId, 101);
        expect(task.title, 'Task from DB');
        expect(task.description, 'This came from SQLite');
        expect(task.completed, false); // 0 -> false
        expect(task.userId, 'user123');
        expect(task.priority, TaskPriority.medium);
        expect(task.category, TaskCategory.personal);
        expect(task.isSynced, true); // 1 -> true
      });

      test('fromMap should convert integer to boolean for completed', () {
        final completedMap = {
          'local_id': 1,
          'title': 'Completed',
          'completed': 1,
          'is_synced': 0,
        };
        final notCompletedMap = {
          'local_id': 2,
          'title': 'Not Completed',
          'completed': 0,
          'is_synced': 1,
        };

        final completedTask = Task.fromMap(completedMap);
        final notCompletedTask = Task.fromMap(notCompletedMap);

        expect(completedTask.completed, true);
        expect(completedTask.isSynced, false);
        expect(notCompletedTask.completed, false);
        expect(notCompletedTask.isSynced, true);
      });

      test('fromMap should handle missing fields with defaults', () {
        final minimalMap = {
          'local_id': 99,
          'title': 'Minimal',
          // Missing most fields
        };

        final task = Task.fromMap(minimalMap);

        expect(task.localId, 99);
        expect(task.title, 'Minimal');
        expect(task.description, '');
        expect(task.completed, false);
        expect(task.userId, '');
        expect(task.priority, TaskPriority.medium);
        expect(task.category, TaskCategory.personal);
        expect(task.isSynced, false);
      });

      test('fromMap should handle invalid date strings gracefully', () {
        final map = {
          'local_id': 77,
          'title': 'Bad Dates',
          'due_date': 'invalid-date',
          'created_at': 'not-a-timestamp',
        };

        final task = Task.fromMap(map);

        expect(task.dueDate, isNull);
        expect(task.createdAt, isNull);
      });
    });

    // ===================================================================
    // copyWith Tests
    // ===================================================================

    group('copyWith Method', () {
      final originalTask = MockData.pendingTask;

      test('copyWith should create new instance with updated fields', () {
        final updated = originalTask.copyWith(
          title: 'Updated Title',
          completed: true,
        );

        expect(updated.title, 'Updated Title');
        expect(updated.completed, true);
        // Other fields should remain unchanged
        expect(updated.description, originalTask.description);
        expect(updated.priority, originalTask.priority);
        expect(updated.userId, originalTask.userId);
      });

      test('copyWith with no parameters should return copy with same values', () {
        final copy = originalTask.copyWith();

        expect(copy.title, originalTask.title);
        expect(copy.description, originalTask.description);
        expect(copy.completed, originalTask.completed);
        expect(copy.priority, originalTask.priority);
        expect(copy.category, originalTask.category);
      });

      test('copyWith should update localId and serverId', () {
        final updated = originalTask.copyWith(
          localId: 999,
          serverId: 888,
        );

        expect(updated.localId, 999);
        expect(updated.serverId, 888);
      });

      test('copyWith should update isSynced flag', () {
        final synced = originalTask.copyWith(isSynced: true);
        final unsynced = originalTask.copyWith(isSynced: false);

        expect(synced.isSynced, true);
        expect(unsynced.isSynced, false);
      });

      test('copyWith should update all date fields', () {
        final newDueDate = DateTime(2025, 1, 15);
        final newCreatedAt = DateTime(2024, 12, 20);

        final updated = originalTask.copyWith(
          dueDate: newDueDate,
          createdAt: newCreatedAt,
        );

        expect(updated.dueDate, newDueDate);
        expect(updated.createdAt, newCreatedAt);
      });
    });

    // ===================================================================
    // Status Getter Tests
    // ===================================================================

    group('Status Getter', () {
      test('status should return completed when task is completed', () {
        final task = Task(
          title: 'Completed Task',
          completed: true,
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
        );

        expect(task.status, TaskStatus.completed);
      });

      test('status should return overdue when not completed and past due date', () {
        final task = Task(
          title: 'Overdue Task',
          completed: false,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(task.status, TaskStatus.overdue);
      });

      test('status should return pending when not completed and future due date', () {
        final task = Task(
          title: 'Pending Task',
          completed: false,
          dueDate: DateTime.now().add(const Duration(days: 5)),
        );

        expect(task.status, TaskStatus.pending);
      });

      test('status should return pending when not completed and no due date', () {
        final task = Task(
          title: 'No Due Date',
          completed: false,
          dueDate: null,
        );

        expect(task.status, TaskStatus.pending);
      });

      test('status should prioritize completed over overdue', () {
        final task = Task(
          title: 'Completed but overdue',
          completed: true,
          dueDate: DateTime.now().subtract(const Duration(days: 10)),
        );

        // Completed tasks should always show as completed
        expect(task.status, TaskStatus.completed);
      });
    });

    // ===================================================================
    // ID Getter Tests
    // ===================================================================

    group('ID Getter', () {
      test('id should return localId as string if available', () {
        final task = Task(
          localId: 42,
          serverId: 100,
          title: 'Task with both IDs',
        );

        expect(task.id, '42'); // localId takes priority
      });

      test('id should return serverId as string if localId is null', () {
        final task = Task(
          localId: null,
          serverId: 200,
          title: 'Task with only serverId',
        );

        expect(task.id, '200');
      });

      test('id should return hashCode-based string if both IDs are null', () {
        final task = Task(
          localId: null,
          serverId: null,
          title: 'Task with no IDs',
        );

        expect(task.id, startsWith('local_'));
        expect(task.id, isNotEmpty);
      });
    });

    // ===================================================================
    // Edge Cases & Validation
    // ===================================================================

    group('Edge Cases', () {
      test('should handle empty string fields', () {
        final task = Task(
          title: '',
          description: '',
          userId: '',
        );

        expect(task.title, '');
        expect(task.description, '');
        expect(task.userId, '');
      });

      test('should handle very long strings', () {
        final longString = 'A' * 10000;
        final task = Task(
          title: longString,
          description: longString,
        );

        expect(task.title.length, 10000);
        expect(task.description.length, 10000);
      });

      test('should handle far future dates', () {
        final farFuture = DateTime(2100, 12, 31);
        final task = Task(
          title: 'Far Future Task',
          dueDate: farFuture,
          createdAt: farFuture,
        );

        expect(task.dueDate, farFuture);
        expect(task.createdAt, farFuture);
        expect(task.status, TaskStatus.pending);
      });

      test('should handle far past dates', () {
        final farPast = DateTime(1900, 1, 1);
        final task = Task(
          title: 'Far Past Task',
          dueDate: farPast,
          createdAt: farPast,
          completed: false,
        );

        expect(task.dueDate, farPast);
        expect(task.createdAt, farPast);
        expect(task.status, TaskStatus.overdue);
      });

      test('should handle special characters in strings', () {
        final task = Task(
          title: 'Task with émojis 🎉 and spëcial çhars!',
          description: 'Testing: <html>, "quotes", \'apostrophes\', & symbols',
        );

        expect(task.title, contains('🎉'));
        expect(task.description, contains('<html>'));
        expect(task.description, contains('"quotes"'));
      });
    });

    // ===================================================================
    // Enum Display Names
    // ===================================================================

    group('Enum Display Names', () {
      test('TaskPriority should have correct Indonesian display names', () {
        expect(TaskPriority.high.displayName, 'Tinggi');
        expect(TaskPriority.medium.displayName, 'Sedang');
        expect(TaskPriority.low.displayName, 'Rendah');
      });

      test('TaskStatus should have correct Indonesian display names', () {
        expect(TaskStatus.completed.displayName, 'Selesai');
        expect(TaskStatus.pending.displayName, 'Belum Selesai');
        expect(TaskStatus.overdue.displayName, 'Terlambat');
      });

      test('TaskCategory should have correct Indonesian display names', () {
        expect(TaskCategory.study.displayName, 'Belajar');
        expect(TaskCategory.assignment.displayName, 'Tugas');
        expect(TaskCategory.project.displayName, 'Proyek');
        expect(TaskCategory.personal.displayName, 'Pribadi');
      });
    });
  });
}
