import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_health_tracker/main.dart';
import 'package:smart_health_tracker/models/activity_type.dart';
import 'package:smart_health_tracker/models/daily_health_metric.dart';
import 'package:smart_health_tracker/models/user_health_profile.dart';
import 'package:smart_health_tracker/services/movement_sensor_service.dart';
import 'package:smart_health_tracker/services/gps_tracking_service.dart';

void main() {
  group('Exercise Science & Biomechanics Tests', () {
    test('UserHealthProfile calculates BMR, BMI, and stride length correctly', () {
      const maleProfile = UserHealthProfile(
        weightKg: 70.0,
        heightCm: 175.0,
        age: 30,
        gender: Gender.male,
      );

      // BMI = 70 / (1.75 * 1.75) = 22.857
      expect(maleProfile.bmi, closeTo(22.86, 0.05));
      expect(maleProfile.bmiCategory, contains('Normal'));

      // BMR Male (Mifflin-St Jeor) = 10(70) + 6.25(175) - 5(30) + 5 = 700 + 1093.75 - 150 + 5 = 1648.75
      expect(maleProfile.bmrKcal, closeTo(1648.75, 0.1));

      // Base Stride Male = 175 * 0.414 / 100 = 0.7245 m
      expect(maleProfile.baseStrideLengthM, closeTo(0.7245, 0.001));

      // 10,000 steps distance = 10,000 * 0.7245 / 1000 = 7.245 km
      final distKm = maleProfile.calculateDistanceKm(10000, 1.0);
      expect(distKm, closeTo(7.245, 0.01));

      // Hydration loss for 10,000 steps at 0.5 intensity ~ 4,750 ml
      final sweatLoss = maleProfile.calculateHydrationLossMl(10000, 0.5);
      expect(sweatLoss, greaterThan(3500.0));
    });

    test('DailyHealthMetric cadence zones and progress ratio', () {
      final metric = DailyHealthMetric(
        steps: 8500,
        stepGoal: 10000,
        caloriesKcal: 382.5,
        distanceKm: 6.375,
        activeMinutes: 65,
        currentActivity: ActivityType.walking,
        motionIntensity: 0.45,
        date: DateTime.now(),
        cadenceSpm: 108, // Brisk walking
      );

      expect(metric.progressRatio, 0.85);
      expect(metric.progressPercent, 85);
      expect(metric.isBriskWalk, isTrue);
      expect(metric.isAerobicRunning, isFalse);
    });

    test('MovementSensorService manual steps and goals', () {
      final service = MovementSensorService();
      final initialSteps = service.todaySteps;
      service.addManualStep();
      expect(service.todaySteps, equals(initialSteps + 1));
      expect(service.currentActivity, equals(ActivityType.walking));
    });
  });

  testWidgets('SmartHealthTrackerApp boots and renders responsive layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MovementSensorService()),
          ChangeNotifierProvider(create: (_) => GpsTrackingService()),
        ],
        child: const SmartHealthTrackerApp(),
      ),
    );

    expect(find.byType(SmartHealthTrackerApp), findsOneWidget);
    expect(find.textContaining('HEALTH'), findsWidgets);
  });
}
