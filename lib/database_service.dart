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
}
