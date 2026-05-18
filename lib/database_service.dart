import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/dashboard_state.dart';
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

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCacheTables(db);
    }
    if (oldVersion < 3) {
      await _ensureMealPlanColumns(db);
      await _recreateGalleryCacheTable(db);
    }
  }

  Future<void> _createCacheTables(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS cached_recipes (
  id TEXT PRIMARY KEY,
  data TEXT NOT NULL,
  synced_at TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS cached_challenges (
  id TEXT PRIMARY KEY,
  data TEXT NOT NULL,
  synced_at TEXT NOT NULL
)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS cached_content (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  data TEXT NOT NULL,
  synced_at TEXT NOT NULL
)
''');
    await _recreateGalleryCacheTable(db);
  }

  Future<void> _recreateGalleryCacheTable(Database db) async {
    await db.execute('DROP TABLE IF EXISTS cached_gallery');
    await db.execute('''
CREATE TABLE cached_gallery (
  id TEXT PRIMARY KEY,
  data TEXT NOT NULL,
  synced_at TEXT NOT NULL
)
''');
  }

  Future<void> _ensureMealPlanColumns(Database db) async {
    final cols = await db.rawQuery('PRAGMA table_info(meal_plans)');
    final names = cols.map((c) => c['name'] as String).toSet();
    if (!names.contains('meal_type')) {
      await db.execute(
        "ALTER TABLE meal_plans ADD COLUMN meal_type TEXT NOT NULL DEFAULT 'Dinner'",
      );
    }
    if (!names.contains('carbon_kg')) {
      await db.execute(
        'ALTER TABLE meal_plans ADD COLUMN carbon_kg REAL NOT NULL DEFAULT 0.0',
      );
    }
    if (!names.contains('is_custom')) {
      await db.execute(
        'ALTER TABLE meal_plans ADD COLUMN is_custom INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

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
  meal_type TEXT NOT NULL DEFAULT 'Dinner',
  carbon_kg REAL NOT NULL DEFAULT 0.0,
  is_custom INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
)
''');

    // Offline cache tables for Firestore data
    await db.execute('''
CREATE TABLE cached_recipes (
  id TEXT PRIMARY KEY,
  data TEXT NOT NULL,
  synced_at TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE cached_challenges (
  id TEXT PRIMARY KEY,
  data TEXT NOT NULL,
  synced_at TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE cached_content (
  id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  data TEXT NOT NULL,
  synced_at TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE cached_gallery (
  id TEXT PRIMARY KEY,
  data TEXT NOT NULL,
  synced_at TEXT NOT NULL
)
''');
  }

  Future<void> logCarbonActivity(
      String userId, String category, String? subcategory, double quantity) async {
    final db = await instance.database;

    final Map<String, double> emissionFactors = {
      'Car': 0.2,
      'Electricity': 0.5,
      'Meat meal': 2.5,
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

    double co2Saved = 0.0;
    double waterSaved = 0.0;
    double energySaved = 0.0;

    final cat = category.toLowerCase();
    final sub = subcategory?.toLowerCase() ?? '';

    if (cat == 'transport' || cat == 'mobility') {
      if (sub == 'bus' || sub == 'train') {
        co2Saved = quantity * 0.15;
        waterSaved = quantity * 0.05;
        energySaved = quantity * 0.2;
      } else if (sub == 'bike' || sub == 'walk') {
        co2Saved = quantity * 0.20;
        waterSaved = quantity * 0.1;
        energySaved = quantity * 0.3;
      }
    } else if (cat == 'car' || cat == 'electricity' || cat == 'meat meal') {
      co2Saved = 0;
      waterSaved = 0;
      energySaved = 0;
    } else {
      co2Saved = quantity * 0.1;
      waterSaved = quantity * 1.0;
      energySaved = quantity * 0.05;
    }

    await _syncTasksCompletedToCloud(
      userId,
      co2: co2Saved,
      water: waterSaved,
      energy: energySaved,
    );
  }

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

    double co2Saved = 0.0;
    double waterSaved = 0.0;
    double energySaved = 0.0;

    if (actionType == 'reusable_bottle') {
      co2Saved = quantity * 0.08;
      waterSaved = quantity * 3.0;
      energySaved = quantity * 0.15;
    } else if (actionType == 'compost') {
      co2Saved = quantity * 0.25;
      waterSaved = quantity * 5.0;
      energySaved = quantity * 0.05;
    } else if (actionType == 'recycle_can') {
      co2Saved = quantity * 0.12;
      waterSaved = quantity * 1.2;
      energySaved = quantity * 0.95;
    } else if (actionType == 'reusable_bag') {
      co2Saved = quantity * 0.5;
      waterSaved = quantity * 2.0;
      energySaved = quantity * 0.1;
    } else {
      co2Saved = quantity * 0.1;
      waterSaved = quantity * 1.5;
      energySaved = quantity * 0.08;
    }

    await _syncTasksCompletedToCloud(
      userId,
      co2: co2Saved,
      water: waterSaved,
      energy: energySaved,
    );
  }

  Future<void> _syncTasksCompletedToCloud(
    String userId, {
    double co2 = 0.0,
    double water = 0.0,
    double energy = 0.0,
  }) async {
    final streak = await getCurrentStreak(userId);
    await FirestoreService.instance.incrementTasksCompleted(
      userId,
      co2: co2,
      water: water,
      energy: energy,
      currentStreak: streak,
    );
  }

  Future<void> joinChallenge(String userId, String challengeId) async {
    final db = await instance.database;
    String date = DateTime.now().toIso8601String().split('T').first;

    await db.insert('user_challenge', {
      'user_id': userId,
      'challenge_id': challengeId,
      'date_joined': date,
    });
  }

  Future<void> updateChallengeProgress(
      int challengeRecordId, String newCompletedDaysJson) async {
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
    final carbonResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM carbon_log WHERE user_id = ?', [userId]);
    final wasteResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM waste_log WHERE user_id = ?', [userId]);

    int carbonCount = Sqflite.firstIntValue(carbonResult) ?? 0;
    int wasteCount = Sqflite.firstIntValue(wasteResult) ?? 0;

    return carbonCount + wasteCount;
  }

  Future<int> getCurrentStreak(String userId) async {
    final db = await instance.database;

    final carbonDates = await db.rawQuery(
        'SELECT DISTINCT date FROM carbon_log WHERE user_id = ?', [userId]);
    final wasteDates = await db.rawQuery(
        'SELECT DISTINCT date FROM waste_log WHERE user_id = ?', [userId]);

    Set<String> uniqueDates = {};
    for (var row in carbonDates) {
      if (row['date'] != null) uniqueDates.add(row['date'].toString());
    }
    for (var row in wasteDates) {
      if (row['date'] != null) uniqueDates.add(row['date'].toString());
    }

    List<String> sortedDates = uniqueDates.toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) return 0;

    DateTime today = DateTime.now();
    String todayStr = today.toIso8601String().split('T').first;
    String yesterdayStr = today
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')
        .first;

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

  // ── Meal planner (Module 4) ─────────────────────────────────────────────

  /// Saves a planned meal to local SQLite (`meal_plans` table).
  Future<void> addPlannedMeal(
    String userId,
    String date,
    String mealType,
    String recipeTitle, {
    double carbonKg = 0.0,
    bool isCustom = false,
  }) async {
    final db = await instance.database;
    final createdAt = DateTime.now().toIso8601String();

    await db.insert('meal_plans', {
      'user_id': userId,
      'date': date,
      'recipe_title': recipeTitle,
      'meal_type': mealType,
      'carbon_kg': carbonKg,
      'is_custom': isCustom ? 1 : 0,
      'created_at': createdAt,
    });
  }

  /// All meals for a single calendar day, ordered Breakfast → Lunch → Dinner.
  Future<List<Map<String, dynamic>>> getPlannedMealsForDate(
    String userId,
    String date,
  ) async {
    final db = await instance.database;

    final result = await db.rawQuery(
      '''
SELECT * FROM meal_plans
WHERE user_id = ? AND date = ?
ORDER BY
  CASE meal_type
    WHEN 'Breakfast' THEN 1
    WHEN 'Lunch' THEN 2
    WHEN 'Dinner' THEN 3
    ELSE 4
  END,
  id ASC
''',
      [userId, date],
    );

    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  /// Legacy helper — assigns a library recipe as Dinner.
  Future<int> insertMealPlan(String userId, String date, String recipeTitle) async {
    await addPlannedMeal(
      userId,
      date,
      'Dinner',
      recipeTitle,
      isCustom: false,
    );
    final db = await instance.database;
    final idResult = await db.rawQuery('SELECT last_insert_rowid() as id');
    return Sqflite.firstIntValue(idResult) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getMealPlans(String userId) async {
    final db = await instance.database;

    final result = await db.rawQuery(
      'SELECT * FROM meal_plans WHERE user_id = ? ORDER BY date ASC, id ASC',
      [userId],
    );

    return result.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<List<int>> getWeeklyActivity(String userId) async {
    final db = await instance.database;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final weeklyActivity = <int>[];

    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dayStr = day.toIso8601String().split('T').first;

      if (day.isAfter(now)) {
        weeklyActivity.add(-1);
        continue;
      }

      final carbonResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM carbon_log WHERE user_id = ? AND date = ?',
        [userId, dayStr],
      );
      final carbonCount = Sqflite.firstIntValue(carbonResult) ?? 0;

      final wasteResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM waste_log WHERE user_id = ? AND date = ?',
        [userId, dayStr],
      );
      final wasteCount = Sqflite.firstIntValue(wasteResult) ?? 0;

      final challengeResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM user_challenge WHERE user_id = ? AND date_joined = ?',
        [userId, dayStr],
      );
      final challengeCount = Sqflite.firstIntValue(challengeResult) ?? 0;

      final mealResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM meal_plans WHERE user_id = ? AND date = ?',
        [userId, dayStr],
      );
      final mealCount = Sqflite.firstIntValue(mealResult) ?? 0;

      if (carbonCount > 0 ||
          wasteCount > 0 ||
          challengeCount > 0 ||
          mealCount > 0) {
        weeklyActivity.add(1);
      } else {
        weeklyActivity.add(0);
      }
    }

    return weeklyActivity;
  }

  Future<List<JourneyActivity>> getRecentActivities(
    String userId, {
    int limit = 5,
  }) async {
    final db = await instance.database;

    final carbonRows = await db.rawQuery(
      'SELECT category, subcategory, date, carbon_kg FROM carbon_log '
      'WHERE user_id = ? ORDER BY id DESC LIMIT ?',
      [userId, limit],
    );

    final wasteRows = await db.rawQuery(
      'SELECT action_type, date, waste_saved_kg FROM waste_log '
      'WHERE user_id = ? ORDER BY id DESC LIMIT ?',
      [userId, limit],
    );

    final List<Map<String, dynamic>> merged = [
      ...carbonRows.map((r) => {
            'title': _carbonLabel(r['category'] as String? ?? ''),
            'subtitle':
                '${_fmtDate(r['date'] as String? ?? '')} · Saved ${((r['carbon_kg'] as num?)?.toStringAsFixed(1) ?? '0.0')}kg CO₂',
            'iconName': _carbonIcon(r['category'] as String? ?? ''),
            'ts': r['date'] as String? ?? '',
          }),
      ...wasteRows.map((r) => {
            'title': _wasteLabel(r['action_type'] as String? ?? ''),
            'subtitle':
                '${_fmtDate(r['date'] as String? ?? '')} · Saved ${((r['waste_saved_kg'] as num?)?.toStringAsFixed(2) ?? '0.00')}kg waste',
            'iconName': _wasteIcon(r['action_type'] as String? ?? ''),
            'ts': r['date'] as String? ?? '',
          }),
    ];

    merged.sort((a, b) => (b['ts'] as String).compareTo(a['ts'] as String));
    final top = merged.take(limit).toList();

    return top
        .map((m) => JourneyActivity(
              title: m['title'] as String,
              subtitle: m['subtitle'] as String,
              iconName: m['iconName'] as String,
            ))
        .toList();
  }

  static String _fmtDate(String iso) {
    if (iso.isEmpty) return '';
    final today = DateTime.now().toIso8601String().split('T').first;
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')
        .first;
    if (iso == today) return 'Today';
    if (iso == yesterday) return 'Yesterday';
    return iso;
  }

  static String _carbonLabel(String cat) {
    const labels = {
      'Car': 'Drove by Car',
      'Electricity': 'Used Electricity',
      'Meat meal': 'Had a Meat Meal',
    };
    return labels[cat] ?? cat;
  }

  static String _carbonIcon(String cat) {
    const icons = {
      'Car': 'directions_walk',
      'Electricity': 'eco',
      'Meat meal': 'restaurant',
    };
    return icons[cat] ?? 'eco';
  }

  static String _wasteLabel(String action) {
    const labels = {
      'reusable_bottle': 'Used Reusable Bottle',
      'compost': 'Composted Organic Waste',
      'recycle_can': 'Recycled Aluminium Can',
    };
    return labels[action] ?? action;
  }

  static String _wasteIcon(String action) {
    const icons = {
      'reusable_bottle': 'eco',
      'compost': 'compost',
      'recycle_can': 'eco',
    };
    return icons[action] ?? 'eco';
  }
}
