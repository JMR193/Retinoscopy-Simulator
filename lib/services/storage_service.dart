import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent storage service — JMR Technologies
/// Handles all SharedPreferences-backed data persistence for the Retinoscopy Simulator.
/// Completely crash-resilient with in-memory fallbacks.
class StorageService {
  static const String _historyKey = 'test_history_v2';
  static const String _userNameKey = 'user_name';
  static const String _workingDistKey = 'preferred_wd';
  static const String _themeColorKey = 'theme_color';
  static const String _darkModeKey = 'dark_mode_v1';
  static const String _firstLaunchKey = 'first_launch_done';
  static const String _totalTestsKey = 'total_tests';
  static const String _totalCorrectKey = 'total_correct';

  static SharedPreferences? _prefs;
  static final Map<String, dynamic> _memoryFallback = {};

  /// Must be called once at app startup (safe & non-blocking)
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // In-memory fallback if platform channel unavailable
      _prefs = null;
    }
  }

  // ─── Test History ──────────────────────────────────────────────────────────

  /// Save a new test history entry (prepended to list, max 100 entries)
  static Future<void> addHistoryEntry({
    required double sphere,
    required double cylinder,
    required double axis,
    required bool correct,
  }) async {
    final entries = getHistory();
    entries.insert(0, {
      'sphere': sphere,
      'cylinder': cylinder,
      'axis': axis,
      'correct': correct,
      'timestamp': DateTime.now().toIso8601String(),
    });
    // Keep only last 100 entries
    final trimmed = entries.take(100).toList();
    final jsonStr = jsonEncode(trimmed);
    
    if (_prefs != null) {
      await _prefs!.setString(_historyKey, jsonStr);
      int total = _prefs!.getInt(_totalTestsKey) ?? 0;
      int correct2 = _prefs!.getInt(_totalCorrectKey) ?? 0;
      await _prefs!.setInt(_totalTestsKey, total + 1);
      if (correct) {
        await _prefs!.setInt(_totalCorrectKey, correct2 + 1);
      }
    } else {
      _memoryFallback[_historyKey] = jsonStr;
      _memoryFallback[_totalTestsKey] = ((_memoryFallback[_totalTestsKey] as int?) ?? 0) + 1;
      if (correct) {
        _memoryFallback[_totalCorrectKey] = ((_memoryFallback[_totalCorrectKey] as int?) ?? 0) + 1;
      }
    }
  }

  /// Load all test history entries
  static List<Map<String, dynamic>> getHistory() {
    final raw = _prefs?.getString(_historyKey) ?? (_memoryFallback[_historyKey] as String?);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Clear all test history (GDPR compliance)
  static Future<void> clearHistory() async {
    if (_prefs != null) {
      await _prefs!.remove(_historyKey);
      await _prefs!.remove(_totalTestsKey);
      await _prefs!.remove(_totalCorrectKey);
    }
    _memoryFallback.remove(_historyKey);
    _memoryFallback.remove(_totalTestsKey);
    _memoryFallback.remove(_totalCorrectKey);
  }

  // ─── Statistics ────────────────────────────────────────────────────────────

  static int getTotalTests() =>
      _prefs?.getInt(_totalTestsKey) ?? (_memoryFallback[_totalTestsKey] as int?) ?? 0;

  static int getTotalCorrect() =>
      _prefs?.getInt(_totalCorrectKey) ?? (_memoryFallback[_totalCorrectKey] as int?) ?? 0;

  static double getAccuracyPercent() {
    final total = getTotalTests();
    if (total == 0) {
      return 0.0;
    }
    return (getTotalCorrect() / total) * 100.0;
  }

  // ─── User Profile ──────────────────────────────────────────────────────────

  static String getUserName() =>
      _prefs?.getString(_userNameKey) ?? (_memoryFallback[_userNameKey] as String?) ?? '';

  static Future<void> setUserName(String name) async {
    if (_prefs != null) {
      await _prefs!.setString(_userNameKey, name);
    } else {
      _memoryFallback[_userNameKey] = name;
    }
  }

  // ─── Preferences ──────────────────────────────────────────────────────────

  static double getPreferredWorkingDistance() =>
      _prefs?.getDouble(_workingDistKey) ?? (_memoryFallback[_workingDistKey] as double?) ?? 1.5;

  static Future<void> setPreferredWorkingDistance(double wd) async {
    if (_prefs != null) {
      await _prefs!.setDouble(_workingDistKey, wd);
    } else {
      _memoryFallback[_workingDistKey] = wd;
    }
  }

  static String getThemeColor() =>
      _prefs?.getString(_themeColorKey) ?? (_memoryFallback[_themeColorKey] as String?) ?? 'Blue';

  static Future<void> setThemeColor(String color) async {
    if (_prefs != null) {
      await _prefs!.setString(_themeColorKey, color);
    } else {
      _memoryFallback[_themeColorKey] = color;
    }
  }

  static bool isDarkMode() =>
      _prefs?.getBool(_darkModeKey) ?? (_memoryFallback[_darkModeKey] as bool?) ?? false;

  static Future<void> setDarkMode(bool val) async {
    if (_prefs != null) {
      await _prefs!.setBool(_darkModeKey, val);
    } else {
      _memoryFallback[_darkModeKey] = val;
    }
  }

  // ─── First Launch ──────────────────────────────────────────────────────────

  static bool isFirstLaunch() =>
      !(_prefs?.getBool(_firstLaunchKey) ?? (_memoryFallback[_firstLaunchKey] as bool?) ?? false);

  static Future<void> markFirstLaunchDone() async {
    if (_prefs != null) {
      await _prefs!.setBool(_firstLaunchKey, true);
    } else {
      _memoryFallback[_firstLaunchKey] = true;
    }
  }

  // ─── Simulator Feature Tour ───────────────────────────────────────────────
  static const String _simulatorTourKey = 'simulator_tour_seen_v1';

  static bool hasSeenSimulatorTour() =>
      _prefs?.getBool(_simulatorTourKey) ?? (_memoryFallback[_simulatorTourKey] as bool?) ?? false;

  static Future<void> markSimulatorTourSeen() async {
    if (_prefs != null) {
      await _prefs!.setBool(_simulatorTourKey, true);
    } else {
      _memoryFallback[_simulatorTourKey] = true;
    }
  }

  // ─── GDPR — Clear all data ─────────────────────────────────────────────────

  static Future<void> clearAllData() async {
    if (_prefs != null) {
      await _prefs!.clear();
    }
    _memoryFallback.clear();
  }
}
