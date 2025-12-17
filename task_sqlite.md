Offline-First dengan SQLite
Overview
Pada pertemuan ini, mahasiswa akan meng-upgrade aplikasi REST API + Supabase yang sudah dibuat di Pertemuan 9 menjadi aplikasi offline-first dengan menambahkan local database SQLite di sisi Flutter. Fokus utamanya adalah menyimpan dan membaca data tasks dari SQLite, lalu melakukan sinkronisasi dengan Supabase ketika internet tersedia.

Durasi: 3 jam (1 jam teori, 2 jam praktik).

Prasyarat: Mahasiswa sudah menyelesaikan praktik Pertemuan 9 (login, CRUD tasks via Supabase REST API dengan http, provider, dan shared_preferences).

Learning Outcomes
Setelah menyelesaikan pertemuan ini, mahasiswa diharapkan mampu:

Menjelaskan konsep offline-first dan peran local database dalam arsitektur mobile app.
Menggunakan SQLite di Flutter (via sqflite/drift—di materi ini dipilih satu, misalnya sqflite) untuk menyimpan data tasks secara lokal.
Mengintegrasikan data lokal (SQLite) dengan REST API Supabase: load dari lokal terlebih dahulu, lalu sync dengan server.
Mengelola status sinkronisasi (misalnya menandai task yang belum tersinkron) dan menangani kondisi offline/online sederhana.
Bagian I – Konsep Teori
1. Kenapa Offline-First?
Aplikasi mobile sering digunakan di kondisi jaringan tidak stabil (wifi putus, sinyal lemah, mode pesawat). Offline-first berarti aplikasi tetap berfungsi utama meskipun tanpa internet, lalu melakukan sinkronisasi ketika terkoneksi kembali.
Dibandingkan pendekatan online-only (seperti P9), offline-first meningkatkan user experience (data tetap muncul, aksi pengguna tidak “hilang”) dan mengurangi error network di UI.
2. Arsitektur Online-Only vs Offline-First
Gunakan tabel ringkas untuk menegaskan perbedaan konteks P9 vs P10:

Aspek	P9: Online-Only (Supabase REST)	P10: Offline-First (Supabase + SQLite)
Sumber data utama	Server Supabase	Local SQLite
Saat tanpa internet	Tidak bisa load/update tasks	Tetap bisa lihat & tambah tasks
Penyimpanan lokal	Hanya token (SharedPreferences)	Token + cache tasks di SQLite
Flow baca data	Langsung GET ke API	Baca dari SQLite, lalu sync API
Kompleksitas kode	Lebih sederhana	Lebih kompleks (ada sync layer)
3. Peran SQLite di Mobile App
SQLite adalah embedded relational database yang berjalan di device (Android/iOS) dan umum dipakai untuk menyimpan data struktural (tabel, relasi) secara lokal.
Di Flutter, akses SQLite biasanya melalui package seperti sqflite (low level, mirip raw SQL) atau drift (ORM-like, type-safe). Untuk pertemuan ini dipilih pendekatan yang lebih straightforward agar fokus di konsep sinkronisasi.
4. Pola Sinkronisasi Sederhana
Untuk level awal, cukup gunakan pola sync berikut (tanpa conflict resolution kompleks):

Saat app dibuka:
Load data dari SQLite → tampilkan di UI.
Jika ada internet → fetch dari Supabase → update SQLite → refresh UI.
Saat user menambah task:
Simpan task ke SQLite dan tandai is_synced = false.
Jika ada internet → kirim ke Supabase → jika sukses, update record lokal is_synced = true dan simpan server_id (id dari Supabase).
Saat user toggle completed atau delete task:
Update status di SQLite.
Jika online → kirim perubahan ke Supabase (patch/delete) berdasarkan server_id.
Tujuannya adalah memberi gambaran bahwa SQLite adalah source-of-truth lokal, sedangkan Supabase adalah source-of-truth global yang disinkronkan sewaktu-waktu.

Bagian II – Praktikum: Menambahkan SQLite ke Project P9
Catatan: Praktikum ini tidak membuat project baru. Mahasiswa melanjutkan project rest_api_demo dari Pertemuan 9, lalu menambahkan fitur SQLite di atas arsitektur yang sudah ada (Task, TaskApiService, TaskProvider, dan UI screens).

Struktur awal P9 (sebelum ditambah SQLite) kira-kira seperti ini:

lib/
├── main.dart
├── api/
│   └── task_api.dart
├── models/
│   └── task.dart
├── providers/
│   └── task_provider.dart
└── screens/
    ├── login_screen.dart
    ├── task_list_screen.dart
    └── add_task_screen.dart
Setelah P10, akan ditambah folder local/ untuk SQLite:

