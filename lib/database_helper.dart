import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ecostep.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const realType = 'REAL NOT NULL';

    // 1. Carbon Footprint Tracker Table
    await db.execute('''
      CREATE TABLE carbon_logs (
        id $idType,
        user_id $textType,
        date $textType,
        activity_type $textType,
        value $realType,
        co2_emitted_kg $realType,
        notes $textNullableType
      )
    ''');

    // 2. Waste Reduction Tracker Table
    await db.execute('''
      CREATE TABLE waste_logs (
        id $idType,
        user_id $textType,
        date $textType,
        material_type $textType,
        weight_kg $realType,
        action_taken $textType,
        notes $textNullableType
      )
    ''');
  }

  // --- CARBON TRACKER CRUD ---

  Future<int> insertCarbonLog(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('carbon_logs', row);
  }

  Future<List<Map<String, dynamic>>> readAllCarbonLogs(String userId) async {
    final db = await instance.database;
    return await db.query(
      'carbon_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  // --- WASTE TRACKER CRUD ---

  Future<int> insertWasteLog(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('waste_logs', row);
  }

  Future<List<Map<String, dynamic>>> readAllWasteLogs(String userId) async {
    final db = await instance.database;
    return await db.query(
      'waste_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
