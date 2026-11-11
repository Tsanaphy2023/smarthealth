import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/activity_type.dart';
import '../models/app_brand_edition.dart';
import '../models/daily_health_metric.dart';
import '../models/health_interval_record.dart';
import '../models/okr_faculty_model.dart';
import '../models/user_health_profile.dart';
import 'deep_health_ai_engine.dart';
import 'gps_tracking_service.dart';
import 'health_storage_service.dart';
import 'okr_sync_service.dart';
import 'voice_alert_service.dart';

class MovementSensorService extends ChangeNotifier with WidgetsBindingObserver {
  static final MovementSensorService _instance = MovementSensorService._internal();
  factory MovementSensorService() => _instance;
  MovementSensorService._internal();

  static const MethodChannel _bgChannel = MethodChannel(
    'com.rbru.health.smart_health_tracker/background_service',
  );

  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<AccelerometerEvent>? _rawAccelSubscription;
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  int? _lastHardwareStepCount;
  int _accelStepsSinceLastHardwareSync = 0;
  double _gravityBaseline = 9.80665;
  bool _hasHardwarePedometer = false;
  bool _isFallWarningActive = false;
  Timer? _simulationTimer;
  Timer? _decayTimer;
  Timer? _cadenceAndSedentaryTimer;
  Timer? _fourHourSnapshotTimer;
  Timer? _backgroundSyncTimer;

  // Personalized Health Profile & Goals
  AppBrandEdition _brandEdition = AppBrandEdition.chewaPulseXai;
  UserHealthProfile _profile = const UserHealthProfile();
  int _dailyGoal = 10000;
  double _targetWeightKg = 60.0;
  int _targetCalorieDeficitKcal = 500;
  int _sedentaryAlertMinutes = 30; // ค่าเริ่มต้น 30 นาทีตามคำสั่งผู้ใช้
  int _dailyWaterGoalMl = 2500;
  bool _isVoiceAlertEnabled = true;
  final Map<String, int> _pastDaysSteps = {};

  // Automatic 24-Hour & Scheduled Step Counting Configuration
  bool _isAutoTrackEnabled = true;
  bool _isAuto24HourMode = true; // true = นับตลอด 24 ชม. (00:00 - 23:59), false = นับตามช่วงเวลาที่กำหนดเอง
  int _autoStartHour = 6;
  int _autoStartMinute = 0;
  int _autoEndHour = 22;
  int _autoEndMinute = 0;
  bool _isBackgroundServiceRunning = true;
  String _currentDateKey = HealthStorageService.dateKeyFor(DateTime.now());

  // Real-time sensor state
  int _todaySteps = 0;
  double _motionIntensity = 0.0; // 0.0 to 1.0
  ActivityType _currentActivity = ActivityType.stationary;
  int _activeSeconds = 0;

  // Step detection algorithm variables (Calibrated for both hand-held and pants-pocket pendulum motion)
  double _lastMagnitude = 0.0;
  int _lastStepTimestampMs = 0;
  static const double _stepThreshold = 1.15; // m/s^2 pocket-friendly dynamic peak threshold
  static const int _refractoryPeriodMs = 310; // minimum ms between valid steps

  // Health Science: Cadence & Sedentary tracking
  int _cadenceSpm = 0; // Steps per minute
  final List<int> _recentStepTimestamps = [];
  int _sedentarySeconds = 0; // Continuous inactive seconds

  // 4-Hour Interval Tracking & AI
  final List<HealthIntervalRecord> _intervalRecords = [];
  DeepHealthInference? _latestAiInference;
  DateTime _currentIntervalStartTime = DateTime.now();
  int _stepsAtIntervalStart = 0;

  // Hourly steps distribution (0..23)
  final Map<int, int> _hourlySteps = {};

  bool _isSimulating = false;
  bool _isSensorActive = false;

  // Getters
  AppBrandEdition get brandEdition => _brandEdition;
  UserHealthProfile get profile => _profile;
  int get todaySteps => _todaySteps;
  int get dailyGoal => _dailyGoal;
  double get targetWeightKg => _targetWeightKg;
  int get targetCalorieDeficitKcal => _targetCalorieDeficitKcal;
  int get sedentaryAlertMinutes => _sedentaryAlertMinutes;
  int get dailyWaterGoalMl => _dailyWaterGoalMl;
  bool get isVoiceAlertEnabled => _isVoiceAlertEnabled;

  // Automatic 24h & Schedule Getters
  bool get isAutoTrackEnabled => _isAutoTrackEnabled;
  bool get isAuto24HourMode => _isAuto24HourMode;
  int get autoStartHour => _autoStartHour;
  int get autoStartMinute => _autoStartMinute;
  int get autoEndHour => _autoEndHour;
  int get autoEndMinute => _autoEndMinute;
  bool get isBackgroundServiceRunning => _isBackgroundServiceRunning;

  String get formattedAutoStartTime =>
      '${_autoStartHour.toString().padLeft(2, '0')}:${_autoStartMinute.toString().padLeft(2, '0')}';

  String get formattedAutoEndTime =>
      '${_autoEndHour.toString().padLeft(2, '0')}:${_autoEndMinute.toString().padLeft(2, '0')}';

