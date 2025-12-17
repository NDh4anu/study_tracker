/// App string constants
///
/// NOTE: Strings akan ditambahkan progressively seiring tutorial:
/// - P4-5: App identity & basic actions
/// - P5-7: Task feature strings
/// - P6: Form validation messages
/// - P9: Authentication strings
/// - P13: Dashboard strings
/// - P14: Profile & settings strings
class AppStrings {
  AppStrings._(); // Prevent instantiation

  // ==================== App Identity ====================
  static const String appName = 'StudyTracker';
  static const String appTagline = 'Kelola Progres Belajarmu';

  // ==================== Common Actions ====================
  // Used across the app for buttons, dialogs, etc.
  static const String loading = 'Memuat...';
  static const String retry = 'Coba Lagi';
  static const String cancel = 'Batal';
  static const String save = 'Simpan';
  static const String delete = 'Hapus';
  static const String ok = 'OK';

  // ==================== Task Feature Strings (P5) ====================
  static const String taskList = 'Daftar Tugas';
  static const String addTask = 'Tambah Tugas';
  static const String noTasks = 'Belum ada tugas';
  static const String noTasksDescription = 'Ketuk tombol + untuk menambah tugas belajar pertamamu';
  
  // Priority
  static const String priorityHigh = 'Tinggi';
  static const String priorityMedium = 'Sedang';
  static const String priorityLow = 'Rendah';
  
  // Status
  static const String statusCompleted = 'Selesai';
  static const String statusPending = 'Belum Selesai';
  static const String statusOverdue = 'Terlambat';
  
  // Actions
  static const String deleteTask = 'Hapus Tugas';
  static const String deleteConfirmation = 'Apakah kamu yakin ingin menghapus tugas ini?';
  static const String taskDeleted = 'Tugas berhasil dihapus';
  static const String undo = 'Urungkan';

  // ==================== Form Labels (P6) ====================
  static const String taskTitle = 'Judul Tugas';
  static const String taskDescription = 'Deskripsi';
  static const String taskDueDate = 'Tenggat Waktu';
  static const String taskCategory = 'Kategori';
  static const String taskPriority = 'Prioritas';
  static const String selectDate = 'Pilih Tanggal';
  static const String selectCategory = 'Pilih Kategori';

  // ==================== Validation Messages (P6) ====================
  static const String fieldRequired = 'Kolom ini wajib diisi';
  static const String titleMinLength = 'Judul minimal 3 karakter';
  static const String descriptionMinLength = 'Deskripsi minimal 10 karakter';
  static const String selectValidDate = 'Silakan pilih tanggal yang valid';
  static const String selectValidCategory = 'Silakan pilih kategori';

  // ==================== Success Messages (P6) ====================
  static const String taskCreated = 'Tugas berhasil dibuat';
  static const String taskUpdated = 'Tugas berhasil diperbarui';
  static const String draftSaved = 'Draft tersimpan';
  static const String draftLoaded = 'Draft dimuat';

  // ==================== Category Labels (P6) ====================
  static const String categoryStudy = 'Belajar';
  static const String categoryAssignment = 'Tugas';
  static const String categoryProject = 'Proyek';
  static const String categoryPersonal = 'Pribadi';

  // ==================== TODO: Additional Strings ====================
  // Will be added progressively in future tutorials:

  // TODO P9: Add authentication strings
  // static const String login = 'Login';
  // static const String register = 'Register';
  // etc...

  // TODO P13: Add dashboard & analytics strings
  // TODO P14: Add profile & settings strings
}
