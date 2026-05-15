import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();

  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('carbon_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Task 1: Schema Design
  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE carbon_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  date TEXT NOT NULL,
  category TEXT NOT NULL,
  subcategory TEXT,
  quantity REAL NOT NULL,
  carbon_kg REAL NOT NULL
)
''');

    await db.execute('''
CREATE TABLE waste_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  date TEXT NOT NULL,
  action_type TEXT NOT NULL,
  quantity INTEGER DEFAULT 1,
  waste_saved_kg REAL
)
''');

    await db.execute('''
CREATE TABLE user_challenge (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  challenge_id TEXT NOT NULL,
  date_joined TEXT,
  completed_days TEXT,
  is_completed INTEGER DEFAULT 0
)
''');
  }

  // Task 2: Tracking Logic
  Future<void> logCarbonActivity(
      String userId, String category, String? subcategory, double quantity) async {
    final db = await instance.database;

    // Predefined map of emission factors
    final Map<String, double> emissionFactors = {
      'Car': 0.2, // kg/km
      'Electricity': 0.5, // kg/kWh
      'Meat meal': 2.5, // kg/meal
    };

    double factor = emissionFactors[category] ?? 
                    (subcategory != null ? (emissionFactors[subcategory] ?? 0.0) : 0.0);
    double carbonKg = quantity * factor;
    String date = DateTime.now().toIso8601String().split('T').first;

    await db.insert('carbon_log', {
      'user_id': userId,
      'date': date,
      'category': category,
      'subcategory': subcategory,
      'quantity': quantity,
      'carbon_kg': carbonKg,
    });
  }

  // Task 3: Data Retrieval
  Future<double> getDailyCarbonTotal(String userId, String date) async {
    final db = await instance.database;

    final result = await db.rawQuery(
      'SELECT SUM(carbon_kg) as total FROM carbon_log WHERE user_id = ? AND date = ?',
      [userId, date],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    } else {
      return 0.0;
    }
  }

  // Waste Tracking Logic
  Future<void> logWasteAction(String userId, String actionType, int quantity) async {
    final db = await instance.database;

    final Map<String, double> wasteEstimates = {
      'reusable_bottle': 0.02,
      'compost': 0.5,
      'recycle_can': 0.015,
    };

    double wasteSavedKg = (wasteEstimates[actionType] ?? 0.0) * quantity;
    String date = DateTime.now().toIso8601String().split('T').first;

    await db.insert('waste_log', {
      'user_id': userId,
      'date': date,
      'action_type': actionType,
      'quantity': quantity,
      'waste_saved_kg': wasteSavedKg,
    });
  }

  // Challenge Tracking Logic
  Future<void> joinChallenge(String userId, String challengeId) async {
    final db = await instance.database;
    String date = DateTime.now().toIso8601String().split('T').first;

    await db.insert('user_challenge', {
      'user_id': userId,
      'challenge_id': challengeId,
      'date_joined': date,
    });
  }

  Future<void> updateChallengeProgress(int challengeRecordId, String newCompletedDaysJson) async {
    final db = await instance.database;

    await db.update(
      'user_challenge',
      {'completed_days': newCompletedDaysJson},
      where: 'id = ?',
      whereArgs: [challengeRecordId],
    );
  }

  Future<int> getTasksCompleted(String userId) async {
    final db = await instance.database;
    final carbonResult = await db.rawQuery('SELECT COUNT(*) as count FROM carbon_log WHERE user_id = ?', [userId]);
    final wasteResult = await db.rawQuery('SELECT COUNT(*) as count FROM waste_log WHERE user_id = ?', [userId]);
    
    int carbonCount = Sqflite.firstIntValue(carbonResult) ?? 0;
    int wasteCount = Sqflite.firstIntValue(wasteResult) ?? 0;
    
    return carbonCount + wasteCount;
  }

  Future<int> getCurrentStreak(String userId) async {
    final db = await instance.database;
    
    final carbonDates = await db.rawQuery('SELECT DISTINCT date FROM carbon_log WHERE user_id = ?', [userId]);
    final wasteDates = await db.rawQuery('SELECT DISTINCT date FROM waste_log WHERE user_id = ?', [userId]);
    
    Set<String> uniqueDates = {};
    for (var row in carbonDates) {
      if (row['date'] != null) uniqueDates.add(row['date'].toString());
    }
    for (var row in wasteDates) {
      if (row['date'] != null) uniqueDates.add(row['date'].toString());
    }
    
    List<String> sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));
    
    if (sortedDates.isEmpty) return 0;
    
    DateTime today = DateTime.now();
    String todayStr = today.toIso8601String().split('T').first;
    String yesterdayStr = today.subtract(const Duration(days: 1)).toIso8601String().split('T').first;
    
    int streak = 0;
    DateTime currentDateToMatch = today;
    
    if (sortedDates.first != todayStr && sortedDates.first != yesterdayStr) {
      return 0;
    }
    
    if (sortedDates.first == yesterdayStr) {
       currentDateToMatch = today.subtract(const Duration(days: 1));
    }
    
    for (String dateStr in sortedDates) {
      if (dateStr == currentDateToMatch.toIso8601String().split('T').first) {
        streak++;
        currentDateToMatch = currentDateToMatch.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }
}
