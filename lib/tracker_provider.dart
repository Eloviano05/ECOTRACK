import 'package:flutter/material.dart';
import 'database_helper.dart';

class TrackerProvider with ChangeNotifier {
  List<Map<String, dynamic>> _carbonLogs = [];
  List<Map<String, dynamic>> _wasteLogs = [];

  List<Map<String, dynamic>> get carbonLogs => _carbonLogs;
  List<Map<String, dynamic>> get wasteLogs => _wasteLogs;

  // --- Carbon Footprint Logic ---

  Future<void> fetchCarbonLogs(String userId) async {
    _carbonLogs = await DatabaseHelper.instance.readAllCarbonLogs(userId);
    notifyListeners();
  }

  Future<void> addCarbonLog({
    required String userId,
    required String date,
    required String activityType,
    required double value,
    required double co2Emitted,
    String? notes,
  }) async {
    final log = {
      'user_id': userId,
      'date': date,
      'activity_type': activityType,
      'value': value,
      'co2_emitted_kg': co2Emitted,
      'notes': notes,
    };
    await DatabaseHelper.instance.insertCarbonLog(log);
    await fetchCarbonLogs(userId); // Refresh list
  }

  // --- Waste Reduction Logic ---

  Future<void> fetchWasteLogs(String userId) async {
    _wasteLogs = await DatabaseHelper.instance.readAllWasteLogs(userId);
    notifyListeners();
  }

  Future<void> addWasteLog({
    required String userId,
    required String date,
    required String materialType,
    required double weightKg,
    required String actionTaken,
    String? notes,
  }) async {
    final log = {
      'user_id': userId,
      'date': date,
      'material_type': materialType,
      'weight_kg': weightKg,
      'action_taken': actionTaken,
      'notes': notes,
    };
    await DatabaseHelper.instance.insertWasteLog(log);
    await fetchWasteLogs(userId); // Refresh list
  }
}
