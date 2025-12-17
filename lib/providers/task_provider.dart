// lib/providers/task_provider.dart

import 'package:flutter/foundation.dart';

import '../api/task_api.dart';
import '../features/tasks/models/task.dart';
import '../local/task_local_db.dart';

/// TaskProvider dengan pendekatan Offline-First:
/// - Semua operasi UI menggunakan data dari SQLite (lokal)
/// - Sinkronisasi ke server dilakukan di background
/// - User tetap bisa bekerja tanpa koneksi internet
class TaskProvider with ChangeNotifier {
  final TaskApiService _apiService;
  final TaskLocalDb _localDb = TaskLocalDb();

  // ===================================================================
  // State Auth
  // ===================================================================
  bool _isAuthenticated = false;
  String _userId = '';
  String _email = '';

  bool get isAuthenticated => _isAuthenticated;
  String get userId => _userId;
  String get email => _email;

  // ===================================================================
  // State Tasks
  // ===================================================================
  List<Task> _tasks = [];
  bool _isTaskLoading = false;
  String? _errorMessage;
  bool _isSyncing = false;

  List<Task> get tasks => _tasks;
  bool get isTaskLoading => _isTaskLoading;
  String? get errorMessage => _errorMessage;
  bool get isSyncing => _isSyncing;

  TaskProvider(this._apiService);

  // ===================================================================
  // Auth Operations
  // ===================================================================

  /// Check jika ada session yang tersimpan di SharedPreferences
  Future<void> checkSession() async {
    final session = await _apiService.loadSession();
    if (session != null) {
      _isAuthenticated = true;
      _userId = session['userId']!;
      _email = session['email']!;
      notifyListeners();

      // Load tasks dari lokal setelah session berhasil
      await loadTasksOfflineFirst();
    }
  }

