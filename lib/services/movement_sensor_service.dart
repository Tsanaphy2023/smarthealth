import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/activity_type.dart';
import '../models/daily_health_metric.dart';
import '../models/health_interval_record.dart';
import '../models/user_health_profile.dart';
import 'deep_health_ai_engine.dart';
import 'gps_tracking_service.dart';
import 'health_storage_service.dart';
import 'voice_alert_service.dart';

class MovementSensorService extends ChangeNotifier {
  static final MovementSensorService _instance = MovementSensorService._internal();
  factory MovementSensorService() => _instance;
  MovementSensorService._internal();

  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  int? _initialHardwareStepCount;
  bool _hasHardwarePedometer = false;
  bool _isFallWarningActive = false;
  Timer? _simulationTimer;
  Timer? _decayTimer;
  Timer? _cadenceAndSedentaryTimer;
  Timer? _fourHourSnapshotTimer;

  // Personalized Health Profile & Goals
  UserHealthProfile _profile = const UserHealthProfile();
  int _dailyGoal = 10000;
  double _targetWeightKg = 60.0;
  int _targetCalorieDeficitKcal = 500;
  int _sedentaryAlertMinutes = 30; // ค่าเริ่มต้น 30 นาทีตามคำสั่งผู้ใช้
  int _dailyWaterGoalMl = 2500;
  bool _isVoiceAlertEnabled = true;

  // Real-time sensor state (เริ่มต้นทุกอย่างเป็น 0 ทั้งหมด)
  int _todaySteps = 0;
  double _motionIntensity = 0.0; // 0.0 to 1.0
  ActivityType _currentActivity = ActivityType.stationary;
  int _activeSeconds = 0;

  // Step detection algorithm variables
  double _lastMagnitude = 0.0;
  int _lastStepTimestampMs = 0;
  static const double _stepThreshold = 1.85; // m/s^2 dynamic peak threshold
  static const int _refractoryPeriodMs = 280; // minimum ms between valid steps

  // Health Science: Cadence & Sedentary tracking
  int _cadenceSpm = 0; // Steps per minute
  final List<int> _recentStepTimestamps = [];
  int _sedentarySeconds = 0; // Continuous inactive seconds

  // 4-Hour Interval Tracking & AI
  final List<HealthIntervalRecord> _intervalRecords = [];
  DeepHealthInference? _latestAiInference;
  DateTime _currentIntervalStartTime = DateTime.now();
  int _stepsAtIntervalStart = 0;

  // Hourly steps distribution (0..23) เริ่มต้นว่างเปล่า 0 ทั้งหมด
  final Map<int, int> _hourlySteps = {};

  bool _isSimulating = false;
  bool _isSensorActive = false;

  // Getters
  UserHealthProfile get profile => _profile;
  int get todaySteps => _todaySteps;
  int get dailyGoal => _dailyGoal;
  double get targetWeightKg => _targetWeightKg;
  int get targetCalorieDeficitKcal => _targetCalorieDeficitKcal;
  int get sedentaryAlertMinutes => _sedentaryAlertMinutes;
  int get dailyWaterGoalMl => _dailyWaterGoalMl;
  bool get isVoiceAlertEnabled => _isVoiceAlertEnabled;

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

  /// Initialize service
  /// กฎสำคัญ: "เมื่อเปิดแอปพลิเคชันใหม่ ทุกอย่างเซตเป็น 0 ทั้งหมด"
  Future<void> initialize() async {
    // โหลดการตั้งค่าเป้าหมายและโปรไฟล์
    _dailyGoal = await HealthStorageService.getDailyGoal();
    _targetWeightKg = await HealthStorageService.getTargetWeight();
    _targetCalorieDeficitKcal = await HealthStorageService.getTargetCalorieDeficit();
    _sedentaryAlertMinutes = await HealthStorageService.getSedentaryAlertMinutes();
    _dailyWaterGoalMl = await HealthStorageService.getDailyWaterGoal();
    _isVoiceAlertEnabled = await HealthStorageService.getVoiceAlertEnabled();

    VoiceAlertService().setVoiceEnabled(_isVoiceAlertEnabled);

    final profileData = await HealthStorageService.getUserProfileData();
    _profile = UserHealthProfile.fromJson(profileData);

    // โหลดประวัติรอบ 4 ชั่วโมงก่อนหน้า
    final savedIntervals = await HealthStorageService.getIntervalRecords();
    _intervalRecords.clear();
    _intervalRecords.addAll(savedIntervals);

    // เซตค่าตัวนับสดของรอบใหม่เป็น 0 ทั้งหมดตามคำสั่ง
    _todaySteps = 0;
    _activeSeconds = 0;
    _motionIntensity = 0.0;
    _cadenceSpm = 0;
    _sedentarySeconds = 0;
    _currentActivity = ActivityType.stationary;
    _hourlySteps.clear();
    _currentIntervalStartTime = DateTime.now();
    _stepsAtIntervalStart = 0;

    // รันการวินิจฉัย AI รอบแรก
    _runAiIntervalAnalysis();

    _startSensorListener();
    _initPedometer();
    _startMotionDecayTimer();
    _startCadenceAndSedentaryTimer();
    _startFourHourSnapshotTimer();
    notifyListeners();
  }

