import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static final UserPreferences instance = UserPreferences._internal();

  UserPreferences._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;

  final ValueNotifier<String> userName = ValueNotifier<String>('Eco-Warrior');
  final ValueNotifier<String> userEmail = ValueNotifier<String>('');
  final ValueNotifier<String> avatarPath = ValueNotifier<String>('');
  final ValueNotifier<String> userGoal =
      ValueNotifier<String>('Become carbon neutral');
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);

  Future<void> init() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    final user = FirebaseAuth.instance.currentUser;
    var defaultName = 'Eco-Warrior';
    var defaultEmail = '';

    if (user != null) {
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        defaultName = user.displayName!.trim();
      }
      defaultEmail = user.email ?? '';
    }

    userName.value = _prefs!.getString('userName') ?? defaultName;
    userEmail.value = _prefs!.getString('userEmail') ?? defaultEmail;
    avatarPath.value = _prefs!.getString('avatarPath') ?? '';
    userGoal.value =
        _prefs!.getString('userGoal') ?? 'Become carbon neutral';
    notificationsEnabled.value =
        _prefs!.getBool('notificationsEnabled') ?? true;

    _initialized = true;

    // Cloud profile wins over stale local cache when already signed in.
    if (user != null) {
      await syncWithFirebase(user);
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  Future<void> setUserName(String name) async {
    await _ensureInitialized();
    await _prefs!.setString('userName', name);
    userName.value = name;
  }

  Future<void> setUserEmail(String email) async {
    await _ensureInitialized();
    await _prefs!.setString('userEmail', email);
    userEmail.value = email;
  }

  Future<void> setAvatarPath(String path) async {
    await _ensureInitialized();
    await _prefs!.setString('avatarPath', path);
    avatarPath.value = path;
  }

  Future<void> setUserGoal(String goal) async {
    await _ensureInitialized();
    await _prefs!.setString('userGoal', goal);
    userGoal.value = goal;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs!.setBool('notificationsEnabled', enabled);
    notificationsEnabled.value = enabled;
  }

  Future<void> clearAuth() async {
    await _ensureInitialized();
    await _prefs!.remove('userName');
    await _prefs!.remove('userEmail');
    await _prefs!.remove('avatarPath');
    await _prefs!.remove('userGoal');
    userName.value = 'Eco-Warrior';
    userEmail.value = '';
    avatarPath.value = '';
    userGoal.value = 'Become carbon neutral';
  }

  /// Overwrites local cache from Firebase Auth so UI matches the cloud profile.
  Future<void> syncWithFirebase([User? user]) async {
    await _ensureInitialized();

    user ??= FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cloudName = (user.displayName != null &&
            user.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : 'Eco-Warrior';
    final cloudAvatar = user.photoURL ?? '';

    userName.value = cloudName;
    avatarPath.value = cloudAvatar;

    await _prefs!.setString('userName', cloudName);
    await _prefs!.setString('avatarPath', cloudAvatar);

    if (user.email != null && user.email!.isNotEmpty) {
      userEmail.value = user.email!;
      await _prefs!.setString('userEmail', user.email!);
    }
  }
}
