import 'activity_type.dart';

class DailyHealthMetric {
  final int steps;
  final int stepGoal;
  final double caloriesKcal;
  final double distanceKm;
  final int activeMinutes;
  final ActivityType currentActivity;
  final double motionIntensity; // 0.0 to 1.0
  final DateTime date;

  // Health Science & Biomechanics Fields
  final int cadenceSpm; // Steps per minute
  final double hydrationLostMl; // Estimated sweat loss (ml)
  final int sedentaryMinutes; // Minutes of continuous inactivity
  final bool needsActiveBreak; // True if sedentary >= 60 mins
  final double tdeeKcal; // Total daily energy expenditure (BMR + Active)

  const DailyHealthMetric({
    required this.steps,
    required this.stepGoal,
    required this.caloriesKcal,
    required this.distanceKm,
    required this.activeMinutes,
    required this.currentActivity,
    required this.motionIntensity,
    required this.date,
    this.cadenceSpm = 0,
    this.hydrationLostMl = 0.0,
    this.sedentaryMinutes = 0,
    this.needsActiveBreak = false,
    this.tdeeKcal = 0.0,
  });

  /// Progress percentage (0.0 to 1.0+)
  double get progressRatio => stepGoal > 0 ? (steps / stepGoal) : 0.0;
  int get progressPercent => (progressRatio * 100).toInt();

  /// Is Cadence in the health-promoting Brisk Walking zone? (100 - 119 SPM)
  bool get isBriskWalk => cadenceSpm >= 100 && cadenceSpm < 120;

  /// Is Cadence in Aerobic / Running zone? (120+ SPM)
  bool get isAerobicRunning => cadenceSpm >= 120;

  DailyHealthMetric copyWith({
    int? steps,
    int? stepGoal,
    double? caloriesKcal,
    double? distanceKm,
    int? activeMinutes,
    ActivityType? currentActivity,
    double? motionIntensity,
    DateTime? date,
    int? cadenceSpm,
    double? hydrationLostMl,
    int? sedentaryMinutes,
    bool? needsActiveBreak,
    double? tdeeKcal,
  }) {
    return DailyHealthMetric(
      steps: steps ?? this.steps,
      stepGoal: stepGoal ?? this.stepGoal,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      distanceKm: distanceKm ?? this.distanceKm,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      currentActivity: currentActivity ?? this.currentActivity,
      motionIntensity: motionIntensity ?? this.motionIntensity,
      date: date ?? this.date,
      cadenceSpm: cadenceSpm ?? this.cadenceSpm,
      hydrationLostMl: hydrationLostMl ?? this.hydrationLostMl,
      sedentaryMinutes: sedentaryMinutes ?? this.sedentaryMinutes,
      needsActiveBreak: needsActiveBreak ?? this.needsActiveBreak,
      tdeeKcal: tdeeKcal ?? this.tdeeKcal,
    );
  }
}

class HourlyMovementRecord {
  final int hour; // 0 to 23
  final int steps;
  final double intensity;

  const HourlyMovementRecord({
    required this.hour,
    required this.steps,
    required this.intensity,
  });
}