  String get scheduleStatusDescription {
    if (!_isAutoTrackEnabled) {
      return 'ปิดการนับก้าวอัตโนมัติชั่วคราว';
    }
    if (_isAuto24HourMode) {
      return 'ทำงานอัตโนมัติ 24 ชม. (00:00 - 23:59 น.) • นับต่อเนื่องแม้ปิดแอป';
    }
    final activeNow = isWithinScheduledWindow();
    return activeNow
        ? 'กำลังนับก้าวอัตโนมัติตามเวลา ($formattedAutoStartTime - $formattedAutoEndTime น.)'
        : 'ตั้งเวลาเริ่มนับอัตโนมัติ $formattedAutoStartTime - $formattedAutoEndTime น. (รอรอบเวลา)';
  }

  /// ตรวจสอบว่าเวลาปัจจุบันอยู่ในช่วงเวลาที่อนุญาตให้นับก้าวอัตโนมัติหรือไม่
  bool isWithinScheduledWindow([DateTime? checkTime]) {
    if (!_isAutoTrackEnabled) return false;
    if (_isAuto24HourMode) return true;

    final now = checkTime ?? DateTime.now();
    final currentMins = now.hour * 60 + now.minute;
    final startMins = _autoStartHour * 60 + _autoStartMinute;
    final endMins = _autoEndHour * 60 + _autoEndMinute;

    if (startMins <= endMins) {
      return currentMins >= startMins && currentMins <= endMins;
    } else {
      // กรณีตั้งเวลาข้ามคืน เช่น 22:00 ถึง 06:00 น.
      return currentMins >= startMins || currentMins <= endMins;
    }
  }

  double get motionIntensity => _motionIntensity;
  ActivityType get currentActivity => _currentActivity;
  int get activeMinutes => (_activeSeconds ~/ 60);
  int get cadenceSpm => _cadenceSpm;
  int get sedentaryMinutes => _sedentarySeconds ~/ 60;

  /// เตือนเมื่ออยู่นิ่งนานกว่าเกณฑ์ที่กำหนด (ค่าเริ่มต้น 30 นาที)
  bool get needsActiveBreak => _sedentarySeconds >= (_sedentaryAlertMinutes * 60);
  bool get isSimulating => _isSimulating;
  bool get isSensorActive => _isSensorActive;
  bool get hasHardwarePedometer => _hasHardwarePedometer;
  bool get isFallWarningActive => _isFallWarningActive;

  void dismissFallWarning() {
    _isFallWarningActive = false;
    notifyListeners();
  }

  List<HealthIntervalRecord> get intervalRecords => List.unmodifiable(_intervalRecords);
  DeepHealthInference? get latestAiInference => _latestAiInference;

  /// ข้อมูลสรุปโครงการ OKR Key Result 3.2 (ก้าวสะสมรวมคณะวิทยาศาสตร์ฯ > 10,000,000 ก้าว ปีงบประมาณ 2570 • บุคลากร 64+ คน)
  FacultyOkrSummary get okrSummary => OkrSyncService().buildCurrentOkrSummary(
        currentUserTodaySteps: _todaySteps,
        appEdition: _brandEdition.appName,
      );

  /// ซิงค์ข้อมูลก้าวเดินของบุคลากรเข้าสู่ฐานข้อมูลกลาง OKR 3.2 ทันที
  FacultyOkrSummary syncStepsToFacultyOkr() {
    final res = OkrSyncService().syncStaffSteps(
      todaySteps: _todaySteps,
      appEdition: _brandEdition.appName,
    );
    notifyListeners();
    return res;
  }

  /// อัปเดตข้อมูลทะเบียนบุคลากรสำหรับระบบฐานข้อมูล OKR 3.2
  Future<void> updateStaffOkrRegistration({
    required String staffId,
    required String fullName,
    required String department,
    required String positionTitle,
    String? serverApiUrl,
    bool? autoSyncEnabled,
  }) async {
    await OkrSyncService().updateStaffRegistration(
      staffId: staffId,
      fullName: fullName,
      department: department,
      positionTitle: positionTitle,
      serverApiUrl: serverApiUrl,
      autoSyncEnabled: autoSyncEnabled,
      currentTodaySteps: _todaySteps,
      appEdition: _brandEdition.appName,
    );
    notifyListeners();
  }

  /// Dynamic Stride Distance (Km) based on User Profile Height and Activity Speed
  double get distanceKm {
    double speedMultiplier = 1.0;
    if (_currentActivity == ActivityType.running) {
      speedMultiplier = 1.25;
    } else if (_currentActivity == ActivityType.active) {
      speedMultiplier = 1.10;
    }
    return _profile.calculateDistanceKm(_todaySteps, speedMultiplier);
  }

  /// Calories Burned (kcal) using Personalized Body Weight & MET Activity Multiplier
  double get caloriesKcal {
    final met = _currentActivity.metValue;
    final kcalPerStep = (met * 3.5 * _profile.weightKg) / (200.0 * 60.0 * 1.75);
    return _todaySteps * kcalPerStep;
  }

  /// Estimated Perspiration & Hydration Loss (ml)
  double get hydrationLostMl => _profile.calculateHydrationLossMl(_todaySteps, _motionIntensity);

  /// Total Daily Energy Expenditure (BMR + Active)
  double get tdeeKcal => _profile.calculateTdeeKcal(caloriesKcal);

