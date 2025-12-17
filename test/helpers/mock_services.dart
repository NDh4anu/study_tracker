// test/helpers/mock_services.dart

import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../lib/api/task_api.dart';
import '../../lib/local/task_local_db.dart';

// Annotate classes that need mocks
// Run: flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([
  TaskApiService,
  TaskLocalDb,
  http.Client,
  SharedPreferences,
  Database,
])
void main() {
  // This file only contains annotations for mockito
  // Run build_runner to generate the actual mock classes
}
