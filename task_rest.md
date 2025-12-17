Pertemuan 9: REST API Integration & Server Authentication
Overview
Pertemuan ini membahas integrasi aplikasi Flutter dengan backend server menggunakan REST API. Mahasiswa akan meng-upgrade dari local authentication (P7) ke server-based authentication dengan Supabase, memahami HTTP protocol, dan mengimplementasikan CRUD operations via API.

Durasi: 3 jam (1 jam teori, 2 jam praktik)

Learning Outcomes
Setelah menyelesaikan pertemuan ini, mahasiswa diharapkan mampu:

Memahami konsep REST API dan HTTP protocol
Mengimplementasikan server authentication dengan JWT tokens
Melakukan CRUD operations melalui REST API
Handle error responses dari server dengan proper
Mengelola authentication state dengan token management
Konsep Teori
1. REST API Fundamentals
Apa itu REST API?

REST (Representational State Transfer) adalah architectural style untuk web services. REST API menggunakan HTTP protocol untuk komunikasi client-server.

HTTP Methods:

GET - Retrieve data (read)
POST - Create new resource
PUT/PATCH - Update existing resource
DELETE - Delete resource
HTTP Status Codes:

2xx Success

200 OK - Request berhasil
201 Created - Resource created successfully
204 No Content - Success tanpa response body
4xx Client Errors

400 Bad Request - Invalid request format
401 Unauthorized - Authentication required
403 Forbidden - Tidak punya akses
404 Not Found - Resource tidak ditemukan
422 Unprocessable Entity - Validation error
5xx Server Errors

500 Internal Server Error - Server error
503 Service Unavailable - Server down
Request Structure:

POST /api/tasks HTTP/1.1
Host: api.example.com
Content-Type: application/json
Authorization: Bearer <token>

{
  "title": "Learn REST API",
  "description": "Study HTTP protocol"
}
Response Structure:

HTTP/1.1 201 Created
Content-Type: application/json

{
  "id": 123,
  "title": "Learn REST API",
  "created_at": "2025-11-13T10:00:00Z"
}
2. JSON Data Format
JSON (JavaScript Object Notation) adalah format standar untuk data exchange di REST API.

JSON Types:

String: "hello"
Number: 42, 3.14
Boolean: true, false
Null: null
Object: {"key": "value"}
Array: [1, 2, 3]
Example Task Object:

{
  "id": 1,
  "title": "Complete assignment",
  "description": "Flutter REST API implementation",
  "category": "study",
  "priority": "high",
  "due_date": "2025-11-20",
  "completed": false,
  "user_id": "abc123"
}
3. Authentication dengan JWT
JWT (JSON Web Token) adalah token-based authentication standard.

JWT Structure:

header.payload.signature
Example:

eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0.
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
JWT Payload Example:

{
  "sub": "user-id-123",
  "email": "user@example.com",
  "exp": 1699999999,
  "iat": 1699996399
}
Authentication Flow:

User login dengan credentials (email/password)
Server validate credentials
Server generate JWT token
Client save token (SharedPreferences)
Client attach token di setiap API request
Server verify token dan process request
Token Management:

Access Token: Short-lived (1 hour), untuk API requests
Refresh Token: Long-lived (7 days), untuk refresh access token
Store tokens di SharedPreferences
Include token di Authorization header: Bearer <token>
4. Supabase Backend
Supabase adalah open-source Firebase alternative dengan PostgreSQL database.

Supabase REST API Endpoints:

Authentication:

POST /auth/v1/token?grant_type=password - Login
POST /auth/v1/signup - Register
POST /auth/v1/token?grant_type=refresh_token - Refresh token
POST /auth/v1/logout - Logout
Data Operations:

GET /rest/v1/{table}?select=* - Get all
GET /rest/v1/{table}?id=eq.{id} - Get by ID
POST /rest/v1/{table} - Create
PATCH /rest/v1/{table}?id=eq.{id} - Update
DELETE /rest/v1/{table}?id=eq.{id} - Delete
Required Headers:

{
  'apikey': 'your-supabase-publishable-key',
  'Authorization': 'Bearer your-access-token',
  'Content-Type': 'application/json',
}
5. Error Handling Strategies
Network Errors:

No internet connection
Timeout
DNS resolution failure
Server Errors:

400-499: Client side issues (validation, auth)
500-599: Server side issues
Handling Strategy:

Wrap API calls dalam try-catch
Check HTTP status code
Parse error response body
Show user-friendly error messages
Implement retry mechanism untuk network errors
Praktik: Implementasi Sederhana
Note: Praktik ini dimulai dari awal (fresh project) dan tidak bergantung pada chapter sebelumnya. Kita akan membuat aplikasi Flutter sederhana dengan CRUD tasks menggunakan Supabase backend.

Praktik 1: Setup Project & Dependencies
Step 1: Buat Flutter Project Baru

flutter create rest_api_demo
cd rest_api_demo
Step 2: Add Dependencies

Buka pubspec.yaml dan tambahkan:

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0                    # HTTP requests
  provider: ^6.0.5               # State management
  shared_preferences: ^2.2.0     # Local storage untuk token
  intl: ^0.18.1                  # Date formatting
Step 3: Setup Simplified Folder Structure

lib/
├── main.dart
├── api/
│   └── task_api.dart           # Single: HTTP + Auth + Task operations
├── models/
│   └── task.dart               # Simplified task model
├── providers/
│   └── task_provider.dart     # Basic state management
└── screens/
    ├── login_screen.dart       # Login UI
    ├── task_list_screen.dart   # Task list UI with CRUD
    └── add_task_screen.dart    # Add task UI
Praktik 2: Setup Supabase Backend
Step 1: Buat Supabase Project

Buka supabase.com
Sign up/Login → New project
Pilih organization → Create project
Tunggu project selesai dibuat
Step 2: Disable Email Confirmation

Di Supabase dashboard:

Authentication → Settings
Scroll ke Email Templates
Disable Confirm signup
Klik Save untuk menyimpan perubahan
Step 3: Create Simple Tasks Table

Setelah project ready, buka SQL Editor dan jalankan:

CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT DEFAULT '',
  completed BOOLEAN DEFAULT FALSE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS (Row Level Security)
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Policy: Users hanya bisa akses tasks mereka sendiri
CREATE POLICY "Users can view own tasks" ON tasks
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tasks" ON tasks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tasks" ON tasks
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tasks" ON tasks
  FOR DELETE USING (auth.uid() = user_id);
Step 4: Update Authentication Settings

Di Supabase dashboard:

Authentication → Settings
Enable confirmation untuk Email dan Phone (opsional)
Session Duration: Set ke 1 hour untuk security
Klik Save
Step 5: Get API Keys

Di Supabase dashboard:

Project Settings → API
Copy Project URL dan anon/public key
Note: Email confirmation akan dikirim saat user mendaftar, namun user tetap bisa login tanpa konfirmasi (sesuai dengan kebutuhan development). Untuk production, tambahkan validasi email verification.

Praktik 3: Single API Service
Step 1: Simplified Task Model