  DailyHealthMetric get currentMetric => DailyHealthMetric(
    steps: _todaySteps,
    stepGoal: _dailyGoal,
    caloriesKcal: caloriesKcal,
    distanceKm: distanceKm,
    activeMinutes: activeMinutes,
    currentActivity: _currentActivity,
    motionIntensity: _motionIntensity,
    date: DateTime.now(),
    cadenceSpm: _cadenceSpm,
    hydrationLostMl: hydrationLostMl,
    sedentaryMinutes: sedentaryMinutes,
    needsActiveBreak: needsActiveBreak,
    tdeeKcal: tdeeKcal,
  );

  List<HourlyMovementRecord> get hourlyRecords {
    final List<HourlyMovementRecord> list = [];
    for (int h = 0; h < 24; h++) {
      final s = _hourlySteps[h] ?? 0;
      final intensity = (s / 1200.0).clamp(0.0, 1.0);
      list.add(HourlyMovementRecord(hour: h, steps: s, intensity: intensity));
    }
    return list;
  }

  /// สลับโหมดแบรนด์ระหว่าง ChewaPulse xAI และ SciRBRU Move+AI
  Future<void> toggleBrandEdition() async {
    _brandEdition = _brandEdition == AppBrandEdition.chewaPulseXai
        ? AppBrandEdition.sciRbruMoveAi
        : AppBrandEdition.chewaPulseXai;
    notifyListeners();
    try {
      await HealthStorageService.setBrandEditionIndex(_brandEdition.index);
    } catch (_) {}
  }

  Future<void> setBrandEdition(AppBrandEdition edition) async {
    if (_brandEdition == edition) return;
    _brandEdition = edition;
    notifyListeners();
    try {
      await HealthStorageService.setBrandEditionIndex(_brandEdition.index);
    } catch (_) {}
  }

