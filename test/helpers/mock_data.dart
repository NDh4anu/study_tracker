// test/helpers/mock_data.dart

import 'package:study_tracker/features/tasks/models/task.dart';

/// Mock data untuk testing
class MockData {
  // ===================================================================
  // Sample Tasks
  // ===================================================================

  static final Task completedTask = Task(
    localId: 1,
    serverId: 101,
    title: 'Completed Task',
    description: 'This task is completed',
    completed: true,
    userId: 'user123',
    createdAt: DateTime(2024, 12, 1, 10, 0),
    priority: TaskPriority.high,
    category: TaskCategory.study,
    dueDate: DateTime(2024, 12, 10),
    isSynced: true,
  );

  static final Task pendingTask = Task(
    localId: 2,
    serverId: 102,
    title: 'Pending Task',
    description: 'This task is pending',
    completed: false,
    userId: 'user123',
    createdAt: DateTime(2024, 12, 5, 14, 30),
    priority: TaskPriority.medium,
    category: TaskCategory.assignment,
    dueDate: DateTime(2024, 12, 25),
    isSynced: true,
  );

  static final Task overdueTask = Task(
    localId: 3,
    serverId: 103,
    title: 'Overdue Task',
    description: 'This task is overdue',
    completed: false,
    userId: 'user123',
    createdAt: DateTime(2024, 11, 20, 9, 0),
    priority: TaskPriority.high,
    category: TaskCategory.project,
    dueDate: DateTime(2024, 12, 1),
    isSynced: true,
  );

  static final Task unsyncedTask = Task(
    localId: 4,
    serverId: null,
    title: 'Unsynced Task',
    description: 'This task is not synced to server yet',
    completed: false,
    userId: 'user123',
    createdAt: DateTime(2024, 12, 15, 16, 45),
    priority: TaskPriority.low,
    category: TaskCategory.personal,
    dueDate: DateTime(2024, 12, 30),
    isSynced: false,
  );

  static List<Task> get sampleTasks => [
        completedTask,
        pendingTask,
        overdueTask,
        unsyncedTask,
      ];

  // ===================================================================
  // Mock JSON Responses (API)
  // ===================================================================

  static const Map<String, dynamic> validLoginResponse = {
    'access_token': 'mock_access_token_123',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': {
      'id': 'user123',
      'email': 'test@example.com',
      'created_at': '2024-01-01T00:00:00Z',
    },
  };

  static const Map<String, dynamic> validRegisterResponse = {
    'access_token': 'mock_access_token_456',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': {
      'id': 'user456',
      'email': 'newuser@example.com',
      'created_at': '2024-12-15T00:00:00Z',
    },
  };

  static const Map<String, dynamic> taskJsonFromServer = {
    'id': 101,
    'user_id': 'user123',
    'title': 'Task from API',
    'description': 'This came from the server',
    'completed': false,
    'priority': 'high',
    'category': 'study',
    'due_date': '2024-12-25T00:00:00Z',
    'created_at': '2024-12-15T10:00:00Z',
  };

  static const List<Map<String, dynamic>> taskListJsonFromServer = [
    {
      'id': 101,
      'user_id': 'user123',
      'title': 'Task 1',
      'description': 'First task',
      'completed': false,
      'priority': 'high',
      'category': 'study',
      'due_date': '2024-12-20T00:00:00Z',
      'created_at': '2024-12-10T10:00:00Z',
    },
    {
      'id': 102,
      'user_id': 'user123',
      'title': 'Task 2',
      'description': 'Second task',
      'completed': true,
      'priority': 'medium',
      'category': 'assignment',
      'due_date': '2024-12-15T00:00:00Z',
      'created_at': '2024-12-05T14:30:00Z',
    },
  ];

  // ===================================================================
  // Mock SQLite Map Data
  // ===================================================================

  static const Map<String, dynamic> taskMapFromDb = {
    'local_id': 1,
    'server_id': 101,
    'title': 'Task from DB',
    'description': 'This came from SQLite',
    'completed': 0,
    'user_id': 'user123',
    'priority': 'medium',
    'category': 'personal',
    'due_date': '2024-12-25T00:00:00.000Z',
    'created_at': '2024-12-15T10:00:00.000Z',
    'is_synced': 1,
  };

  static const List<Map<String, dynamic>> taskListFromDb = [
    {
      'local_id': 1,
      'server_id': 101,
      'title': 'DB Task 1',
      'description': 'First from DB',
      'completed': 0,
      'user_id': 'user123',
      'priority': 'high',
      'category': 'study',
      'due_date': '2024-12-20T00:00:00.000Z',
      'created_at': '2024-12-10T10:00:00.000Z',
      'is_synced': 1,
    },
    {
      'local_id': 2,
      'server_id': null,
      'title': 'DB Task 2',
      'description': 'Second from DB (unsynced)',
      'completed': 1,
      'user_id': 'user123',
      'priority': 'low',
      'category': 'personal',
      'due_date': '2024-12-30T00:00:00.000Z',
      'created_at': '2024-12-12T16:00:00.000Z',
      'is_synced': 0,
    },
  ];

  // ===================================================================
  // Mock Error Responses
  // ===================================================================

  static const Map<String, dynamic> unauthorizedError = {
    'error': 'invalid_credentials',
    'message': 'Invalid email or password',
  };

  static const Map<String, dynamic> serverError = {
    'error': 'internal_server_error',
    'message': 'Something went wrong on the server',
  };

  static const Map<String, dynamic> validationError = {
    'error': 'validation_error',
    'message': 'Title is required',
  };

  // ===================================================================
  // Mock Session Data
  // ===================================================================

  static const Map<String, String> validSession = {
    'accessToken': 'mock_access_token_123',
    'userId': 'user123',
    'email': 'test@example.com',
  };
}
