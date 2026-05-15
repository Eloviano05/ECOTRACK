import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'services/firestore_service.dart';

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

    await db.execute('''
CREATE TABLE meal_plans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  date TEXT NOT NULL,
  recipe_title TEXT NOT NULL,
  created_at TEXT NOT NULL
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

    // Mock impact calculation for carbon logging
    final mockCo2 = carbonKg;
    final mockWater = 5.0; // 5L water saved per carbon action
    final mockEnergy = 0.5; // 0.5 kWh energy saved per carbon action

    await _syncTasksCompletedToCloud(
      userId,
      co2: mockCo2,
      water: mockWater,
      energy: mockEnergy,
    );
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

    // Mock impact calculation for waste logging
    final mockCo2 = wasteSavedKg * 0.5; // 0.5 kg CO2 saved per kg waste
    final mockWater = wasteSavedKg * 100.0; // 100L water saved per kg waste
    final mockEnergy = 0.2; // 0.2 kWh energy saved per waste action

    await _syncTasksCompletedToCloud(
      userId,
      co2: mockCo2,
      water: mockWater,
      energy: mockEnergy,
    );
  }

  Future<void> _syncTasksCompletedToCloud(
    String userId, {
    double co2 = 0.0,
    double water = 0.0,
    double energy = 0.0,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'tasksCompleted': FieldValue.increment(1),
        if (co2 > 0) 'co2Saved': FieldValue.increment(co2),
        if (water > 0) 'waterSaved': FieldValue.increment(water),
        if (energy > 0) 'energySaved': FieldValue.increment(energy),
      });
    } catch (_) {
      await FirestoreService.instance.incrementTasksCompleted(
        userId,
        co2: co2,
        water: water,
        energy: energy,
      );
    }
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

  // Meal Plan Methods
  Future<int> insertMealPlan(String userId, String date, String recipeTitle) async {
    final db = await instance.database;
    String createdAt = DateTime.now().toIso8601String();

    return await db.insert('meal_plans', {
      'user_id': userId,
      'date': date,
      'recipe_title': recipeTitle,
      'created_at': createdAt,
    });
  }

  Future<List<Map<String, dynamic>>> getMealPlans(String userId) async {
    final db = await instance.database;

    final result = await db.rawQuery(
      'SELECT * FROM meal_plans WHERE user_id = ? ORDER BY date ASC',
      [userId],
    );

    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  // Weekly Activity Time-Series
  Future<List<int>> getWeeklyActivity(String userId) async {
    final db = await instance.database;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    
    final weeklyActivity = <int>[];
    
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dayStr = day.toIso8601String().split('T').first;
      
      // Check if this day is in the future
      if (day.isAfter(now)) {
        weeklyActivity.add(-1); // Future day
        continue;
      }
      
      // Query carbon_log for this day
      final carbonResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM carbon_log WHERE user_id = ? AND date = ?',
        [userId, dayStr],
      );
      final carbonCount = Sqflite.firstIntValue(carbonResult) ?? 0;
      
      // Query waste_log for this day
      final wasteResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM waste_log WHERE user_id = ? AND date = ?',
        [userId, dayStr],
      );
      final wasteCount = Sqflite.firstIntValue(wasteResult) ?? 0;
      
      // Query user_challenge for this day (date_joined or completed_days containing this date)
      final challengeResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM user_challenge WHERE user_id = ? AND date_joined = ?',
        [userId, dayStr],
      );
      final challengeCount = Sqflite.firstIntValue(challengeResult) ?? 0;
      
      // If any activity was logged on this day, mark as completed
      if (carbonCount > 0 || wasteCount > 0 || challengeCount > 0) {
        weeklyActivity.add(1); // Completed
      } else {
        weeklyActivity.add(0); // Missed past day
      }
    }
    
    return weeklyActivity;
  }
}