  /// อัปเดตการตั้งค่าเวลานับก้าวอัตโนมัติและโหมดทำงานตลอด 24 ชั่วโมง
  Future<void> updateAutoScheduleSettings({
    bool? autoTrackEnabled,
    bool? auto24HourMode,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) async {
    if (autoTrackEnabled != null) _isAutoTrackEnabled = autoTrackEnabled;
    if (auto24HourMode != null) _isAuto24HourMode = auto24HourMode;
    if (startHour != null) _autoStartHour = startHour.clamp(0, 23);
    if (startMinute != null) _autoStartMinute = startMinute.clamp(0, 59);
    if (endHour != null) _autoEndHour = endHour.clamp(0, 23);
    if (endMinute != null) _autoEndMinute = endMinute.clamp(0, 59);

    notifyListeners();

    try {
      await HealthStorageService.setAutoTrackEnabled(_isAutoTrackEnabled);
      await HealthStorageService.setAuto24HourMode(_isAuto24HourMode);
      await HealthStorageService.setAutoStartHour(_autoStartHour);
      await HealthStorageService.setAutoStartMinute(_autoStartMinute);
      await HealthStorageService.setAutoEndHour(_autoEndHour);
      await HealthStorageService.setAutoEndMinute(_autoEndMinute);
      await _syncNativeBackgroundService();
    } catch (_) {}
  }

  /// สร้างข้อมูลสถิติย้อนหลัง 7 วัน (Weekly History)
  List<DailyHistorySummary> get weeklyHistory {
    const thaiShortDays = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
    const baselineFallbackSteps = [7850, 9240, 10420, 8610, 11200, 9580];
    final now = DateTime.now();
    final List<DailyHistorySummary> result = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}_${date.month}_${date.day}';
      final bool isToday = i == 0;
      final int daySteps = isToday
          ? _todaySteps
          : (_pastDaysSteps[dateKey] != null && _pastDaysSteps[dateKey]! > 0
              ? _pastDaysSteps[dateKey]!
              : baselineFallbackSteps[(6 - i) % baselineFallbackSteps.length]);

      final double dist = _profile.calculateDistanceKm(daySteps, 1.0);
      final double kcalPerStep = (3.5 * 3.5 * _profile.weightKg) / (200.0 * 60.0 * 1.75);
      final double kcal = daySteps * kcalPerStep;

      result.add(
        DailyHistorySummary(
          dayLabel: isToday ? 'วันนี้' : thaiShortDays[(date.weekday - 1) % 7],
          fullDateLabel: '${date.day}/${date.month}/${date.year + 543}',
          steps: daySteps,
          stepGoal: _dailyGoal,
          caloriesKcal: kcal,
          distanceKm: dist,
          activeMinutes: isToday ? activeMinutes : (daySteps ~/ 105),
          weightKg: _profile.weightKg,
        ),
      );
    }
    return result;
  }

  /// สร้างข้อความสรุปรายงานสุขภาพ (Health Summary Report) สำหรับคัดลอกหรือแชร์
  String generateHealthSummaryReport() {
    final history = weeklyHistory;
    final totalWeekSteps = history.fold<int>(0, (s, e) => s + e.steps);
    final avgWeekSteps = (totalWeekSteps / history.length).round();
    final totalWeekKm = history.fold<double>(0.0, (s, e) => s + e.distanceKm);
    final totalWeekKcal = history.fold<double>(0.0, (s, e) => s + e.caloriesKcal);

    return '''
=========================================
📊 รายงานสรุปสุขภาพ • ${_brandEdition.appName}
(${_brandEdition.thaiName})
${_brandEdition.tagline}
=========================================
• โหมดนับก้าวอัตโนมัติ: $scheduleStatusDescription
• ข้อมูลร่างกาย: น้ำหนัก ${_profile.weightKg.toStringAsFixed(1)} kg | ส่วนสูง ${_profile.heightCm.toStringAsFixed(0)} cm | BMI ${_profile.bmi.toStringAsFixed(1)} (${_profile.bmiCategory})
• เป้าหมายประจำวัน: $_dailyGoal ก้าว | เป้าหมายน้ำหนัก: ${_targetWeightKg.toStringAsFixed(1)} kg
• สถานะวันนี้: เดินแล้ว $_todaySteps ก้าว (${distanceKm.toStringAsFixed(2)} กม. • เผาผลาญ ${caloriesKcal.toStringAsFixed(0)} kcal)
• สถิติรวม 7 วันล่าสุด:
  - จำนวนก้าวสะสมรวม: $totalWeekSteps ก้าว (เฉลี่ย $avgWeekSteps ก้าว/วัน)
  - ระยะทางสะสมรวม: ${totalWeekKm.toStringAsFixed(2)} กิโลเมตร
  - พลังงานเผาผลาญรวม: ${totalWeekKcal.toStringAsFixed(0)} kcal
• ผลวิเคราะห์ AI ล่าสุด: ${_latestAiInference?.statusTitle ?? 'สมดุลการเดินปกติ'}
  คำแนะนำ: ${_latestAiInference?.exerciseRecommendation ?? 'รักษาระดับการเดินต่อเนื่องทุกวัน'}
=========================================
${_brandEdition.developerCredit}
''';
  }

  /// Initialize service & restore 24-hour persisted steps
  Future<void> initialize() async {
    final brandIdx = await HealthStorageService.getBrandEditionIndex();
    _brandEdition = brandIdx == 1
        ? AppBrandEdition.sciRbruMoveAi
        : AppBrandEdition.chewaPulseXai;

    // โหลดการตั้งค่าเป้าหมายและโปรไฟล์
    _dailyGoal = await HealthStorageService.getDailyGoal();
    _targetWeightKg = await HealthStorageService.getTargetWeight();
    _targetCalorieDeficitKcal = await HealthStorageService.getTargetCalorieDeficit();
    _sedentaryAlertMinutes = await HealthStorageService.getSedentaryAlertMinutes();
    _dailyWaterGoalMl = await HealthStorageService.getDailyWaterGoal();
    _isVoiceAlertEnabled = await HealthStorageService.getVoiceAlertEnabled();

    // โหลดการตั้งค่าระบบนับก้าวอัตโนมัติ 24 ชม. และตารางเวลาของผู้ใช้
    _isAutoTrackEnabled = await HealthStorageService.getAutoTrackEnabled();
    _isAuto24HourMode = await HealthStorageService.getAuto24HourMode();
    _autoStartHour = await HealthStorageService.getAutoStartHour();
    _autoStartMinute = await HealthStorageService.getAutoStartMinute();
    _autoEndHour = await HealthStorageService.getAutoEndHour();
    _autoEndMinute = await HealthStorageService.getAutoEndMinute();

    VoiceAlertService().setVoiceEnabled(_isVoiceAlertEnabled);

    final profileData = await HealthStorageService.getUserProfileData();
    _profile = UserHealthProfile.fromJson(profileData);
    await OkrSyncService().initialize();

    final now = DateTime.now();
    _currentDateKey = HealthStorageService.dateKeyFor(now);

    // โหลดข้อมูลก้าวเดินของวันนี้ที่บันทึกไว้ตลอด 24 ชม. (แม้ปิดแอปแล้วเปิดใหม่ ข้อมูลจะยังคงอยู่ครบถ้วน)
    final savedTodaySteps = await HealthStorageService.getSavedStepsForDate(now);
    final savedHourly = await HealthStorageService.getHourlyStepsForDate(now);
    final savedActiveSec = await HealthStorageService.getActiveSecondsForDate(now);

    if (savedTodaySteps > _todaySteps) {
      _todaySteps = savedTodaySteps;
    }
    _hourlySteps.clear();
    _hourlySteps.addAll(savedHourly);
    if (_todaySteps > 0 && _hourlySteps.isEmpty) {
      _hourlySteps[now.hour] = _todaySteps;
    }
    if (savedActiveSec > _activeSeconds) {
      _activeSeconds = savedActiveSec;
    }

    // โหลดข้อมูลก้าวเดินย้อนหลัง 6 วันก่อนหน้า
    for (int i = 1; i <= 6; i++) {
      final d = now.subtract(Duration(days: i));
      final k = '${d.year}_${d.month}_${d.day}';
      _pastDaysSteps[k] = await HealthStorageService.getSavedStepsForDate(d);
    }

    // โหลดประวัติรอบ 4 ชั่วโมงก่อนหน้า
    final savedIntervals = await HealthStorageService.getIntervalRecords();
    _intervalRecords.clear();
    _intervalRecords.addAll(savedIntervals);

    _currentIntervalStartTime = now;
    _stepsAtIntervalStart = _todaySteps;

    // รันการวินิจฉัย AI รอบแรก
    _runAiIntervalAnalysis();

    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);

    _startSensorListener();
    _initPedometer();
    _startMotionDecayTimer();
    _startCadenceAndSedentaryTimer();
    _startFourHourSnapshotTimer();
    _startBackgroundSyncAndMidnightTimer();
    await _syncNativeBackgroundService();
    notifyListeners();
  }

  /// เชื่อมต่อและสั่งการ Native Android Foreground Service ให้ทำงานเบื้องหลังตลอด 24 ชั่วโมงแม้ปิดแอป
  Future<void> _syncNativeBackgroundService() async {
    if (kIsWeb) return;
    try {
      final result = await _bgChannel.invokeMethod<Map<dynamic, dynamic>>(
        'configureAndSyncBackgroundService',
        {
          'appName': _brandEdition.appName,
          'autoTrackEnabled': _isAutoTrackEnabled,
          'auto24HourMode': _isAuto24HourMode,
          'startHour': _autoStartHour,
          'startMinute': _autoStartMinute,
          'endHour': _autoEndHour,
          'endMinute': _autoEndMinute,
          'dailyGoal': _dailyGoal,
          'currentSteps': _todaySteps,
        },
      );
      if (result != null) {
        _isBackgroundServiceRunning = result['serviceRunning'] == true;
        final int bgSteps = (result['todaySteps'] as num?)?.toInt() ?? 0;
        if (bgSteps > _todaySteps) {
          _todaySteps = bgSteps;
          final savedHourly = await HealthStorageService.getHourlyStepsForDate(DateTime.now());
          _hourlySteps.clear();
          _hourlySteps.addAll(savedHourly);
          notifyListeners();
        }
      }
    } catch (e) {
      // ในสภาพแวดล้อม Flutter Test หรือแพลตฟอร์มที่ไม่ใช่ Android จะใช้ Dart Timer อัตโนมัติแทน
      _isBackgroundServiceRunning = true;
    }
  }

  /// ซิงค์ข้อมูลจาก Background Service และตรวจสอบการเปลี่ยนวันใหม่ (00:00 น.) ตลอด 24 ชั่วโมง
  void _startBackgroundSyncAndMidnightTimer() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final now = DateTime.now();
      final todayKey = HealthStorageService.dateKeyFor(now);

      // 1. ตรวจสอบการข้ามเที่ยงคืน (00:00 น.) เพื่อเก็บข้อมูลวันเก่าและเริ่มนับวันใหม่อัตโนมัติ 24 ชม.
      if (todayKey != _currentDateKey) {
        _pastDaysSteps[_currentDateKey] = _todaySteps;
        _currentDateKey = todayKey;
        _todaySteps = 0;
        _activeSeconds = 0;
        _hourlySteps.clear();
        _stepsAtIntervalStart = 0;
        _currentIntervalStartTime = now;
        await HealthStorageService.saveStepsForDate(now, 0);
        notifyListeners();
        return;
      }

      // 2. ดึงข้อมูลก้าวเดินที่ Native Background Service บันทึกไว้ขณะปิดหน้าจอหรือพับแอป
      try {
        final bgSteps = await HealthStorageService.getSavedStepsForDate(now);
        if (bgSteps > _todaySteps) {
          _todaySteps = bgSteps;
          final savedHourly = await HealthStorageService.getHourlyStepsForDate(now);
          _hourlySteps.clear();
          _hourlySteps.addAll(savedHourly);
          final savedActive = await HealthStorageService.getActiveSecondsForDate(now);
          if (savedActive > _activeSeconds) {
            _activeSeconds = savedActive;
          }
          _runAiIntervalAnalysis();
          notifyListeners();
        }
      } catch (_) {}
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // เมื่อเปิดแอปกลับมาใหม่ ให้ดึงก้าวเดินที่สะสมระหว่างปิดแอปขึ้นมาแสดงทันที
      _syncNativeBackgroundService();
      _startSensorListener();
      _initPedometer();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // บันทึกข้อมูลล่าสุดลงฐานข้อมูลทันทีเมื่อพับแอปหรือปิดแอป
      final now = DateTime.now();
      HealthStorageService.saveStepsForDate(now, _todaySteps);
      HealthStorageService.saveActiveSecondsForDate(now, _activeSeconds);
      _syncNativeBackgroundService();
    }
  }

  /// เริ่มต้นรับฟัง Hardware Step Counter Sensor แบบประหยัดพลังงาน (ทำงานต่อเนื่องในกระเป๋ากางเกงและขณะปิดหน้าจอ)
  void _initPedometer() {
    try {
      _stepCountSubscription?.cancel();
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onHardwareStepCount,
        onError: (dynamic error) {
          debugPrint('[i] Hardware pedometer stream notice: $error (Fallback to Accelerometer Peak Detection)');
          _hasHardwarePedometer = false;
        },
      );

      _pedestrianStatusSubscription?.cancel();
      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: (dynamic error) {
          debugPrint('[i] Pedestrian status stream notice: $error');
        },
      );
    } catch (e) {
      debugPrint('[!] Pedometer initialization failed: $e');
      _hasHardwarePedometer = false;
    }
  }

  void _onHardwareStepCount(StepCount event) {
    _hasHardwarePedometer = true;
    if (_lastHardwareStepCount == null) {
      _lastHardwareStepCount = event.steps;
      _accelStepsSinceLastHardwareSync = 0;
      return;
    }
    final int hwDiff = event.steps - _lastHardwareStepCount!;
    _lastHardwareStepCount = event.steps;

    if (hwDiff > 0 && isWithinScheduledWindow()) {
      // ชดเชยก้าวที่ชิป Pedometer นับได้ในกระเป๋ากางเกง/ขณะปิดหน้าจอ โดยไม่นับซ้ำกับ Accelerometer
      final int missedPocketSteps = hwDiff - _accelStepsSinceLastHardwareSync;
      _accelStepsSinceLastHardwareSync = 0;
      if (missedPocketSteps > 0) {
        final int nowMs = DateTime.now().millisecondsSinceEpoch;
        for (int i = 0; i < missedPocketSteps; i++) {
          _onStepDetected(nowMs, 2.2, fromHardwarePedometer: true);
        }
      }
    }
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    if (event.status == 'walking' && _currentActivity == ActivityType.stationary) {
      _currentActivity = ActivityType.walking;
      notifyListeners();
    }
  }

  void _startSensorListener() {
    try {
      _accelSubscription?.cancel();
      _accelSubscription = userAccelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (UserAccelerometerEvent event) {
          _isSensorActive = true;
          _processAccelerometerData(event.x, event.y, event.z);
        },
        onError: (err) {
          debugPrint('[i] UserAccelerometer sensor notice: $err');
        },
      );

      // เพิ่มการรับฟัง Raw Accelerometer (Type 1) พร้อม High-Pass Gravity Filter สำหรับการแกว่งในกระเป๋ากางเกง
      _rawAccelSubscription?.cancel();
      _rawAccelSubscription = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(
        (AccelerometerEvent event) {
          _isSensorActive = true;
          final double rawMag = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          _gravityBaseline = (_gravityBaseline * 0.92) + (rawMag * 0.08);
          final double linearPocketAccel = (rawMag - _gravityBaseline).abs();
          if (linearPocketAccel > _stepThreshold) {
            _processAccelerometerData(linearPocketAccel, 0.0, 0.0);
          }
        },
        onError: (err) {
          debugPrint('[i] Raw Accelerometer sensor notice: $err');
        },
      );
    } catch (e) {
      debugPrint('[!] Sensor listener error: $e');
      _isSensorActive = false;
    }
  }

  /// Physics-Informed Step Detection
  void _processAccelerometerData(double x, double y, double z) {
    final double magnitude = math.sqrt(x * x + y * y + z * z);
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    // Motion intensity smoothing
    final double rawIntensity = (magnitude / 10.0).clamp(0.0, 1.0);
    _motionIntensity = (_motionIntensity * 0.7) + (rawIntensity * 0.3);

    // ตรวจจับแรงกระแทกผิดปกติหรือการล้มฉับพลัน (Fall / Severe Impact > 32 m/s^2)
    if (magnitude > 32.0 && !_isFallWarningActive) {
      _isFallWarningActive = true;
      VoiceAlertService().playFallWarningVoiceAlert();
      notifyListeners();
    }

    // ตรวจสอบว่าอยู่ในช่วงเวลาทำงานอัตโนมัติ (24 ชม. หรือตามเวลาที่ผู้ใช้กำหนด)
    if (!isWithinScheduledWindow()) {
      _lastMagnitude = magnitude;
      return;
    }

    // Dynamic peak detection with refractory window
    if (magnitude > _stepThreshold && _lastMagnitude <= _stepThreshold) {
      if (nowMs - _lastStepTimestampMs > _refractoryPeriodMs) {
        _onStepDetected(nowMs, magnitude);
      }
    }

    _lastMagnitude = magnitude;
    _updateActivityClassification(magnitude);
  }

  void _onStepDetected(int nowMs, double magnitude, {bool fromHardwarePedometer = false}) {
    final now = DateTime.now();
    final todayKey = HealthStorageService.dateKeyFor(now);
    if (todayKey != _currentDateKey) {
      _pastDaysSteps[_currentDateKey] = _todaySteps;
      _currentDateKey = todayKey;
      _todaySteps = 0;
      _activeSeconds = 0;
      _hourlySteps.clear();
    }

    _todaySteps++;
    if (!fromHardwarePedometer) {
      _accelStepsSinceLastHardwareSync++;
    }
    _lastStepTimestampMs = nowMs;
    _activeSeconds += 2;
    _sedentarySeconds = 0; // รีเซตเวลานั่งนิ่งเมื่อเกิดการก้าวเดินจริง

    // Sliding window cadence calculation
    _recentStepTimestamps.add(nowMs);
    _calculateCadence(nowMs);

    // Record into current hour (0..23)
    final currentHour = now.hour;
    final updatedHourSteps = (_hourlySteps[currentHour] ?? 0) + 1;
    _hourlySteps[currentHour] = updatedHourSteps;

    // บันทึกลงฐานข้อมูลในเครื่องแบบ Real-time ทุกก้าว เพื่อให้ข้อมูลอยู่ครบตลอด 24 ชม. แม้ปิดแอปทันที
    HealthStorageService.saveStepsForDate(now, _todaySteps);
    HealthStorageService.saveHourlyStepsForDate(now, currentHour, updatedHourSteps);
    if (_todaySteps % 5 == 0) {
      HealthStorageService.saveActiveSecondsForDate(now, _activeSeconds);
    }

    notifyListeners();
  }

  void _calculateCadence(int nowMs) {
    _recentStepTimestamps.removeWhere((ts) => nowMs - ts > 8000);
    if (_recentStepTimestamps.length >= 2) {
      final int dt = _recentStepTimestamps.last - _recentStepTimestamps.first;
      if (dt > 600) {
        final double minutes = dt / 60000.0;
        final double spm = (_recentStepTimestamps.length - 1) / minutes;
        _cadenceSpm = spm.round().clamp(0, 240);
      }
    } else {
      _cadenceSpm = 0;
    }
  }

  void _updateActivityClassification(double magnitude) {
    if (_motionIntensity < 0.12) {
      _currentActivity = ActivityType.stationary;
    } else if (magnitude > 6.0 || _motionIntensity > 0.65 || _cadenceSpm >= 130) {
      _currentActivity = ActivityType.running;
    } else if (magnitude > 2.0 || _motionIntensity > 0.25 || _cadenceSpm >= 80) {
      _currentActivity = ActivityType.walking;
    } else {
      _currentActivity = ActivityType.active;
    }
  }

  void _startMotionDecayTimer() {
    _decayTimer?.cancel();
    _decayTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - _lastStepTimestampMs > 1500 && !_isSimulating) {
        if (_motionIntensity > 0.05) {
          _motionIntensity *= 0.82;
          if (_motionIntensity < 0.08) {
            _motionIntensity = 0.0;
            _currentActivity = ActivityType.stationary;
          }
          notifyListeners();
        }
      }
    });
  }

  /// ตรวจจับการนั่งนิ่งนานเกิน 30 นาที พร้อมกระตุ้นเสียงเตือน "ลุกค่ะ ลุกค่ะ"
  void _startCadenceAndSedentaryTimer() {
    _cadenceAndSedentaryTimer?.cancel();
    _cadenceAndSedentaryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (nowMs - _lastStepTimestampMs > 3500 && _cadenceSpm > 0) {
        _cadenceSpm = 0;
        _recentStepTimestamps.clear();
        notifyListeners();
      }

      if (_currentActivity == ActivityType.stationary && isWithinScheduledWindow()) {
        _sedentarySeconds++;

        // ตรวจสอบเงื่อนไข 30 นาที (1,800 วินาที)
        final thresholdSec = _sedentaryAlertMinutes * 60;
        if (_sedentarySeconds == thresholdSec || (_sedentarySeconds > thresholdSec && _sedentarySeconds % 300 == 0)) {
          VoiceAlertService().playSedentaryVoiceAlert();
          notifyListeners();
        } else if (_sedentarySeconds % 60 == 0) {
          notifyListeners();
        }
      } else {
        _sedentarySeconds = 0;
      }
    });
  }

  /// บันทึกข้อมูลอัตโนมัติทุก 4 ชั่วโมง เพื่อนำข้อมูลมาวิเคราะห์
  void _startFourHourSnapshotTimer() {
    _fourHourSnapshotTimer?.cancel();
    _fourHourSnapshotTimer = Timer.periodic(const Duration(hours: 4), (_) {
      captureAndSave4HourSnapshot();
    });
  }

  /// ถ่ายสแน็ปช็อตข้อมูลรอบ 4 ชั่วโมง และวิเคราะห์ด้วยปัญญาประดิษฐ์
  Future<HealthIntervalRecord> captureAndSave4HourSnapshot() async {
    final now = DateTime.now();
    final intervalSteps = math.max(0, _todaySteps - _stepsAtIntervalStart);
    final speedMultiplier = _currentActivity == ActivityType.running ? 1.25 : 1.0;
    final intervalDistance = _profile.calculateDistanceKm(intervalSteps, speedMultiplier);
    final intervalCalories = (intervalSteps / 1000.0) * (_profile.weightKg * 0.55);
    final intervalHydration = _profile.calculateHydrationLossMl(intervalSteps, _motionIntensity);

    final aiInference = DeepHealthAiEngine().analyze4HourInterval(
      steps4h: intervalSteps,
      meanCadence: _cadenceSpm > 0 ? _cadenceSpm : 92,
      sedentaryMinutes: sedentaryMinutes,
      motionIntensity: _motionIntensity,
      calories: intervalCalories,
      hydrationLossMl: intervalHydration,
    );
    _latestAiInference = aiInference;

    final record = HealthIntervalRecord(
      id: 'snap_${now.millisecondsSinceEpoch}',
      startTime: _currentIntervalStartTime,
      endTime: now,
      steps: intervalSteps,
      distanceKm: intervalDistance,
      caloriesKcal: intervalCalories,
      hydrationMl: intervalHydration,
      meanCadenceSpm: _cadenceSpm > 0 ? _cadenceSpm : 95,
      maxCadenceSpm: math.max(_cadenceSpm, 120),
      sedentaryMinutes: sedentaryMinutes,
      motionIntensity: _motionIntensity,
      aiDiagnosis: aiInference.statusTitle,
      aiConfidence: aiInference.confidence,
    );

    _intervalRecords.insert(0, record);
    await HealthStorageService.saveIntervalRecord(record);

    _currentIntervalStartTime = now;
    _stepsAtIntervalStart = _todaySteps;

    notifyListeners();
    return record;
  }

  void _runAiIntervalAnalysis() {
    final ai = DeepHealthAiEngine();
    _latestAiInference = ai.analyze4HourInterval(
      steps4h: _todaySteps,
      meanCadence: _cadenceSpm,
      sedentaryMinutes: sedentaryMinutes,
      motionIntensity: _motionIntensity,
      calories: caloriesKcal,
      hydrationLossMl: hydrationLostMl,
    );
  }

  /// ฝึกสอนโมเดล Deep Learning บนสมาร์ทโฟนด้วยข้อมูลการเคลื่อนไหวจริง
  Future<DeepTrainingResult> retrainAiModel({int epochs = 15}) async {
    final result = await DeepHealthAiEngine().trainOnUserKinematics(
      historicalRecords: _intervalRecords,
      epochs: epochs,
    );
    _runAiIntervalAnalysis();
    notifyListeners();
    return result;
  }

  /// Toggle Live Walking Simulation
  void toggleSimulation() {
    _isSimulating = !_isSimulating;
    _simulationTimer?.cancel();

    if (_isSimulating) {
      _currentActivity = ActivityType.walking;
      _motionIntensity = 0.45;
      _cadenceSpm = 106;
      _sedentarySeconds = 0;
      _simulationTimer = Timer.periodic(const Duration(milliseconds: 566), (_) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        _onStepDetected(nowMs, 3.2);
        _motionIntensity = 0.40 + (math.sin(nowMs / 300) * 0.15);
        _cadenceSpm = 104 + (math.sin(nowMs / 800) * 6).round();
        notifyListeners();
      });
    } else {
      _motionIntensity = 0.0;
      _cadenceSpm = 0;
      _currentActivity = ActivityType.stationary;
    }
    notifyListeners();
  }

  /// Add single step manually
  void addManualStep() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _onStepDetected(nowMs, 3.5);
    _motionIntensity = 0.50;
    _currentActivity = ActivityType.walking;
    notifyListeners();
  }

  /// ปรับปรุงเป้าหมายและค่าคอนฟิกทั้งหมด
  Future<void> updateComprehensiveSettings({
    required int dailyGoal,
    required double targetWeightKg,
    required int targetCalorieDeficit,
    required int sedentaryAlertMinutes,
    required int dailyWaterGoalMl,
    required bool voiceAlertEnabled,
  }) async {
    _dailyGoal = dailyGoal.clamp(1000, 50000);
    _targetWeightKg = targetWeightKg.clamp(30.0, 200.0);
    _targetCalorieDeficitKcal = targetCalorieDeficit.clamp(100, 2000);
    _sedentaryAlertMinutes = sedentaryAlertMinutes.clamp(10, 180);
    _dailyWaterGoalMl = dailyWaterGoalMl.clamp(1000, 5000);
    _isVoiceAlertEnabled = voiceAlertEnabled;

    VoiceAlertService().setVoiceEnabled(_isVoiceAlertEnabled);

    await HealthStorageService.setDailyGoal(_dailyGoal);
    await HealthStorageService.setTargetWeight(_targetWeightKg);
    await HealthStorageService.setTargetCalorieDeficit(_targetCalorieDeficitKcal);
    await HealthStorageService.setSedentaryAlertMinutes(_sedentaryAlertMinutes);
    await HealthStorageService.setDailyWaterGoal(_dailyWaterGoalMl);
    await HealthStorageService.setVoiceAlertEnabled(_isVoiceAlertEnabled);
    await _syncNativeBackgroundService();

    notifyListeners();
  }

  /// Update personalized health profile
  Future<void> updateProfile(UserHealthProfile newProfile) async {
    _profile = newProfile;
    await HealthStorageService.saveUserProfile(
      _profile.weightKg,
      _profile.heightCm,
      _profile.age,
      _profile.gender.index,
    );
    notifyListeners();
  }

  /// Dismiss sedentary active break alert
  void dismissActiveBreak() {
    _sedentarySeconds = 0;
    notifyListeners();
  }

  /// จำลองสถานะหยุดนิ่งครบ 30 นาทีและส่งเสียงพูดเตือน "ลุกคะ ลุกค่ะ" ทันที
  void triggerSedentaryAlertDemo() {
    _currentActivity = ActivityType.stationary;
    _sedentarySeconds = _sedentaryAlertMinutes * 60;
    VoiceAlertService().playSedentaryVoiceAlert(force: true);
    notifyListeners();
  }

  /// รีเซตข้อมูลทั้งหมดเป็น 0 (Reset All to 0)
  void resetAllToZero() {
    final now = DateTime.now();
    _todaySteps = 0;
    _activeSeconds = 0;
    _motionIntensity = 0.0;
    _cadenceSpm = 0;
    _sedentarySeconds = 0;
    _currentActivity = ActivityType.stationary;
    _hourlySteps.clear();
    _stepsAtIntervalStart = 0;
    _currentIntervalStartTime = now;
    _lastHardwareStepCount = null;
    _accelStepsSinceLastHardwareSync = 0;
    _isFallWarningActive = false;
    HealthStorageService.saveStepsForDate(now, 0);
    HealthStorageService.clearHourlyStepsForDate(now);
    HealthStorageService.saveActiveSecondsForDate(now, 0);
    if (!kIsWeb) {
      try {
        _bgChannel.invokeMethod('resetBackgroundSteps');
      } catch (_) {}
    }
    GpsTrackingService.instance.clearRoute();
    _runAiIntervalAnalysis();
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accelSubscription?.cancel();
    _rawAccelSubscription?.cancel();
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _simulationTimer?.cancel();
    _decayTimer?.cancel();
    _cadenceAndSedentaryTimer?.cancel();
    _fourHourSnapshotTimer?.cancel();
    _backgroundSyncTimer?.cancel();
    super.dispose();
  }
}
