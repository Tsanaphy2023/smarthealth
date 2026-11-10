import 'package:flutter_test/flutter_test.dart';
import 'package:smart_health_tracker/models/activity_type.dart';
import 'package:smart_health_tracker/models/daily_health_metric.dart';
import 'package:smart_health_tracker/services/movement_sensor_service.dart';

void main() {
  group('Step Counter and Movement Health Tests', () {
    test('DailyHealthMetric calculations', () {
      final metric = DailyHealthMetric(
        steps: 6500,
        stepGoal: 10000,
        caloriesKcal: 292.5,
        distanceKm: 4.875,
        activeMinutes: 45,
        currentActivity: ActivityType.walking,
        motionIntensity: 0.35,
        date: DateTime.now(),
      );

      expect(metric.progressRatio, equals(0.65));
      expect(metric.progressPercent, equals(65));
      expect(metric.currentActivity.nameTh, contains('เดิน'));
      expect(metric.currentActivity.met, greaterThan(1.0));
    });

    test('MovementSensorService step accumulation and biometrics', () {
      final service = MovementSensorService();
      expect(service.dailyGoal, equals(10000));

      final initialSteps = service.todaySteps;
      service.addManualStep();

      expect(service.todaySteps, equals(initialSteps + 1));
      expect(service.caloriesKcal, greaterThan(0.0));
      expect(service.distanceKm, greaterThan(0.0));
    });

    test('ActivityType categorizations', () {
      expect(ActivityType.values.length, equals(4));
      expect(ActivityType.stationary.nameTh, contains('อยู่นิ่ง'));
      expect(ActivityType.running.nameTh, contains('วิ่ง'));
      expect(ActivityType.running.met, greaterThan(ActivityType.walking.met));
    });

    test('Fall detection state and dismissal in MovementSensorService', () {
      final service = MovementSensorService();
      expect(service.isFallWarningActive, isFalse);
      service.dismissFallWarning();
      expect(service.isFallWarningActive, isFalse);
    });
  });
}
