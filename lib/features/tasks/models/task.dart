/// Task model untuk study tracking
/// 
/// Mendukung:
/// - Penyimpanan di Supabase (REST API) via toJson/fromJson
/// - Penyimpanan di SQLite (local DB) via toMap/fromMap
/// - Field lokal untuk UI (priority, status, category, dueDate)
class Task {
  // --- Field untuk SQLite (local DB) ---
  /// Primary key di SQLite, auto-increment.
  final int? localId;

  // --- Field untuk Supabase / server ---
  /// ID dari Supabase (kolom "id" di tabel tasks).
  final int? serverId;

  // --- Field domain utama (dipakai di lokal & server) ---
  final String title;
  final String description;
  final bool completed;
  final String userId;
  final DateTime? createdAt;

  // --- Field tambahan untuk UI (extended dari spec) ---
  final TaskPriority priority;
  final TaskCategory category;
  final DateTime? dueDate;

  // --- Status sinkronisasi ---
  /// Menandai apakah data ini sudah tersinkron ke server.
  final bool isSynced;

  Task({
    this.localId,
    this.serverId,
    required this.title,
    this.description = '',
    this.completed = false,
    this.userId = '',
    this.createdAt,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.personal,
    this.dueDate,
    this.isSynced = false,
  });

  /// Unique identifier for UI purposes (Dismissible keys, etc.)
  /// Prioritizes localId, then serverId, then hashCode
  String get id => localId?.toString() ?? serverId?.toString() ?? 'local_${hashCode.toString()}';

  /// Computed status berdasarkan completed dan dueDate
  TaskStatus get status {
    if (completed) return TaskStatus.completed;
    if (dueDate != null && dueDate!.isBefore(DateTime.now())) {
      return TaskStatus.overdue;
    }
    return TaskStatus.pending;
  }

  // ===================================================================
  // Konversi untuk REST API (Supabase)
  // ===================================================================

  /// Digunakan ketika mengirim data ke Supabase (body JSON).
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'description': description,
      'completed': completed,
      'user_id': userId,
      'priority': priority.name,
      'category': category.name,
      'due_date': dueDate?.toIso8601String(),
    };

    // Hanya include 'id' untuk update operation (bukan create)
    if (serverId != null) {
      json['id'] = serverId;
    }

    return json;
  }

  /// Digunakan ketika menerima response JSON dari Supabase.
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      serverId: json['id'] as int?,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      completed: (json['completed'] ?? false) as bool,
      userId: json['user_id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      priority: _parsePriority(json['priority']),
      category: _parseCategory(json['category']),
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString())
          : null,
    );
  }

  static TaskPriority _parsePriority(dynamic value) {
    if (value == null) return TaskPriority.medium;
    return TaskPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskPriority.medium,
    );
  }

  static TaskCategory _parseCategory(dynamic value) {
    if (value == null) return TaskCategory.personal;
    return TaskCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskCategory.personal,
    );
  }

  // ===================================================================
  // Konversi untuk SQLite (local DB)
  // ===================================================================

  /// Konversi Task ke Map untuk disimpan ke tabel SQLite.
  Map<String, dynamic> toMap() {
    return {
      'local_id': localId,
      'server_id': serverId,
      'title': title,
      'description': description,
      'completed': completed ? 1 : 0,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
      'priority': priority.name,
      'category': category.name,
      'due_date': dueDate?.toIso8601String(),
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
      priority: _parsePriority(map['priority']),
      category: _parseCategory(map['category']),
      dueDate: map['due_date'] != null
          ? DateTime.tryParse(map['due_date'].toString())
          : null,
      isSynced: (map['is_synced'] ?? 0) == 1,
    );
  }

  // ===================================================================
  // Helper copyWith
  // ===================================================================

  Task copyWith({
    int? localId,
    int? serverId,
    String? title,
    String? description,
    bool? completed,
    String? userId,
    DateTime? createdAt,
    TaskPriority? priority,
    TaskCategory? category,
    DateTime? dueDate,
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
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

enum TaskPriority {
  high,
  medium,
  low;

  String get displayName {
    switch (this) {
      case TaskPriority.high:
        return 'Tinggi';
      case TaskPriority.medium:
        return 'Sedang';
      case TaskPriority.low:
        return 'Rendah';
    }
  }
}

enum TaskStatus {
  completed,
  pending,
  overdue;

  String get displayName {
    switch (this) {
      case TaskStatus.completed:
        return 'Selesai';
      case TaskStatus.pending:
        return 'Belum Selesai';
      case TaskStatus.overdue:
        return 'Terlambat';
    }
  }
}

enum TaskCategory {
  study,
  assignment,
  project,
  personal;

  String get displayName {
    switch (this) {
      case TaskCategory.study:
        return 'Belajar';
      case TaskCategory.assignment:
        return 'Tugas';
      case TaskCategory.project:
        return 'Proyek';
      case TaskCategory.personal:
        return 'Pribadi';
    }
  }
}