lib/
├── main.dart
├── api/
│   └── task_api.dart
├── local/
│   └── task_local_db.dart     # SQLite helper / repository lokal
├── models/
│   └── task.dart
├── providers/
│   └── task_provider.dart
└── screens/
    ├── login_screen.dart
    ├── task_list_screen.dart
    └── add_task_screen.dart
Praktikum 1 – Menambahkan Dependency SQLite
Buka pubspec.yaml pada project rest_api_demo (project yang sama dari P9).
Tambahkan dependency untuk SQLite, misalnya:
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  provider: ^6.0.5
  shared_preferences: ^2.2.0
  intl: ^0.18.1
  sqflite: ^2.3.0
  path: ^1.8.0
Jalankan:
flutter pub get
Langkah ini menambahkan kemampuan aplikasi untuk membuka file database SQLite dan mengatur path penyimpanan database di device.

Praktikum 2 – Memperluas Model Task untuk Offline
Tujuan praktikum:

Menambahkan field yang dibutuhkan untuk SQLite dan status sinkronisasi.
Memisahkan cara konversi data untuk REST API (Supabase) dan untuk SQLite [1].
// lib/models/task.dart

/// Model Task versi offline-first:
/// - Mendukung penyimpanan di Supabase (REST API)
/// - Mendukung penyimpanan di SQLite (offline local DB)
class Task {
  // --- Field untuk SQLite (local DB) ---
  /// Primary key di SQLite, auto-increment.
  /// Tidak dikirim ke server.
  final int? localId;

  // --- Field untuk Supabase / server ---
  /// ID dari Supabase (kolom "id" di tabel tasks).
  /// Pada Pertemuan 9, field ini bernama `id` dan dipakai langsung untuk API [file:11].
  final int? serverId;

  // --- Field domain utama (dipakai di lokal & server) ---
  final String title;
  final String description;
  final bool completed;
  final String userId;
  final DateTime? createdAt;

  // --- Status sinkronisasi ---
  /// Menandai apakah data ini sudah tersinkron ke server.
  /// false: baru ada di lokal / perubahan lokal belum terkirim.
  final bool isSynced;

  Task({
    this.localId,
    this.serverId,
    required this.title,
    this.description = '',
    this.completed = false,
    required this.userId,
    this.createdAt,
    this.isSynced = false,
  });

  // ===================================================================
  // Bagian 1: Konversi untuk REST API (Supabase)
  // ===================================================================

  /// Digunakan ketika mengirim data ke Supabase (body JSON).
  /// Hanya field yang relevan dengan tabel Supabase yang dikirim [file:11].
  Map<String, dynamic> toJson() {
    final json = {
	  'title': title,
	  'description': description,
	  'completed': completed,
	  'user_id': userId,
	  'created_at': createdAt?.toIso8601String(),
	};

	// Hanya include 'id' untuk update operation (bukan create)
	if (serverId != null) {
	  json['id'] = serverId;
	}

	return json;
  }

