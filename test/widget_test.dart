import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_health_tracker/main.dart';
import 'package:smart_health_tracker/models/activity_type.dart';
import 'package:smart_health_tracker/models/app_brand_edition.dart';
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

    test('MovementSensorService manual steps, sedentary alert, and goals', () {
      final service = MovementSensorService();
      final initialSteps = service.todaySteps;
      service.addManualStep();
      expect(service.todaySteps, equals(initialSteps + 1));
      expect(service.currentActivity, equals(ActivityType.walking));

      // Verify 30-minute sedentary alert trigger demo
      service.triggerSedentaryAlertDemo();
      expect(service.sedentaryMinutes, greaterThanOrEqualTo(service.sedentaryAlertMinutes));
      expect(service.needsActiveBreak, isTrue);

      service.dismissActiveBreak();
      expect(service.needsActiveBreak, isFalse);
    });

    test('GpsTrackingService layer modes and simulation route tracking', () {
      final gps = GpsTrackingService();
      expect(gps.mapLayerMode, equals(GpsMapLayerMode.satellite));
      gps.cycleMapLayerMode();
      expect(gps.mapLayerMode, equals(GpsMapLayerMode.street));
      gps.cycleMapLayerMode();
      expect(gps.mapLayerMode, equals(GpsMapLayerMode.cyberGrid));
      gps.cycleMapLayerMode();
      expect(gps.mapLayerMode, equals(GpsMapLayerMode.satellite));
    });

    test('Automatic 24-hour and user-scheduled step counting window works accurately', () async {
      final service = MovementSensorService();
      expect(service.isAutoTrackEnabled, isTrue);
      expect(service.isAuto24HourMode, isTrue);
      expect(service.isWithinScheduledWindow(DateTime(2026, 11, 11, 2, 30)), isTrue);

      await service.updateAutoScheduleSettings(
        autoTrackEnabled: true,
        auto24HourMode: false,
        startHour: 6,
        startMinute: 30,
        endHour: 21,
        endMinute: 0,
      );
      expect(service.formattedAutoStartTime, equals('06:30'));
      expect(service.formattedAutoEndTime, equals('21:00'));
      expect(service.isWithinScheduledWindow(DateTime(2026, 11, 11, 10, 15)), isTrue);
      expect(service.isWithinScheduledWindow(DateTime(2026, 11, 11, 4, 0)), isFalse);

      // Restore 24h continuous mode
      await service.updateAutoScheduleSettings(
        autoTrackEnabled: true,
        auto24HourMode: true,
      );
      expect(service.isAuto24HourMode, isTrue);
    });

    test('OKR Key Result 3.2 Faculty Database (64+ staff, 9 departments, 10M steps target) syncs accurately', () async {
      final service = MovementSensorService();
      final initialOkr = service.okrSummary;
      expect(initialOkr.totalStaffCount, greaterThanOrEqualTo(60));
      expect(initialOkr.departments.length, equals(9));
      expect(initialOkr.totalFacultySteps, greaterThan(3000000));

      await service.updateStaffOkrRegistration(
        staffId: 'SCI-001',
        fullName: 'ผศ.ดร.ชีวะ ทัศนา',
        department: 'สาขาวิชาฟิสิกส์',
        positionTitle: 'ผู้ช่วยศาสตราจารย์',
      );
      final updatedOkr = service.syncStepsToFacultyOkr();
      expect(updatedOkr.totalStaffCount, greaterThanOrEqualTo(64));
      expect(updatedOkr.progressPercent, greaterThan(30.0));
    });
  });

  testWidgets('SmartHealthTrackerApp renders without overflow across 320dp, 360dp, 768dp, and 1280dp viewports',
      (WidgetTester tester) async {
    final viewports = [
      const Size(320, 640), // Small mobile phone
      const Size(360, 800), // Standard Android phone
      const Size(768, 1024), // Tablet Portrait (Medium layout)
      const Size(1280, 900), // Web / Desktop (Expanded 3-column layout)
    ];

    for (final size in viewports) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MovementSensorService()),
            ChangeNotifierProvider(create: (_) => GpsTrackingService()),
          ],
          child: const SmartHealthTrackerApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SmartHealthTrackerApp), findsOneWidget);
      expect(find.textContaining('CHEWAPULSE XAI'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'No layout overflow at viewport $size');
    }

    // Test Dual-Brand switching (ChewaPulse xAI <-> SciRBRU Move+AI) and 4-Tab Bottom Navigation on narrow 320x640 viewport
    await tester.binding.setSurfaceSize(const Size(320, 640));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MovementSensorService()),
          ChangeNotifierProvider(create: (_) => GpsTrackingService()),
        ],
        child: const SmartHealthTrackerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Switch brand to SciRBRU Move+AI
    await tester.tap(find.text('SciRBRU Move+AI'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('SCIRBRU MOVE+AI'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'No overflow after switching to SciRBRU Move+AI');

    // Test Bottom Navigation Tabs 1, 2, 3
    await tester.tap(find.text('แผนที่ดาวเทียม'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull, reason: 'No overflow on Tab 1 (Satellite Map)');

    await tester.tap(find.text('สถิติ 7 วัน & AI'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('แนวโน้มสุขภาพย้อนหลัง 7 วัน'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'No overflow on Tab 2 (7-Day History & AI)');

    await tester.tap(find.text('โปรไฟล์'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull, reason: 'No overflow on Tab 3 (Profile & Brand)');

    // Return to Tab 0 and test ComprehensiveGoalsDialog on narrow 320x640 viewport
    await tester.tap(find.text('วันนี้'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ตั้งค่าเป้าหมายสุขภาพ'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'No overflow in ComprehensiveGoalsDialog tab 1');

    await tester.tap(find.text('ลดน้ำหนัก'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: 'No overflow in ComprehensiveGoalsDialog tab 2');

    await tester.tap(find.text('ระบบเตือนขยับ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: 'No overflow in ComprehensiveGoalsDialog tab 3');

    await tester.binding.setSurfaceSize(null);
  });
}
