import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

import 'firestore_service.dart';
import '../database_service.dart';

/// Periodically syncs Firestore catalog data into SQLite for offline reads.
class OfflineSyncService {
  OfflineSyncService._();

  static final OfflineSyncService instance = OfflineSyncService._();

  Timer? _syncTimer;
  static const Duration _syncInterval = Duration(minutes: 30);

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final StreamController<void> _cacheUpdatedController =
      StreamController<void>.broadcast();

  /// Fires after a successful cache write (screens can refresh).
  Stream<void> get onCacheUpdated => _cacheUpdatedController.stream;

  static bool hasNetwork(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.any((r) => r != ConnectivityResult.none);
    }
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    return true;
  }

  Future<void> initialize() async {
    await _checkConnectivity();
    await _initialSync();
    _startPeriodicSync();

    Connectivity().onConnectivityChanged.listen((result) async {
      _isOnline = hasNetwork(result);
      if (_isOnline) {
        await syncNow();
      } else {
        _cacheUpdatedController.add(null);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = hasNetwork(result);
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) async {
      if (_isOnline) {
        await syncNow();
      }
    });
  }

  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> syncNow() async {
    if (!_isOnline) return;

    try {
      await Future.wait([
        _syncRecipes(),
        _syncChallenges(),
        _syncContent(),
        _syncGallery(),
      ]);
      _cacheUpdatedController.add(null);
    } catch (e) {
      // ignore: avoid_print
      print('Sync error: $e');
    }
  }

  Future<void> _initialSync() async {
    if (!_isOnline) return;
    try {
      await syncNow();
    } catch (e) {
      // ignore: avoid_print
      print('Initial sync error: $e');
    }
  }

  Future<void> _syncRecipes() async {
    try {
      final recipes = await FirestoreService.instance.getRecipes();
      final db = await DatabaseService.instance.database;

      await db.delete('cached_recipes');

      for (final recipe in recipes) {
        final id = recipe['id'] as String? ?? recipe['title'] as String? ?? '';
        if (id.isEmpty) continue;
        await db.insert(
          'cached_recipes',
          {
            'id': id,
            'data': jsonEncode(recipe),
            'synced_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error syncing recipes: $e');
    }
  }

  Future<void> _syncChallenges() async {
    try {
      final snapshot =
          await FirestoreService.instance.getActiveChallengesStream().first;

      final db = await DatabaseService.instance.database;
      await db.delete('cached_challenges');

      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        await db.insert(
          'cached_challenges',
          {
            'id': doc.id,
            'data': jsonEncode(data),
            'synced_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error syncing challenges: $e');
    }
  }

  Future<void> _syncContent() async {
    try {
      final content =
          await FirestoreService.instance.getEducationalContent('all');
      final db = await DatabaseService.instance.database;

      await db.delete('cached_content');

      for (final item in content) {
        final id = item['id'] as String? ?? item['title'] as String? ?? '';
        if (id.isEmpty) continue;
        await db.insert(
          'cached_content',
          {
            'id': id,
            'category': item['category'] as String? ?? '',
            'data': jsonEncode(item),
            'synced_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error syncing content: $e');
    }
  }

  Future<void> _syncGallery() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirestoreService.galleryCollection)
          .get();

      final db = await DatabaseService.instance.database;
      await db.delete('cached_gallery');

      for (final doc in snapshot.docs) {
        final payload = <String, dynamic>{
          ...doc.data(),
          'id': doc.id,
        };
        await db.insert(
          'cached_gallery',
          {
            'id': doc.id,
            'data': jsonEncode(payload),
            'synced_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error syncing gallery: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedRecipes() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('cached_recipes', orderBy: 'synced_at DESC');

    return result.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      data['id'] = row['id'] as String;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getCachedChallenges() async {
    final db = await DatabaseService.instance.database;
    final result =
        await db.query('cached_challenges', orderBy: 'synced_at DESC');

    return result.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      data['id'] = row['id'] as String;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getCachedContent({String? category}) async {
    final db = await DatabaseService.instance.database;

    final List<Map<String, dynamic>> result;
    if (category != null && category.isNotEmpty && category != 'all') {
      result = await db.query(
        'cached_content',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'synced_at DESC',
      );
    } else {
      result = await db.query('cached_content', orderBy: 'synced_at DESC');
    }

    return result.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      data['id'] = row['id'] as String;
      return data;
    }).toList();
  }

  Future<List<String>> getCachedGallery() async {
    final items = await getCachedGalleryItems();
    return items
        .map((e) => e['imageUrl'] as String? ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCachedGalleryItems() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('cached_gallery', orderBy: 'synced_at DESC');

    return result.map((row) {
      final dataStr = row['data'] as String?;
      if (dataStr != null && dataStr.isNotEmpty) {
        final data = jsonDecode(dataStr) as Map<String, dynamic>;
        data['id'] = row['id'] as String? ?? data['id'];
        return data;
      }
      // Legacy rows that only stored url
      final legacyUrl = row['url'] as String? ?? '';
      return <String, dynamic>{
        'id': legacyUrl,
        'imageUrl': legacyUrl,
        'title': 'Eco inspiration',
        'tag': 'nature',
      };
    }).toList();
  }

  Future<DateTime?> getLastSyncTime() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
      'SELECT MAX(synced_at) as last_sync FROM cached_recipes',
    );

    if (result.isNotEmpty && result.first['last_sync'] != null) {
      return DateTime.tryParse(result.first['last_sync'] as String);
    }
    return null;
  }

  Future<void> clearCache() async {
    final db = await DatabaseService.instance.database;
    await Future.wait([
      db.delete('cached_recipes'),
      db.delete('cached_challenges'),
      db.delete('cached_content'),
      db.delete('cached_gallery'),
    ]);
    _cacheUpdatedController.add(null);
  }
}