  /// Login dengan email dan password
  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.login(email, password);
    if (result != null) {
      _isAuthenticated = true;
      _userId = result['user']['id'].toString();
      _email = result['user']['email'];
      notifyListeners();

      // Load tasks offline-first
      await loadTasksOfflineFirst();
      return true;
    } else {
      _errorMessage = 'Login gagal. Periksa email dan password Anda.';
      notifyListeners();
      return false;
    }
  }

  /// Register user baru
  Future<bool> register(String email, String password) async {
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.register(email, password);
    if (result != null) {
      _isAuthenticated = true;
      _userId = result['user']['id'].toString();
      _email = result['user']['email'];
      notifyListeners();

      return true;
    } else {
      _errorMessage = 'Registrasi gagal. Email mungkin sudah digunakan.';
      notifyListeners();
      return false;
    }
  }

  /// Logout - clear session dan lokal data
  Future<void> logout() async {
    await _apiService.logout();
    await _localDb.clearAll();

    _isAuthenticated = false;
    _userId = '';
    _email = '';
    _tasks = [];

    notifyListeners();
  }

  // ===================================================================
  // Task Operations - OFFLINE FIRST
  // ===================================================================

  /// Load tasks dengan pendekatan offline-first:
  /// 1. Ambil dari SQLite dulu (cepat, langsung tampil ke UI)
  /// 2. Sync dengan server di background (jika online)
  Future<void> loadTasksOfflineFirst() async {
    _isTaskLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Load dari SQLite dulu
      _tasks = await _localDb.getAllTasks();
      _isTaskLoading = false;
      notifyListeners();

      // 2. Sync dengan server di background (tanpa blocking UI)
      _syncWithServer();
    } catch (e) {
      _errorMessage = 'Gagal memuat tasks: $e';
      _isTaskLoading = false;
      notifyListeners();
    }
  }

  /// Sync unidirectional: ambil semua data dari server, replace lokal.
  /// Dipanggil secara background setelah load lokal.
  Future<void> _syncWithServer() async {
    if (!_isAuthenticated) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // Ambil data dari server
      final serverTasks = await _apiService.getTasks();

      if (serverTasks.isNotEmpty) {
        // Replace semua data lokal dengan data server
        await _localDb.replaceAllTasks(serverTasks);

        // Update UI
        _tasks = await _localDb.getAllTasks();
      }

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      // Gagal sync tidak fatal, data lokal tetap bisa dipakai
      debugPrint('Sync error (non-fatal): $e');
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Manual refresh untuk trigger sync
  Future<void> refreshTasks() async {
    await loadTasksOfflineFirst();
  }

  /// Add task baru (offline-first)
  /// 1. Simpan ke SQLite dulu (cepat)
  /// 2. Update UI
  /// 3. Sync ke server di background
  Future<bool> addTask({
    required String title,
    required String description,
    required TaskPriority priority,
    required TaskCategory category,
    required DateTime dueDate,
  }) async {
    try {
      // 1. Buat task dengan isSynced = false
      final newTask = Task(
        title: title,
        description: description,
        userId: _userId,
        priority: priority,
        category: category,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        isSynced: false,
      );

      // 2. Simpan ke SQLite dulu
      final localId = await _localDb.insertTask(newTask);
      final taskWithLocalId = newTask.copyWith(localId: localId);

      // 3. Update UI
      _tasks.insert(0, taskWithLocalId);
      notifyListeners();

      // 4. Sync ke server di background (non-blocking)
      _syncTaskToServer(taskWithLocalId);

      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah task: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sync single task ke server di background
  Future<void> _syncTaskToServer(Task task) async {
    if (!_isAuthenticated) return;

    try {
      // Upload ke server
      final serverTask = await _apiService.createTask(task);

      if (serverTask != null) {
        // Update task lokal dengan serverId dan isSynced = true
        final syncedTask = task.copyWith(
          serverId: serverTask.serverId,
          isSynced: true,
        );

        await _localDb.updateTask(syncedTask);

        // Update UI
        final index = _tasks.indexWhere((t) => t.localId == task.localId);
        if (index != -1) {
          _tasks[index] = syncedTask;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Sync task to server error (non-fatal): $e');
    }
  }

  /// Toggle task completed status (offline-first)
  Future<void> toggleTask(Task task) async {
    try {
      // 1. Update lokal dulu
      final updatedTask = task.copyWith(
        completed: !task.completed,
        isSynced: false, // Mark as unsynced
      );

      await _localDb.updateTask(updatedTask);

      // 2. Update UI
      final index = _tasks.indexWhere((t) => t.localId == task.localId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }

      // 3. Sync ke server di background
      if (_isAuthenticated && updatedTask.serverId != null) {
        _apiService.updateTask(updatedTask).then((success) {
          if (success) {
            final syncedTask = updatedTask.copyWith(isSynced: true);
            _localDb.updateTask(syncedTask);

            final idx = _tasks.indexWhere((t) => t.localId == task.localId);
            if (idx != -1) {
              _tasks[idx] = syncedTask;
              notifyListeners();
            }
          }
        });
      }
    } catch (e) {
      _errorMessage = 'Gagal update task: $e';
      notifyListeners();
    }
  }

  /// Update task (offline-first)
  Future<bool> updateTask(Task task) async {
    try {
      // 1. Update lokal dulu
      final updatedTask = task.copyWith(isSynced: false);
      await _localDb.updateTask(updatedTask);

      // 2. Update UI
      final index = _tasks.indexWhere((t) => t.localId == task.localId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }

      // 3. Sync ke server di background
      if (_isAuthenticated && updatedTask.serverId != null) {
        _apiService.updateTask(updatedTask).then((success) {
          if (success) {
            final syncedTask = updatedTask.copyWith(isSynced: true);
            _localDb.updateTask(syncedTask);

            final idx = _tasks.indexWhere((t) => t.localId == task.localId);
            if (idx != -1) {
              _tasks[idx] = syncedTask;
              notifyListeners();
            }
          }
        });
      }

      return true;
    } catch (e) {
      _errorMessage = 'Gagal update task: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete task (offline-first)
  Future<bool> deleteTask(Task task) async {
    try {
      // 1. Hapus dari lokal dulu
      if (task.localId != null) {
        await _localDb.deleteTask(task.localId!);
      }

      // 2. Update UI
      _tasks.removeWhere((t) => t.localId == task.localId);
      notifyListeners();

      // 3. Hapus dari server di background (jika ada serverId)
      if (_isAuthenticated && task.serverId != null) {
        _apiService.deleteTask(task.serverId!).catchError((e) {
          debugPrint('Delete from server error (non-fatal): $e');
          return false;
        });
      }

      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus task: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mengambil jumlah task yang belum tersinkron (untuk debugging/UI indicator)
  Future<int> getUnsyncedCount() async {
    final unsynced = await _localDb.getUnsyncedTasks();
    return unsynced.length;
  }
}