  /// เริ่มต้นรับฟัง Hardware Step Counter Sensor แบบประหยัดพลังงาน
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
    if (_initialHardwareStepCount == null) {
      _initialHardwareStepCount = event.steps;
      return;
    }
    final int delta = event.steps - _initialHardwareStepCount!;
    if (delta > 0 && delta > _todaySteps) {
      final int stepsToAdd = delta - _todaySteps;
      for (int i = 0; i < stepsToAdd; i++) {
        _onStepDetected(DateTime.now().millisecondsSinceEpoch, 2.2);
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
      _accelSubscription = userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          _isSensorActive = true;
          _processAccelerometerData(event.x, event.y, event.z);
        },
        onError: (err) {
          debugPrint('[i] Accelerometer sensor notice: $err');
          _isSensorActive = false;
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

    // Dynamic peak detection with refractory window
    if (magnitude > _stepThreshold && _lastMagnitude <= _stepThreshold) {
      if (nowMs - _lastStepTimestampMs > _refractoryPeriodMs) {
        _onStepDetected(nowMs, magnitude);
      }
    }

    _lastMagnitude = magnitude;
    _updateActivityClassification(magnitude);
  }

  void _onStepDetected(int nowMs, double magnitude) {
    _todaySteps++;
    _lastStepTimestampMs = nowMs;
    _activeSeconds += 2;
    _sedentarySeconds = 0; // รีเซตเวลานั่งนิ่งเมื่อเกิดการก้าวเดินจริง

    // Sliding window cadence calculation
    _recentStepTimestamps.add(nowMs);
    _calculateCadence(nowMs);

    // Record into current hour
    final currentHour = DateTime.now().hour;
    _hourlySteps[currentHour] = (_hourlySteps[currentHour] ?? 0) + 1;

    // Save steps periodically
    if (_todaySteps % 10 == 0) {
      HealthStorageService.saveStepsForDate(DateTime.now(), _todaySteps);
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

      if (_currentActivity == ActivityType.stationary) {
        _sedentarySeconds++;

        // ตรวจสอบเงื่อนไข 30 นาที (1,800 วินาที)
        final thresholdSec = _sedentaryAlertMinutes * 60;
        if (_sedentarySeconds == thresholdSec || (_sedentarySeconds > thresholdSec && _sedentarySeconds % 300 == 0)) {
          // กระตุ้นเสียงพูดเตือนภาษาไทย "ลุกค่ะ ลุกค่ะ"
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
    // ตรวจสอบทุก 4 ชั่วโมง (4 * 3600 วินาที)
    _fourHourSnapshotTimer = Timer.periodic(const Duration(hours: 4), (_) {
      captureAndSave4HourSnapshot();
    });
  }

  /// ถ่ายสแน็ปช็อตข้อมูลรอบ 4 ชั่วโมง และวิเคราะห์ด้วยปัญญาประดิษฐ์
  Future<HealthIntervalRecord> captureAndSave4HourSnapshot() async {
    final now = DateTime.now();
    final intervalSteps = _todaySteps - _stepsAtIntervalStart;
    final speedMultiplier = _currentActivity == ActivityType.running ? 1.25 : 1.0;
    final intervalDistance = _profile.calculateDistanceKm(intervalSteps, speedMultiplier);
    final intervalCalories = (intervalSteps / 1000.0) * (_profile.weightKg * 0.55);
    final intervalHydration = _profile.calculateHydrationLossMl(intervalSteps, _motionIntensity);

    // รันการวินิจฉัยด้วย Deep Learning Neural Engine
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

    // อัปเดตจุดเริ่มของรอบถัดไป
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

  /// รีเซตข้อมูลทั้งหมดเป็น 0 (Reset All to 0)
  void resetAllToZero() {
    _todaySteps = 0;
    _activeSeconds = 0;
    _motionIntensity = 0.0;
    _cadenceSpm = 0;
    _sedentarySeconds = 0;
    _currentActivity = ActivityType.stationary;
    _hourlySteps.clear();
    _stepsAtIntervalStart = 0;
    _currentIntervalStartTime = DateTime.now();
    _initialHardwareStepCount = null;
    _isFallWarningActive = false;
    HealthStorageService.saveStepsForDate(DateTime.now(), 0);
    GpsTrackingService.instance.clearRoute();
    _runAiIntervalAnalysis();
    notifyListeners();
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _simulationTimer?.cancel();
    _decayTimer?.cancel();
    _cadenceAndSedentaryTimer?.cancel();
    _fourHourSnapshotTimer?.cancel();
    super.dispose();
  }
}
