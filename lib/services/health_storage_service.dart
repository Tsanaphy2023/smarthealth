import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_interval_record.dart';

class HealthStorageService {
  static const String _keyDailyGoal = 'health_step_goal';
  static const String _keySavedStepsPrefix = 'health_steps_';
  static const String _keyHourlyStepsPrefix = 'health_hourly_';
  static const String _keyActiveSecPrefix = 'health_active_sec_';
  static const String _keyIntervalHistory = 'health_interval_history_v2';
  static const String _keyTargetWeight = 'health_target_weight';
  static const String _keyTargetCalorieDeficit = 'health_target_calorie_deficit';
  static const String _keySedentaryAlertMinutes = 'health_sedentary_alert_minutes';
  static const String _keyDailyWaterGoal = 'health_daily_water_goal';
  static const String _keyVoiceAlertEnabled = 'health_voice_alert_enabled';
  static const String _keyBrandEditionIndex = 'health_brand_edition_index';

  // Automatic 24h & Scheduled Tracking keys (Shared with Android Native Foreground Service)
  static const String _keyAutoTrackEnabled = 'health_auto_track_enabled';
  static const String _keyAuto24HourMode = 'health_auto_24h_mode';
  static const String _keyAutoStartHour = 'health_auto_start_hour';
  static const String _keyAutoStartMinute = 'health_auto_start_minute';
  static const String _keyAutoEndHour = 'health_auto_end_hour';
  static const String _keyAutoEndMinute = 'health_auto_end_minute';

  // Profile keys
  static const String _keyProfileWeight = 'health_profile_weight';
  static const String _keyProfileHeight = 'health_profile_height';
  static const String _keyProfileAge = 'health_profile_age';
  static const String _keyProfileGender = 'health_profile_gender';

  static String dateKeyFor(DateTime date) => '${date.year}_${date.month}_${date.day}';

  static Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDailyGoal) ?? 10000;
  }

  static Future<void> setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyGoal, goal);
  }

  static Future<int> getSavedStepsForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final key = '$_keySavedStepsPrefix${dateKeyFor(date)}';
    return prefs.getInt(key) ?? 0;
  }

  static Future<void> saveStepsForDate(DateTime date, int steps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keySavedStepsPrefix${dateKeyFor(date)}';
      await prefs.setInt(key, steps);
    } catch (_) {}
  }

  static Future<Map<int, int>> getHourlyStepsForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final dKey = dateKeyFor(date);
      final Map<int, int> result = {};
      for (int h = 0; h < 24; h++) {
        final val = prefs.getInt('$_keyHourlyStepsPrefix${dKey}_$h') ?? 0;
        if (val > 0) {
          result[h] = val;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveHourlyStepsForDate(DateTime date, int hour, int steps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dKey = dateKeyFor(date);
      await prefs.setInt('$_keyHourlyStepsPrefix${dKey}_$hour', steps);
    } catch (_) {}
  }

  static Future<void> clearHourlyStepsForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dKey = dateKeyFor(date);
      for (int h = 0; h < 24; h++) {
        await prefs.setInt('$_keyHourlyStepsPrefix${dKey}_$h', 0);
      }
    } catch (_) {}
  }

  static Future<int> getActiveSecondsForDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final key = '$_keyActiveSecPrefix${dateKeyFor(date)}';
      return prefs.getInt(key) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> saveActiveSecondsForDate(DateTime date, int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyActiveSecPrefix${dateKeyFor(date)}';
      await prefs.setInt(key, seconds);
    } catch (_) {}
  }

  // === Automatic 24-Hour & Custom Schedule Settings ===
  static Future<bool> getAutoTrackEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoTrackEnabled) ?? true;
  }

  static Future<void> setAutoTrackEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoTrackEnabled, enabled);
  }

  static Future<bool> getAuto24HourMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAuto24HourMode) ?? true;
  }

  static Future<void> setAuto24HourMode(bool is24Hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAuto24HourMode, is24Hour);
  }

  static Future<int> getAutoStartHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAutoStartHour) ?? 6;
  }

  static Future<void> setAutoStartHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoStartHour, hour.clamp(0, 23));
  }

  static Future<int> getAutoStartMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAutoStartMinute) ?? 0;
  }

  static Future<void> setAutoStartMinute(int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoStartMinute, minute.clamp(0, 59));
  }

  static Future<int> getAutoEndHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAutoEndHour) ?? 22;
  }

  static Future<void> setAutoEndHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoEndHour, hour.clamp(0, 23));
  }

  static Future<int> getAutoEndMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAutoEndMinute) ?? 0;
  }

  static Future<void> setAutoEndMinute(int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoEndMinute, minute.clamp(0, 59));
  }

  static Future<void> saveUserProfile(double weightKg, double heightCm, int age, int genderIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyProfileWeight, weightKg);
    await prefs.setDouble(_keyProfileHeight, heightCm);
    await prefs.setInt(_keyProfileAge, age);
    await prefs.setInt(_keyProfileGender, genderIndex);
  }

  static Future<Map<String, dynamic>> getUserProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'weightKg': prefs.getDouble(_keyProfileWeight) ?? 65.0,
      'heightCm': prefs.getDouble(_keyProfileHeight) ?? 170.0,
      'age': prefs.getInt(_keyProfileAge) ?? 25,
      'gender': prefs.getInt(_keyProfileGender) ?? 0,
    };
  }

  // === 4-Hour Interval Records Storage ===
  static Future<List<HealthIntervalRecord>> getIntervalRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyIntervalHistory) ?? '';
    return HealthIntervalRecord.decodeList(str);
  }

  static Future<void> saveIntervalRecord(HealthIntervalRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getIntervalRecords();
    current.insert(0, record);
    if (current.length > 50) {
      current.removeRange(50, current.length);
    }
    await prefs.setString(_keyIntervalHistory, HealthIntervalRecord.encodeList(current));
  }

  // === Health & Weight Loss Goals Settings ===
  static Future<double> getTargetWeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTargetWeight) ?? 60.0;
  }

  static Future<void> setTargetWeight(double weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTargetWeight, weight);
  }

  static Future<int> getTargetCalorieDeficit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTargetCalorieDeficit) ?? 500;
  }

  static Future<void> setTargetCalorieDeficit(int kcal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTargetCalorieDeficit, kcal);
  }

  static Future<int> getSedentaryAlertMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySedentaryAlertMinutes) ?? 30;
  }

  static Future<void> setSedentaryAlertMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySedentaryAlertMinutes, minutes);
  }

  static Future<int> getDailyWaterGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDailyWaterGoal) ?? 2500;
  }

  static Future<void> setDailyWaterGoal(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyWaterGoal, ml);
  }

  static Future<bool> getVoiceAlertEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVoiceAlertEnabled) ?? true;
  }

  static Future<void> setVoiceAlertEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVoiceAlertEnabled, enabled);
  }

  static Future<int> getBrandEditionIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBrandEditionIndex) ?? 0;
  }

  static Future<void> setBrandEditionIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBrandEditionIndex, index);
  }
}