// lib/models/task.dart
class Task {
  final int? id;
  final String title;
  final String description;
  final bool completed;
  final String userId;
  final DateTime? createdAt;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.completed = false,
    required this.userId,
    this.createdAt,
  });

  // Convert to JSON untuk API requests
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'completed': completed,
      'user_id': userId,
    };
  }

  // Create from JSON untuk API responses
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      completed: json['completed'] ?? false,
      userId: json['user_id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
Step 2: Combined API Service (Auth + Tasks)

// lib/api/task_api.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class TaskApiService {
  // Ganti dengan Supabase project Anda
  static const String _baseUrl = 'https://xxxxxx.supabase.co';
  static const String _apiKey = 'xxxxxxxxx';

  String? _accessToken;

  // Build headers untuk API requests
  Map<String, String> _getHeaders({bool includeAuth = true, bool returnRepresentation = false}) {
    final headers = {
      'apikey': _apiKey,
      'Content-Type': 'application/json',
    };

    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    // For create operations, return the created record
    if (returnRepresentation) {
      headers['Prefer'] = 'return=representation';
    }

    return headers;
  }

  // === AUTHENTICATION ===

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
  Future<Map<String, dynamic>?> register(String email, String password) async {
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

  // === TASK OPERATIONS ===

  // Get all tasks for current user
  Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/rest/v1/tasks?select=*&order=created_at.desc'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
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
      final response = await http.post(
        Uri.parse('$_baseUrl/rest/v1/tasks'),
        headers: _getHeaders(returnRepresentation: true),
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 201) {
        // Handle empty response
        if (response.body.isEmpty) {
          // Return task with generated ID
          return Task(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: task.title,
            description: task.description,
            completed: false,
            userId: task.userId,
            createdAt: DateTime.now(),
          );
        }

        try {
          final data = jsonDecode(response.body);

          // Handle different response formats
          if (data is List && data.isNotEmpty) {
            return Task.fromJson(Map<String, dynamic>.from(data[0]));
          } else if (data is Map) {
            return Task.fromJson(Map<String, dynamic>.from(data));
          } else {
            return null;
          }
        } catch (parseError) {
          // If parsing fails, return basic task
          return Task(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: task.title,
            description: task.description,
            completed: false,
            userId: task.userId,
            createdAt: DateTime.now(),
          );
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
    if (task.id == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/rest/v1/tasks?id=eq.${task.id}'),
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
  Future<bool> deleteTask(int taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/rest/v1/tasks?id=eq.$taskId'),
        headers: _getHeaders(),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Delete task error: $e');
      return false;
    }
  }
}
Praktik 4: Simplified Provider
Step 1: Combined Provider (Auth + Tasks)

// lib/providers/task_provider.dart
import 'package:flutter/material.dart';

import '../api/task_api.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final TaskApiService _apiService;

  TaskProvider(this._apiService);

  // Auth state
  bool _isAuthenticated = false;
  bool _isAuthLoading = true;
  bool _isTaskLoading = false;
  String? _email;
  String? _userId;
  String? _errorMessage;

  // Task state
  List<Task> _tasks = [];

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isAuthLoading; // For backward compatibility
  bool get isAuthLoading => _isAuthLoading;
  bool get isTaskLoading => _isTaskLoading;
  String? get email => _email;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;
  List<Task> get tasks => _tasks;

  // Check saved session on app start
  Future<void> checkSession() async {
    _isAuthLoading = true;
    notifyListeners();

    final session = await _apiService.loadSession();
    if (session != null) {
      _isAuthenticated = true;
      _email = session['email'];
      _userId = session['userId'];
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
    _isAuthenticated = false;
    _email = null;
    _userId = null;
    _tasks = [];
    notifyListeners();
  }

  // === TASK OPERATIONS ===

  // Load all tasks
  Future<void> loadTasks() async {
    // Avoid multiple simultaneous loads
    if (_isTaskLoading && _tasks.isEmpty) return;

    _isTaskLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _apiService.getTasks();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat tasks';
    }

    _isTaskLoading = false;
    notifyListeners();
  }

  // Add new task
  Future<bool> addTask(String title, String description) async {
    if (_userId == null) return false;

    final task = Task(
      title: title,
      description: description,
      userId: _userId!,
    );

    final createdTask = await _apiService.createTask(task);

    if (createdTask != null) {
      _tasks.insert(0, createdTask);
      notifyListeners();
      return true;
    }

    _errorMessage = 'Gagal menambahkan task';
    notifyListeners();
    return false;
  }

  // Toggle task completion
  Future<bool> toggleTask(Task task) async {
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      completed: !task.completed,
      userId: task.userId,
      createdAt: task.createdAt,
    );

    final success = await _apiService.updateTask(updatedTask);

    if (success) {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      return true;
    }

    _errorMessage = 'Gagal mengupdate task';
    notifyListeners();
    return false;
  }

  // Delete task
  Future<bool> deleteTask(int taskId) async {
    final success = await _apiService.deleteTask(taskId);

    if (success) {
      _tasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
      return true;
    }

    _errorMessage = 'Gagal menghapus task';
    notifyListeners();
    return false;
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
Praktik 5: Simple UI Implementation
Step 1: Main App

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api/task_api.dart';
import 'providers/task_provider.dart';
import 'screens/login_screen.dart';
import 'screens/task_list_screen.dart';

void main() {
  // Initialize single API service
  final apiService = TaskApiService();

  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final taskProvider = TaskProvider(apiService);
        taskProvider.checkSession(); // Check saved session
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
      title: 'REST API Demo',
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
Step 2: Login Screen (Simplified)

// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final taskProvider = context.read<TaskProvider>();
    bool success;

    if (_isLogin) {
      success = await taskProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await taskProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.errorMessage ?? 'Terjadi kesalahan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email harus diisi';
                      }
                      if (!value.contains('@')) {
                        return 'Email tidak valid';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password harus diisi';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  if (taskProvider.isLoading)
                    CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: _submit,
                          child: Text(_isLogin ? 'Login' : 'Register'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() => _isLogin = !_isLogin);
                          },
                          child: Text(_isLogin
                              ? 'Belum punya akun? Register'
                              : 'Sudah punya akun? Login'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
Step 3: Task List Screen with Complete CRUD

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
        context.read<TaskProvider>().loadTasks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('My Tasks (${taskProvider.tasks.length})'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => taskProvider.loadTasks(),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
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
            taskProvider.loadTasks();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(TaskProvider taskProvider) {
    if (taskProvider.isTaskLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (taskProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(taskProvider.errorMessage!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => taskProvider.loadTasks(),
              child: Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (taskProvider.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada tasks', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Tap + untuk menambah task pertama'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: taskProvider.tasks.length,
      itemBuilder: (context, index) {
        final task = taskProvider.tasks[index];
        return TaskCard(task: task);
      },
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: task.completed
              ? null
              : (value) async {
                  final success =
                      await context.read<TaskProvider>().toggleTask(task);

                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal update task'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed ? Colors.grey : null,
          ),
        ),
        subtitle: task.description.isNotEmpty
            ? Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: task.completed
            ? Icon(Icons.check_circle, color: Colors.green)
            : PopupMenuButton(
                itemBuilder: (context) => [
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
                        title: Text('Hapus Task'),
                        content: Text('Yakin ingin menghapus task ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Hapus'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      final success = await context
                          .read<TaskProvider>()
                          .deleteTask(task.id!);

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Task dihapus')),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
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
Step 4: Add Task Screen (Simplified)

// lib/screens/add_task_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final taskProvider = context.read<TaskProvider>();

    final success = await taskProvider.addTask(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.errorMessage ?? 'Gagal menambah task'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title harus diisi';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 32),
                if (taskProvider.isLoading)
                  Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _saveTask,
                    child: Text('Add Task'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
Penjelasan Implementasi:

Single API Service: TaskApiService menggabungkan authentication dan task operations dalam satu class
Simplified Task Model: Hanya 5 fields essential (id, title, description, completed, userId)
Combined Provider: TaskProvider menghandle auth state dan task state dalam satu class
Complete CRUD UI:
✅ CREATE: AddTaskScreen dengan simple form
✅ READ: TaskListScreen menampilkan semua tasks
✅ UPDATE: Checkbox untuk toggle completed status
✅ DELETE: PopupMenuButton dengan konfirmasi dialog
Simple Error Handling: Basic try-catch dengan user-friendly messages
Authentication Flow: Login/Register dengan token persistence
Key Simplifications:
Dari 12+ file menjadi 5 file
Single API service untuk semua operations
Minimal task model tanpa complex fields
Basic UI tanpa fancy features
Straightforward error handling tanpa complex patterns
Educational Benefits:
Focus on REST API concepts tanpa architectural complexity
Complete CRUD demonstration dengan semua HTTP methods
Easy to understand codebase untuk beginners
Simple debugging dan troubleshooting
Best Practices
1. API Error Handling
✅ DO: Check status codes explicitly

if (response.statusCode == 200) {
  // Success
} else if (response.statusCode == 401) {
  // Unauthorized - redirect to login
} else if (response.statusCode >= 500) {
  // Server error - show retry option
}
2. Loading States
✅ DO: Show loading indicators

if (isLoading) {
  return Center(child: CircularProgressIndicator());
}
3. Token Management
✅ DO: Refresh expired tokens

Future<void> refreshToken() async {
  final prefs = await SharedPreferences.getInstance();
  final refreshToken = prefs.getString('refresh_token');

  if (refreshToken != null) {
    final result = await _apiClient.post(
      '/auth/v1/token?grant_type=refresh_token',
      {'refresh_token': refreshToken},
    );
    // Update access token
  }
}
4. Network Error Handling
✅ DO: Handle network errors gracefully

try {
  final response = await http.get(url);
} on SocketException {
  return 'No internet connection';
} on TimeoutException {
  return 'Request timeout';
} catch (e) {
  return 'Unexpected error: $e';
}
5. User Feedback
✅ DO: Show clear error messages

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(errorMessage),
    backgroundColor: Colors.red,
    action: SnackBarAction(
      label: 'Retry',
      onPressed: () => _retry(),
    ),
  ),
);
Common Pitfalls
1. Not Handling 401 Unauthorized
❌ WRONG: Ignore 401
if (response.statusCode == 200) {
  return data;
}
return null; // User tidak tahu kenapa gagal

✅ CORRECT: Handle 401 explicitly
if (response.statusCode == 401) {
  // Token expired - logout user
  await authProvider.logout();
  Navigator.pushReplacementNamed(context, '/login');
}
2. Blocking UI dengan Sync Calls
❌ WRONG:
final tasks = taskService.getAllTasks(); // Blocks UI!

✅ CORRECT:
final tasks = await taskService.getAllTasks(); // Async
3. Not Validating JSON Structure
❌ WRONG:
final task = Task.fromJson(json); // Crash jika structure berbeda

✅ CORRECT:
try {
  final task = Task.fromJson(json);
} catch (e) {
  return TaskResult.error('Invalid data format');
}
4. Hardcoding API Keys di Code
❌ WRONG:
const apiKey = 'sk_live_123abc...'; // Exposed di version control!

✅ CORRECT:
// Use environment variables atau config file yang di-gitignore
const apiKey = String.fromEnvironment('API_KEY');
Testing dengan Postman
Setup Postman Collection:

Login Request:
POST https://your-project.supabase.co/auth/v1/token?grant_type=password
Headers:
  apikey: your-publishable-key
  Content-Type: application/json
Body:
{
  "email": "user@example.com",
  "password": "password123"
}
Get Tasks:
GET https://your-project.supabase.co/rest/v1/tasks?select=*
Headers:
  apikey: your-publishable-key
  Authorization: Bearer <access_token>
Create Task:
POST https://your-project.supabase.co/rest/v1/tasks
Headers:
  apikey: your-publishable-key
  Authorization: Bearer <access_token>
  Content-Type: application/json
Body:
{
  "title": "Test task",
  "description": "Created from Postman",
  "category": "work",
  "priority": "high",
  "user_id": "your-user-id"
}
Tip: Save access token dari login response ke Postman environment variable untuk reuse.

Summary
Key Takeaways:

REST API menggunakan HTTP methods untuk CRUD operations
JWT tokens untuk authentication dan authorization
http package untuk HTTP requests di Flutter
JSON serialization dengan toJson/fromJson methods
Error handling untuk network, server, dan auth errors
Upgrade dari P7:

✅ P7: Local authentication (hardcoded credentials)
✅ P9: Server authentication (real login via API)
✅ P9: Online-only (require internet connection)
➡️ P10: Offline-first (local database + sync)
Resources
Official Documentation
http package
Supabase REST API Docs
JSON serialization in Flutter
Recommended Reading
Flutter in Action - Chapter 9: HTTP & REST APIs
RESTful Web APIs by Leonard Richardson
Practice Exercises
User Profile API

Implement GET user profile endpoint
Add update profile functionality
Handle avatar upload (coming in P12)
Search & Filter

Add search by title endpoint
Filter by category/priority
Implement sorting options
Error Recovery

Implement automatic retry for failed requests
Add request queuing untuk offline scenarios
Handle token refresh automatically