  /// Digunakan ketika menerima response JSON dari Supabase [file:11].
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      // di P9: id: json['id']
      serverId: json['id'] as int?,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      completed: (json['completed'] ?? false) as bool,
      userId: json['user_id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,

      // Data dari server dianggap sudah tersinkron.
      isSynced: true,
    );
  }

  // ===================================================================
  // Bagian 2: Konversi untuk SQLite (local DB)
  // ===================================================================

  /// Konversi Task ke Map untuk disimpan ke tabel SQLite.
  /// Nama kolom bisa disesuaikan dengan skema tabel lokal.
  Map<String, dynamic> toMap() {
    return {
      'local_id': localId,
      'server_id': serverId,
      'title': title,
      'description': description,
      'completed': completed ? 1 : 0,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// Membuat Task dari hasil query SQLite (Map).
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      localId: map['local_id'] as int?,
      serverId: map['server_id'] as int?,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      completed: (map['completed'] ?? 0) == 1,
      userId: map['user_id'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      isSynced: (map['is_synced'] ?? 0) == 1,
    );
  }

  // ===================================================================
  // Bagian 3: Helper untuk copyWith (memudahkan update sebagian field)
  // ===================================================================

  Task copyWith({
    int? localId,
    int? serverId,
    String? title,
    String? description,
    bool? completed,
    String? userId,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return Task(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
Catatan Perbedaan dengan Versi Pertemuan 9

Berikut poin perubahan utama dibanding model Task di P9 [1]:

Penambahan field untuk kebutuhan offline & sync

localId
Baru di P10, dipakai sebagai primary key di SQLite.
Tidak ada di P9 karena saat itu data hanya berasal dari Supabase [1].
serverId
Di P9 bernama id dan langsung merepresentasikan ID Supabase [1].
Di P10 dipisah dari localId agar jelas mana ID lokal dan mana ID di server.
isSynced
Baru di P10 untuk menandai apakah record ini sudah tersinkron ke server (Supabase) atau belum.
Penambahan metode khusus SQLite

toMap() dan factory Task.fromMap(...) adalah tambahan untuk kebutuhan SQLite.
Di P9 hanya ada toJson() dan fromJson() untuk keperluan REST API [1].
Penyesuaian fromJson()

Sekarang memetakan serverId dari json['id'], bukan langsung ke id field model.
isSynced diset true ketika data datang dari server, karena secara definisi sudah sinkron.
Penambahan copyWith()

Digunakan untuk mempermudah update sebagian field di layer provider (misalnya saat toggle completed atau mengubah isSynced setelah sync sukses).
Di P9 update dilakukan dengan membuat instance baru manual tanpa helper [1].
Dengan perubahan ini, mahasiswa bisa tetap memakai satu model Task di seluruh aplikasi (UI, provider, API, SQLite), tetapi dengan jalur konversi yang berbeda sesuai konteks: toJson/fromJson untuk Supabase dan toMap/fromMap untuk SQLite [1].

Praktikum 3 – Membuat Layer SQLite (task_local_db.dart)
Tujuan praktikum:

Menyediakan layer akses SQLite terpisah untuk operasi CRUD lokal.
Menyelaraskan skema tabel lokal dengan model Task offline-first yang sudah dibuat di Praktikum 2 [1].
// lib/local/task_local_db.dart

import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task.dart';

/// Helper class untuk mengelola database lokal (SQLite)
/// yang menyimpan data Task secara offline.
class TaskLocalDb {
  static const String _dbName = 'tasks_offline.db';
  static const int _dbVersion = 1;

  static const String _tableTasks = 'tasks_local';

  static Database? _database;

  // Singleton pattern (opsional, tapi memudahkan reuse instance)
  static final TaskLocalDb instance = TaskLocalDb._internal();

  TaskLocalDb._internal();

  factory TaskLocalDb() {
    return instance;
  }

  // ===================================================================
  // Inisialisasi & Open Database
  // ===================================================================

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // openDatabase akan membuat file DB jika belum ada.
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  // Membuat tabel pada saat database pertama kali dibuat.
  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableTasks (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        user_id TEXT NOT NULL,
        created_at TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ===================================================================
  // Operasi CRUD ke SQLite
  // ===================================================================

  /// Mengambil semua task dari SQLite, diurutkan dari yang terbaru.
  Future<List<Task>> getAllTasks() async {
    final db = await database;

    final maps = await db.query(
      _tableTasks,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Mengambil semua task yang belum tersinkron ke server (is_synced = 0).
  Future<List<Task>> getUnsyncedTasks() async {
    final db = await database;

    final maps = await db.query(
      _tableTasks,
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Insert task baru ke SQLite.
  /// Mengembalikan local_id (primary key) yang di-generate SQLite.
  Future<int> insertTask(Task task) async {
    final db = await database;

    // Pastikan createdAt terisi jika null.
    final toInsert = task.copyWith(
      createdAt: task.createdAt ?? DateTime.now(),
    );

    final id = await db.insert(
      _tableTasks,
      toInsert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  /// Update task berdasarkan local_id.
  /// Digunakan untuk update completed, serverId, dan isSynced.
  Future<int> updateTask(Task task) async {
    if (task.localId == null) return 0;

    final db = await database;

    return await db.update(
      _tableTasks,
      task.toMap(),
      where: 'local_id = ?',
      whereArgs: [task.localId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Menghapus task dari SQLite berdasarkan local_id.
  Future<int> deleteTask(int localId) async {
    final db = await database;

    return await db.delete(
      _tableTasks,
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// Menghapus semua task dan mengisi ulang dari data server
  /// (misalnya setelah full sync sukses).
  Future<void> replaceAllTasks(List<Task> tasks) async {
    final db = await database;
    final batch = db.batch();

    // Kosongkan tabel.
    batch.delete(_tableTasks);

    // Insert ulang dengan isSynced = true (data dari server).
    for (final task in tasks) {
      final syncedTask = task.copyWith(
        localId: null,
        isSynced: true,
      );

      batch.insert(
        _tableTasks,
        syncedTask.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Opsional: clear semua data lokal (misalnya saat logout).
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableTasks);
  }
}
Catatan Penting & Perbedaan terhadap P9

Layer baru khusus lokal, terpisah dari TaskApiService

Di P9 hanya ada TaskApiService yang berkomunikasi dengan Supabase via HTTP (http package) [1].
Di P10 ditambahkan TaskLocalDb yang berkomunikasi dengan SQLite via sqflite.
Hal ini mengikuti prinsip separation of concerns: satu class untuk remote API, satu class untuk local DB.
Skema tabel lokal diselaraskan dengan model offline-first

Tabel tasks_local memiliki kolom local_id, server_id, title, description, completed, user_id, created_at, is_synced.
Kolom-kolom ini dipetakan langsung ke field di model Task melalui toMap() dan fromMap() yang sudah dibuat di Praktikum 2, sehingga integrasi dengan provider lebih mudah.
Metode getAllTasks() dan getUnsyncedTasks()

getAllTasks() digunakan untuk menampilkan data di UI tanpa harus memukul API setiap kali (offline-first).
getUnsyncedTasks() akan dipakai nanti di layer provider untuk mengirim data yang belum tersinkron ketika koneksi internet tersedia.
Metode replaceAllTasks() untuk full refresh dari server

Metode ini memudahkan implementasi strategi sync sederhana:
Ambil seluruh data dari Supabase dengan TaskApiService.getTasks() [1].
Panggil replaceAllTasks() untuk mengosongkan tabel lokal dan mengisi ulang dengan data server.
Ini menyederhanakan logika sync di pertemuan awal sebelum membahas conflict resolution yang lebih kompleks.
Kalau sudah oke, langkah berikutnya bisa lanjut ke Praktikum 4: mengubah TaskProvider agar memakai kombinasi TaskApiService + TaskLocalDb dengan pola offline-first.

Praktikum 4 – Mengubah TaskProvider menjadi Offline-First
Tujuan praktikum:

Menggabungkan Supabase (TaskApiService) dan SQLite (TaskLocalDb) di dalam satu provider.
Mengubah flow dari online-only (loadTasks langsung ke API) menjadi offline-first (load dari SQLite dulu, baru sync ke server) [1].
// lib/providers/task_provider.dart

import 'package:flutter/material.dart';

import '../api/task_api.dart';
import '../local/task_local_db.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final TaskApiService _apiService;
  final TaskLocalDb _localDb;

  TaskProvider(this._apiService, this._localDb);

  // =========================
  // Auth state
  // =========================
  bool _isAuthenticated = false;
  bool _isAuthLoading = true;
  bool _isTaskLoading = false;
  String? _email;
  String? _userId;
  String? _errorMessage;

  // =========================
  // Task state
  // =========================
  List<Task> _tasks = [];

  // Optional: status koneksi / sync sederhana
  bool _isSyncing = false;

  // =========================
  // Getters
  // =========================
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isAuthLoading; // Backward compatibility
  bool get isAuthLoading => _isAuthLoading;
  bool get isTaskLoading => _isTaskLoading;
  bool get isSyncing => _isSyncing;
  String? get email => _email;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;
  List<Task> get tasks => _tasks;

  /// Jumlah task yang belum tersinkron ke server
  int get unsyncedCount =>
      _tasks.where((task) => task.isSynced == false).length;

  // =========================
  // AUTH FLOW
  // =========================

  // Check saved session on app start
  Future<void> checkSession() async {
    _isAuthLoading = true;
    notifyListeners();

    final session = await _apiService.loadSession();
    if (session != null) {
      _isAuthenticated = true;
      _email = session['email'];
      _userId = session['userId'];
      // Setelah session valid, langsung load tasks offline-first
      await loadTasksOfflineFirst();
    }

    _isAuthLoading = false;
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    _isAuthLoading = true;
    notifyListeners();

    final result = await _apiService.login(email, password);

    _isAuthLoading = false;

    if (result != null) {
      _isAuthenticated = true;
      _email = result['user']['email'];
      _userId = result['user']['id'];

      // Setelah login sukses, sync data dari server ke lokal
      await loadTasksOfflineFirst();

      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Login gagal. Periksa email dan password.';
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register(String email, String password) async {
    _errorMessage = null;
    _isAuthLoading = true;
    notifyListeners();

    final result = await _apiService.register(email, password);

    _isAuthLoading = false;

    if (result != null) {
      _isAuthenticated = true;
      _email = result['user']['email'];
      _userId = result['user']['id'].toString();

      // User baru: tidak ada data lama di lokal, tapi tetap panggil sync
      await loadTasksOfflineFirst();

      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Registrasi gagal. Coba email lain.';
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _apiService.logout();
    await _localDb.clearAll();

    _isAuthenticated = false;
    _email = null;
    _userId = null;
    _tasks = [];
    notifyListeners();
  }

  // =========================
  // TASK OPERATIONS (OFFLINE-FIRST)
  // =========================

  /// Load tasks dengan strategi offline-first:
  /// 1) Tampilkan dulu data dari SQLite
  /// 2) Coba sync dengan server (Supabase)
  Future<void> loadTasksOfflineFirst() async {
    if (_userId == null) return;

    _isTaskLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Baca dari lokal terlebih dahulu
      _tasks = await _localDb.getAllTasks();
      notifyListeners();

      // 2. Coba sync dengan server
      _isSyncing = true;
      notifyListeners();

      // Ambil semua tasks dari server
      final remoteTasks = await _apiService.getTasks();

      // Map hasil remote agar punya userId & flag isSynced true
      final normalizedRemote = remoteTasks.map((t) {
        return t.copyWith(
          userId: _userId!,
          isSynced: true,
        );
      }).toList();

      // Ganti isi tabel lokal dengan data server
      await _localDb.replaceAllTasks(normalizedRemote);

      // Baca ulang dari lokal setelah sync
      _tasks = await _localDb.getAllTasks();
      _errorMessage = null;
    } catch (e) {
      // Kalau gagal sync (misalnya offline), tetap pakai data lokal
      _errorMessage = 'Gagal sinkronisasi dengan server (mode offline).';
    }

    _isSyncing = false;
    _isTaskLoading = false;
    notifyListeners();
  }

  /// Menambah task baru:
  /// - Selalu disimpan ke SQLite
  /// - Jika online, coba kirim ke server dan update flag isSynced
  Future<bool> addTask(String title, String description) async {
    if (_userId == null) return false;

    _errorMessage = null;

    // 1. Simpan ke lokal terlebih dahulu (optimistic)
    final localTask = Task(
      title: title,
      description: description,
      userId: _userId!,
      completed: false,
      isSynced: false,
      createdAt: DateTime.now(),
    );

    final localId = await _localDb.insertTask(localTask);
    final insertedTask = localTask.copyWith(localId: localId);

    // Update list di memori
    _tasks.insert(0, insertedTask);
    notifyListeners();

    // 2. Coba kirim ke server
    try {
      final createdOnServer = await _apiService.createTask(insertedTask);

      if (createdOnServer != null) {
        // Update record lokal: set serverId & isSynced = true
        final syncedTask = insertedTask.copyWith(
          serverId: createdOnServer.serverId,
          isSynced: true,
          createdAt: createdOnServer.createdAt ?? insertedTask.createdAt,
        );

        await _localDb.updateTask(syncedTask);

        // Update di list in-memory
        final index =
            _tasks.indexWhere((t) => t.localId == insertedTask.localId);
        if (index != -1) {
          _tasks[index] = syncedTask;
        }

        notifyListeners();
        return true;
      } else {
        // Gagal create ke server, tetap ada di lokal dengan isSynced = false
        _errorMessage = 'Task disimpan lokal tetapi gagal ke server.';
        notifyListeners();
        return true; // dari sudut pandang user, tetap berhasil tersimpan
      }
    } catch (e) {
      // Network error, tetap anggap sukses di lokal
      _errorMessage = 'Mode offline: task disimpan lokal.';
      notifyListeners();
      return true;
    }
  }

  /// Toggle completed:
  /// - Update status di SQLite
  /// - Jika punya serverId dan online, update juga di server
  Future<bool> toggleTask(Task task) async {
    // 1. Update lokal (optimistic)
    final updatedLocal = task.copyWith(
      completed: !task.completed,
      isSynced: false, // akan diset true jika sync ke server sukses
    );

    await _localDb.updateTask(updatedLocal);

    final index = _tasks.indexWhere((t) => t.localId == task.localId);
    if (index != -1) {
      _tasks[index] = updatedLocal;
      notifyListeners();
    }

    // 2. Coba update ke server jika ada serverId
    if (task.serverId == null) {
      // Belum pernah tersinkron, cukup lokal saja
      return true;
    }

    try {
      final success = await _apiService.updateTask(
        updatedLocal.copyWith(
          // Pastikan id yang dikirim adalah serverId
          serverId: task.serverId,
        ),
      );

      if (success) {
        final syncedTask = updatedLocal.copyWith(
          isSynced: true,
        );

        await _localDb.updateTask(syncedTask);

        final idx = _tasks.indexWhere((t) => t.localId == syncedTask.localId);
        if (idx != -1) {
          _tasks[idx] = syncedTask;
          notifyListeners();
        }

        return true;
      } else {
        _errorMessage = 'Gagal mengupdate task di server.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Mode offline: perubahan hanya tersimpan lokal.';
      notifyListeners();
      return true;
    }
  }

  /// Delete task:
  /// - Hapus dari SQLite
  /// - Jika punya serverId dan online, hapus juga di server
  Future<bool> deleteTask(Task task) async {
    if (task.localId == null) return false;

    // 1. Hapus di lokal terlebih dahulu
    await _localDb.deleteTask(task.localId!);
    _tasks.removeWhere((t) => t.localId == task.localId);
    notifyListeners();

    // 2. Jika tidak punya serverId, selesai di sini
    if (task.serverId == null) {
      return true;
    }

    // 3. Hapus di server
    try {
      final success = await _apiService.deleteTask(task.serverId!);
      if (!success) {
        _errorMessage = 'Gagal menghapus task di server.';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Mode offline: task hanya terhapus di lokal.';
      notifyListeners();
      return true;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
Catatan Perbedaan dengan TaskProvider di Pertemuan 9

Konstruktor & dependency baru

P9: TaskProvider(this._apiService); hanya berinteraksi dengan Supabase [1].
P10: TaskProvider(this._apiService, this._localDb); menambahkan TaskLocalDb agar bisa baca/tulis ke SQLite.
Metode loadTasks() diubah menjadi loadTasksOfflineFirst()

P9: loadTasks() langsung memanggil _apiService.getTasks() dan menampilkan hasilnya di UI [1].
P10: loadTasksOfflineFirst():
Baca dulu dari SQLite (_localDb.getAllTasks()), sehingga UI tetap jalan tanpa internet.
Lalu mencoba sync dengan server (_apiService.getTasks() → _localDb.replaceAllTasks(...)).
Operasi tambah, update, delete sekarang selalu menyentuh SQLite

addTask()
P9: langsung kirim ke Supabase (createTask) dan kalau sukses baru dimasukkan ke list _tasks [1].
P10: selalu insert ke SQLite dulu, update list di memori, lalu coba kirim ke server; jika gagal, task tetap ada di lokal dengan isSynced = false.
toggleTask() dan deleteTask():
Sekarang selalu memodifikasi SQLite dulu (optimistic update), baru coba sync ke server jika serverId tersedia.
Penambahan status sinkronisasi

Ada field isSynced yang dimanfaatkan di provider untuk:
Menandai data yang belum terkirim.
Menyediakan getter unsyncedCount yang bisa dipakai di UI sebagai indikator “X task belum tersinkron”.
Penanganan offline sederhana

Di beberapa catch (e) error network tidak langsung dianggap failure total, tetapi diinterpretasikan sebagai “mode offline”: perubahan tetap tersimpan lokal dan user tetap bisa melanjutkan penggunaan aplikasi.
Langkah selanjutnya, di Praktikum 5, bisa menyesuaikan main.dart untuk meng-inject TaskLocalDb ke TaskProvider, lalu menambahkan indikator offline/sync di TaskListScreen menggunakan isSyncing dan unsyncedCount. [1]

lib/api/task_api.dart (Versi Offline-First Friendly)
// lib/api/task_api.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class TaskApiService {
  // Ganti dengan Supabase project Anda sendiri.
  static const String _baseUrl = 'https://lqskcgghhozyxzanbadq.supabase.co';
  static const String _apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxxc2tjZ2doaG96eXh6YW5iYWRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM5MTAzNjEsImV4cCI6MjA3OTQ4NjM2MX0.GYPfUopr2TRQ-KgT6I8DGKYOjY7WXVVOx0hpHPxOvuQ';

  String? _accessToken;

  // Build headers untuk API requests
  Map<String, String> _getHeaders({
    bool includeAuth = true,
    bool returnRepresentation = false,
  }) {
    final headers = <String, String>{
      'apikey': _apiKey,
      'Content-Type': 'application/json',
    };

    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    // Untuk create operations, minta server mengembalikan record yang dibuat
    if (returnRepresentation) {
      headers['Prefer'] = 'return=representation';
    }

    return headers;
  }

  // =========================================================
  // AUTHENTICATION
  // =========================================================

  // Login user
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/v1/token?grant_type=password'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        await _saveSession(data);
        return data;
      }

      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Register user
  Future<Map<String, dynamic>?> register(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/v1/signup'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        await _saveSession(data);
        return data;
      }
      return null;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  // Load saved session
  Future<Map<String, String>?> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final userId = prefs.getString('user_id');
      final email = prefs.getString('user_email');

      if (token != null && userId != null && email != null) {
        _accessToken = token;
        return {
          'token': token,
          'userId': userId,
          'email': email,
        };
      }
      return null;
    } catch (e) {
      print('Load session error: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      _accessToken = null;
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Save session to local storage
  Future<void> _saveSession(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('access_token', data['access_token']);
      await prefs.setString('user_id', data['user']['id'].toString());
      await prefs.setString('user_email', data['user']['email']);
    } catch (e) {
      print('Save session error: $e');
    }
  }

  // =========================================================
  // TASK OPERATIONS (REMOTE / SUPABASE)
  // =========================================================

  // Get all tasks for current user
  Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/rest/v1/tasks?select=*&order=created_at.desc'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => Task.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      } else if (response.statusCode == 401) {
        // Handle unauthorized error
        print('Unauthorized: Token may be expired');
        return [];
      }

      return [];
    } catch (e) {
      print('Get tasks error: $e');
      return [];
    }
  }

  // Create new task
  Future<Task?> createTask(Task task) async {
    try {
      // Untuk Supabase, hanya field yang relevan dikirim (Task.toJson)
      final response = await http.post(
        Uri.parse('$_baseUrl/rest/v1/tasks'),
        headers: _getHeaders(returnRepresentation: true),
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.body.isEmpty) {
          // Fallback jika server tidak mengembalikan body
          return task;
        }

        final data = jsonDecode(response.body);

        // Supabase bisa mengembalikan array atau object tunggal
        if (data is List && data.isNotEmpty) {
          return Task.fromJson(Map<String, dynamic>.from(data[0]));
        } else if (data is Map) {
          return Task.fromJson(Map<String, dynamic>.from(data));
        } else {
          return null;
        }
      }

      return null;
    } catch (e) {
      print('Create task error: $e');
      return null;
    }
  }

  // Update task (toggle completed)
  Future<bool> updateTask(Task task) async {
    // Di sini yang dipakai sebagai identifier adalah serverId (id di Supabase)
    if (task.serverId == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/rest/v1/tasks?id=eq.${task.serverId}'),
        headers: _getHeaders(),
        body: jsonEncode(task.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Update task error: $e');
      return false;
    }
  }

  // Delete task
  Future<bool> deleteTask(int serverId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/rest/v1/tasks?id=eq.$serverId'),
        headers: _getHeaders(),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Delete task error: $e');
      return false;
    }
  }
}
Apa yang Berbeda Dibanding task_api.dart di P9?

Penyesuaian ke model Task baru

Di P9, Task punya field id yang sekaligus dipakai sebagai ID Supabase [1].
Di P10, ID server dipisah ke serverId (sementara localId untuk SQLite), sehingga:
getTasks() memanggil Task.fromJson(...) yang mengisi serverId dari json['id'] (sudah diatur di model).
updateTask() dan deleteTask() sekarang menggunakan task.serverId sebagai identifier pada URL:
PATCH /rest/v1/tasks?id=eq.${task.serverId}
DELETE /rest/v1/tasks?id=eq.$serverId
Kontrak method disesuaikan dengan provider offline-first

updateTask(Task task) sekarang mengasumsikan bahwa Task sudah berisi serverId (diisi di provider ketika sync).
deleteTask(int serverId) menerima ID server, bukan Task penuh, supaya provider bisa menghapus dulu di lokal, lalu memanggil API dengan task.serverId.
Bagian auth & session tetap sama

Flow login, register, simpan token di SharedPreferences, dan load session tidak berubah dari P9 [1].
Ini menegaskan bahwa pertemuan 10 tidak merombak backend, hanya menambah local DB dan sync.
Dengan perubahan ini, TaskApiService tetap sederhana dan fokus pada komunikasi Supabase, sementara seluruh logika offline-first (SQLite, localId, isSynced, dsb.) dikelola di model Task + TaskLocalDb + TaskProvider. [1]

Praktikum 5 – Menambahkan Indikator Offline/Sync di UI
Tujuan: mengubah inisialisasi TaskProvider agar menerima TaskLocalDb dan langsung memanggil checkSession() seperti sebelumnya [1].

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api/task_api.dart';
import 'local/task_local_db.dart';
import 'providers/task_provider.dart';
import 'screens/login_screen.dart';
import 'screens/task_list_screen.dart';

void main() {
  // Initialize services
  final apiService = TaskApiService();
  final localDb = TaskLocalDb();

  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final taskProvider = TaskProvider(apiService, localDb);
        taskProvider.checkSession(); // Check saved session + load offline data
        return taskProvider;
      },
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline-First Tasks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Selector<TaskProvider, bool>(
        selector: (context, provider) => provider.isAuthLoading,
        builder: (context, isAuthLoading, child) {
          return Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (isAuthLoading) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return taskProvider.isAuthenticated
                  ? TaskListScreen()
                  : LoginScreen();
            },
          );
        },
      ),
    );
  }
}
Catatan Perubahan dari P9

P9: TaskProvider(apiService); hanya menerima TaskApiService [1].
P10: TaskProvider(apiService, localDb); menambahkan TaskLocalDb untuk SQLite.
Title aplikasi diganti menjadi 'Offline-First Tasks' agar selaras dengan tema pertemuan.
Update TaskListScreen untuk Indikator Offline/Sync
Tujuan:

Menampilkan status sync dan jumlah task yang belum tersinkron (unsyncedCount).
Mengganti loadTasks() lama dengan loadTasksOfflineFirst() [1].
// lib/screens/task_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import 'add_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoaded) {
        _hasLoaded = true;
        context.read<TaskProvider>().loadTasksOfflineFirst();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Tasks (${taskProvider.tasks.length})'),
            const SizedBox(height: 2),
            _buildSyncSubtitle(taskProvider),
          ],
        ),
        actions: [
          // Ikon status sync sederhana
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: taskProvider.isSyncing
                  ? const Icon(Icons.sync, color: Colors.yellowAccent)
                  : (taskProvider.unsyncedCount > 0
                      ? const Icon(Icons.cloud_off, color: Colors.orangeAccent)
                      : const Icon(Icons.cloud_done, color: Colors.greenAccent)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => taskProvider.loadTasksOfflineFirst(),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                taskProvider.logout();
              }
            },
          ),
        ],
      ),
      body: _buildBody(taskProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          );

          if (result == true) {
            taskProvider.loadTasksOfflineFirst();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSyncSubtitle(TaskProvider taskProvider) {
    if (taskProvider.isTaskLoading && taskProvider.tasks.isEmpty) {
      return const Text(
        'Memuat data lokal...',
        style: TextStyle(fontSize: 12),
      );
    }

    if (taskProvider.isSyncing) {
      return const Text(
        'Sinkronisasi dengan server...',
        style: TextStyle(fontSize: 12),
      );
    }

    if (taskProvider.unsyncedCount > 0) {
      return Text(
        '${taskProvider.unsyncedCount} task belum tersinkron',
        style: const TextStyle(fontSize: 12),
      );
    }

    return const Text(
      'Semua data tersinkron',
      style: TextStyle(fontSize: 12),
    );
  }

  Widget _buildBody(TaskProvider taskProvider) {
    if (taskProvider.isTaskLoading && taskProvider.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (taskProvider.errorMessage != null &&
        taskProvider.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(taskProvider.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => taskProvider.loadTasksOfflineFirst(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (taskProvider.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada tasks', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Tap + untuk menambah task pertama'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => taskProvider.loadTasksOfflineFirst(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: taskProvider.tasks.length,
        itemBuilder: (context, index) {
          final task = taskProvider.tasks[index];
          return TaskCard(task: task);
        },
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isUnsynced = !task.isSynced;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Checkbox(
              value: task.completed,
              onChanged: (value) async {
                final success =
                    await context.read<TaskProvider>().toggleTask(task);

                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal update task'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            if (isUnsynced)
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(
                  Icons.offline_bolt,
                  size: 14,
                  color: Colors.orangeAccent,
                ),
              ),
          ],
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (isUnsynced)
              const Text(
                'Belum terkirim ke server',
                style: TextStyle(fontSize: 11, color: Colors.orange),
              ),
          ],
        ),
        trailing: task.completed
            ? const Icon(Icons.check_circle, color: Colors.green)
            : PopupMenuButton(
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus Task'),
                        content:
                            const Text('Yakin ingin menghapus task ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      final success = await context
                          .read<TaskProvider>()
                          .deleteTask(task);

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task dihapus')),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal menghapus task'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
      ),
    );
  }
}
Catatan Perubahan dari P9

P9: initState memanggil loadTasks() (online-only ke Supabase) [1]. P10: memanggil loadTasksOfflineFirst() yang membaca dari SQLite lalu sync ke server.
AppBar sekarang menampilkan:
Subtitle status (Memuat data lokal, Sinkronisasi, X task belum tersinkron, Semua data tersinkron).
Ikon status cloud: cloud_done, cloud_off, atau sync tergantung isSyncing dan unsyncedCount.
TaskCard menambahkan indikator kecil offline_bolt dan teks “Belum terkirim ke server” untuk task yang isSynced == false.
Dengan Praktikum 5 ini, mahasiswa bisa melihat langsung efek offline-first: data tetap muncul tanpa internet, ada indikator task yang belum tersinkron, dan tombol refresh memicu proses sinkronisasi ke Supabase [1].

Praktikum 6 – Simulasi Mode Offline
Untuk menguji konsep offline-first:

Jalankan aplikasi di emulator / device.
Login dan tambahkan beberapa tasks saat online (akan tersimpan di SQLite dan Supabase).
Matikan koneksi internet (Wi-Fi/seluler).
Buka kembali aplikasi → pastikan tasks masih muncul karena dibaca dari SQLite.
Tambah beberapa tasks baru saat offline → seharusnya tetap tersimpan di SQLite dengan isSynced = false.
Nyalakan kembali internet dan tekan tombol refresh/sync → periksa apakah tasks offline tadi ikut terkirim ke Supabase dan menjadi isSynced = true.
Langkah ini menutup loop: mahasiswa tidak hanya menulis kode, tapi menguji end-to-end behaviour offline-first.

Penugasan (Opsional)
Jika ingin memberi tugas mandiri, bisa diminta:

Menambahkan filter di TaskListScreen untuk hanya menampilkan tasks yang belum tersinkron.
Membuat tombol “Force Sync” yang memaksa mengirim semua unsynced tasks ke server.
Menambahkan timestamp lastSyncedAt di local DB dan menampilkan di UI.