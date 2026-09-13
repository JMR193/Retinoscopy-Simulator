import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_service.dart';

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

  // ─── Daily Study Reminders & Notifications ─────────────────────────────────
  static const String _dailyReminderKey = 'daily_reminder_enabled_v1';
  static const String _reminderHourKey = 'daily_reminder_hour_v1';
  static const String _reminderMinuteKey = 'daily_reminder_minute_v1';
  static const String _studyStreakKey = 'study_streak_count_v1';
  static const String _lastStudyDateKey = 'last_study_date_v1';

  static bool getDailyReminderEnabled() =>
      _prefs?.getBool(_dailyReminderKey) ?? (_memoryFallback[_dailyReminderKey] as bool?) ?? true;

  static Future<void> setDailyReminderEnabled(bool val) async {
    if (_prefs != null) {
      await _prefs!.setBool(_dailyReminderKey, val);
    } else {
      _memoryFallback[_dailyReminderKey] = val;
    }
  }

  static int getReminderHour() =>
      _prefs?.getInt(_reminderHourKey) ?? (_memoryFallback[_reminderHourKey] as int?) ?? 9;

  static int getReminderMinute() =>
      _prefs?.getInt(_reminderMinuteKey) ?? (_memoryFallback[_reminderMinuteKey] as int?) ?? 0;

  static Future<void> setReminderTime(int hour, int minute) async {
    if (_prefs != null) {
      await _prefs!.setInt(_reminderHourKey, hour);
      await _prefs!.setInt(_reminderMinuteKey, minute);
    } else {
      _memoryFallback[_reminderHourKey] = hour;
      _memoryFallback[_reminderMinuteKey] = minute;
    }
  }

  static int getStudyStreak() =>
      _prefs?.getInt(_studyStreakKey) ?? (_memoryFallback[_studyStreakKey] as int?) ?? 1;

  static Future<void> recordStudySession() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final lastDate = _prefs?.getString(_lastStudyDateKey) ?? (_memoryFallback[_lastStudyDateKey] as String?);

    bool isNewDay = false;
    int currentStreak = getStudyStreak();

    if (lastDate == null) {
      isNewDay = true;
      currentStreak = 1;
    } else if (lastDate != todayStr) {
      isNewDay = true;
      final lastDateTime = DateTime.tryParse(lastDate);
      if (lastDateTime != null && now.difference(lastDateTime).inDays == 1) {
        currentStreak += 1;
      } else if (lastDateTime != null && now.difference(lastDateTime).inDays > 1) {
        currentStreak = 1;
      }
    }

    if (isNewDay) {
      if (_prefs != null) {
        await _prefs!.setString(_lastStudyDateKey, todayStr);
        await _prefs!.setInt(_studyStreakKey, currentStreak);
      } else {
        _memoryFallback[_lastStudyDateKey] = todayStr;
        _memoryFallback[_studyStreakKey] = currentStreak;
      }

      // Give Daily Streak CME Bonus
      int xpBonus = 100 * currentStreak;
      if (currentStreak > 10) {
        xpBonus = 1000;
      }

      await addXp(xpBonus);
    }
  }

  // ─── Gamification: XP & Gems ─────────────────────────────────────────────────
  static const String _xpKey = 'user_xp_v1';
  static const String _gemsKey = 'user_gems_v1';

  static int getXp() =>
      _prefs?.getInt(_xpKey) ?? (_memoryFallback[_xpKey] as int?) ?? 0;

  static Future<void> addXp(int amount) async {
    final current = getXp();
    if (_prefs != null) {
      await _prefs!.setInt(_xpKey, current + amount);
    } else {
      _memoryFallback[_xpKey] = current + amount;
    }
    CloudSyncService.syncLocalDataToCloud(getXp(), getGems(), getStudyStreak(), getUserName());
  }

  static int getGems() =>
      _prefs?.getInt(_gemsKey) ?? (_memoryFallback[_gemsKey] as int?) ?? 0;

  static Future<void> addGems(int amount) async {
    final current = getGems();
    if (_prefs != null) {
      await _prefs!.setInt(_gemsKey, current + amount);
    } else {
      _memoryFallback[_gemsKey] = current + amount;
    }
    CloudSyncService.syncLocalDataToCloud(getXp(), getGems(), getStudyStreak(), getUserName());
  }

  // ─── Gamification: Store & Cosmetics ───────────────────────────────────────
  static const String _unlockedCosmeticsKey = 'unlocked_cosmetics_v1';
  static const String _equippedCosmeticKey = 'equipped_cosmetic_v1';

  static List<String> getUnlockedCosmetics() =>
      _prefs?.getStringList(_unlockedCosmeticsKey) ?? 
      (_memoryFallback[_unlockedCosmeticsKey] as List<String>?) ?? 
      ['Default Orange'];

  static Future<void> unlockCosmetic(String name) async {
    final current = getUnlockedCosmetics();
    if (!current.contains(name)) {
      current.add(name);
      if (_prefs != null) {
        await _prefs!.setStringList(_unlockedCosmeticsKey, current);
      } else {
        _memoryFallback[_unlockedCosmeticsKey] = current;
      }
    }
  }

  static String getEquippedCosmetic() =>
      _prefs?.getString(_equippedCosmeticKey) ?? 
      (_memoryFallback[_equippedCosmeticKey] as String?) ?? 
      'Default Orange';

  static Future<void> equipCosmetic(String name) async {
    if (_prefs != null) {
      await _prefs!.setString(_equippedCosmeticKey, name);
    } else {
      _memoryFallback[_equippedCosmeticKey] = name;
    }
  }

  // ─── Clinical Preferences & Accelerometer Settings ───────────────────────
  static const String _accelerometerTiltKey = 'accelerometer_tilt_enabled_v1';
  static const String _sphereStepKey = 'pref_sphere_step_v1';
  static const String _cylinderStepKey = 'pref_cylinder_step_v1';
  static const String _axisStepKey = 'pref_axis_step_v1';
  static const String _liveNeutralityKey = 'pref_live_neutrality_v1';

  /// Accelerometer Tilt Parallax: Default FALSE for steady clinical sweeps
  static bool isAccelerometerTiltEnabled() =>
      _prefs?.getBool(_accelerometerTiltKey) ??
      (_memoryFallback[_accelerometerTiltKey] as bool?) ??
      false;

  static Future<void> setAccelerometerTiltEnabled(bool value) async {
    if (_prefs != null) {
      await _prefs!.setBool(_accelerometerTiltKey, value);
    } else {
      _memoryFallback[_accelerometerTiltKey] = value;
    }
  }

  static double getSphereStep() =>
      _prefs?.getDouble(_sphereStepKey) ??
      (_memoryFallback[_sphereStepKey] as double?) ??
      0.25;

  static Future<void> setSphereStep(double value) async {
    if (_prefs != null) {
      await _prefs!.setDouble(_sphereStepKey, value);
    } else {
      _memoryFallback[_sphereStepKey] = value;
    }
  }

  static double getCylinderStep() =>
      _prefs?.getDouble(_cylinderStepKey) ??
      (_memoryFallback[_cylinderStepKey] as double?) ??
      0.25;

  static Future<void> setCylinderStep(double value) async {
    if (_prefs != null) {
      await _prefs!.setDouble(_cylinderStepKey, value);
    } else {
      _memoryFallback[_cylinderStepKey] = value;
    }
  }

  static double getAxisStep() =>
      _prefs?.getDouble(_axisStepKey) ??
      (_memoryFallback[_axisStepKey] as double?) ??
      5.0;

  static Future<void> setAxisStep(double value) async {
    if (_prefs != null) {
      await _prefs!.setDouble(_axisStepKey, value);
    } else {
      _memoryFallback[_axisStepKey] = value;
    }
  }

  static bool getShowLiveNeutralityFeedback() =>
      _prefs?.getBool(_liveNeutralityKey) ??
      (_memoryFallback[_liveNeutralityKey] as bool?) ??
      true;

  static Future<void> setShowLiveNeutralityFeedback(bool value) async {
    if (_prefs != null) {
      await _prefs!.setBool(_liveNeutralityKey, value);
    } else {
      _memoryFallback[_liveNeutralityKey] = value;
    }
  }

  // ─── Offline Clinical Guest Mode ──────────────────────────────────────────
  static const String _guestModeKey = 'guest_mode_enabled_v1';

  static bool isGuestMode() =>
      _prefs?.getBool(_guestModeKey) ??
      (_memoryFallback[_guestModeKey] as bool?) ??
      false;

  static Future<void> setGuestMode(bool value) async {
    if (_prefs != null) {
      await _prefs!.setBool(_guestModeKey, value);
    } else {
      _memoryFallback[_guestModeKey] = value;
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

