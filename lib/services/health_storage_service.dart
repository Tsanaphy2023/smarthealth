import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_interval_record.dart';

class HealthStorageService {
  static const String _keyDailyGoal = 'health_step_goal';
  static const String _keySavedStepsPrefix = 'health_steps_';
  static const String _keyIntervalHistory = 'health_interval_history_v2';
  static const String _keyTargetWeight = 'health_target_weight';
  static const String _keyTargetCalorieDeficit = 'health_target_calorie_deficit';
  static const String _keySedentaryAlertMinutes = 'health_sedentary_alert_minutes';
  static const String _keyDailyWaterGoal = 'health_daily_water_goal';
  static const String _keyVoiceAlertEnabled = 'health_voice_alert_enabled';

  // Profile keys
  static const String _keyProfileWeight = 'health_profile_weight';
  static const String _keyProfileHeight = 'health_profile_height';
  static const String _keyProfileAge = 'health_profile_age';
  static const String _keyProfileGender = 'health_profile_gender';

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
    final dateKey = '$_keySavedStepsPrefix${date.year}_${date.month}_${date.day}';
    return prefs.getInt(dateKey) ?? 0;
  }

  static Future<void> saveStepsForDate(DateTime date, int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = '$_keySavedStepsPrefix${date.year}_${date.month}_${date.day}';
    await prefs.setInt(dateKey, steps);
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
    // เพิ่มข้อมูลใหม่ด้านหน้า จำกัดไม่เกิน 50 รายการล่าสุด
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
    return prefs.getInt(_keySedentaryAlertMinutes) ?? 30; // ค่าเริ่มต้น 30 นาที
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
}
