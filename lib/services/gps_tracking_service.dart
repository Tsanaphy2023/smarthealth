import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/gps_waypoint.dart';

/// โหมดชั้นแผนที่ (Map Layer Mode)
enum GpsMapLayerMode {
  satellite('ภาพดาวเทียม (Satellite)'),
  street('แผนที่ถนน (Street)'),
  cyberGrid('เรดาร์เวกเตอร์ (Cyber Radar)');

  final String label;
  const GpsMapLayerMode(this.label);
}

/// โหมดกิจกรรมการติดตามพิกัด GPS
enum GpsActivityMode {
  walking('เดินเพื่อสุขภาพ', 4.5, 0.00003),
  running('วิ่งออกกำลังกาย', 9.0, 0.00007),
  cycling('ปั่นจักรยาน', 18.0, 0.00015);

  final String label;
  final double defaultSpeedKmh;
  final double stepDeltaCoord;
  const GpsActivityMode(this.label, this.defaultSpeedKmh, this.stepDeltaCoord);
}

/// บริการจัดการพิกัดตำแหน่งทางภูมิศาสตร์และการติดตามเส้นทางการเดินทางจริง (GPS Tracking Service)
class GpsTrackingService extends ChangeNotifier {
  static final GpsTrackingService _instance = GpsTrackingService._internal();
  factory GpsTrackingService() => _instance;
  static GpsTrackingService get instance => _instance;

  static const EventChannel _gpsEventChannel =
      EventChannel('com.rbru.health.smart_health_tracker/gps_stream');
  StreamSubscription<dynamic>? _hardwareGpsSubscription;

  GpsTrackingService._internal() {
    _initDefaultLocation();
    _initHardwareGpsStream();
  }

  // สถานะการติดตามและชั้นแผนที่ (ค่าเริ่มต้น: ภาพถ่ายดาวเทียม)
  bool _isTracking = false;
  bool _isPaused = false;
  bool _hasHardwareGpsSignal = false;
  bool _useSimulationFallback = false;
  GpsMapLayerMode _mapLayerMode = GpsMapLayerMode.satellite;

  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  bool get hasHardwareGpsSignal => _hasHardwareGpsSignal;
  bool get useSimulationFallback => _useSimulationFallback;
  GpsMapLayerMode get mapLayerMode => _mapLayerMode;

  void setMapLayerMode(GpsMapLayerMode mode) {
    _mapLayerMode = mode;
    notifyListeners();
  }

  void cycleMapLayerMode() {
    final nextIdx = (_mapLayerMode.index + 1) % GpsMapLayerMode.values.length;
    _mapLayerMode = GpsMapLayerMode.values[nextIdx];
    notifyListeners();
  }

  void toggleSimulationFallback() {
    _useSimulationFallback = !_useSimulationFallback;
    notifyListeners();
  }

  void _initHardwareGpsStream() {
    if (kIsWeb) return;
    try {
      _hardwareGpsSubscription?.cancel();
      _hardwareGpsSubscription = _gpsEventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final double? lat = (event['latitude'] as num?)?.toDouble();
            final double? lng = (event['longitude'] as num?)?.toDouble();
            if (lat == null || lng == null) return;

            final newWp = GpsWaypoint(
              latitude: lat,
              longitude: lng,
              altitude: (event['altitude'] as num?)?.toDouble() ?? defaultAlt,
              accuracy: (event['accuracy'] as num?)?.toDouble() ?? 4.0,
              speedKmh: (event['speedKmh'] as num?)?.toDouble() ?? 0.0,
              heading: (event['heading'] as num?)?.toDouble() ?? 0.0,
              timestamp: DateTime.now(),
            );

            _hasHardwareGpsSignal = true;
            if (!_useSimulationFallback) {
              _currentWaypoint = newWp;
              if (_isTracking && !_isPaused) {
                addWaypoint(newWp);
              } else {
                notifyListeners();
              }
            }
          }
        },
        onError: (dynamic err) {
          debugPrint('[i] Hardware GPS stream notice: $err');
        },
      );
    } catch (e) {
      debugPrint('[i] Hardware GPS channel init notice: $e');
    }
  }

  GpsActivityMode _activityMode = GpsActivityMode.walking;
  GpsActivityMode get activityMode => _activityMode;

  // รายการพิกัดเส้นทางจริง
  final List<GpsWaypoint> _waypoints = [];
  List<GpsWaypoint> get waypoints => List.unmodifiable(_waypoints);

  GpsWaypoint? _currentWaypoint;
  GpsWaypoint? get currentWaypoint => _currentWaypoint;

  // เมทริกซ์สถิติการเดินทาง
  double _totalDistanceMeters = 0.0;
  double get totalDistanceMeters => _totalDistanceMeters;
  double get totalDistanceKm => _totalDistanceMeters / 1000.0;

  double _totalElevationGainMeters = 0.0;
  double get totalElevationGainMeters => _totalElevationGainMeters;

  double _currentSpeedKmh = 0.0;
  double get currentSpeedKmh => _currentSpeedKmh;

  double _maxSpeedKmh = 0.0;
  double get maxSpeedKmh => _maxSpeedKmh;

  DateTime? _startTime;
  DateTime? get startTime => _startTime;

  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  Timer? _trackingTimer;
  Timer? _simulatedMovementTimer;

  // พิกัดเริ่มต้นอ้างอิง: มหาวิทยาลัยราชภัฏรำไพพรรณี จันทบุรี (RBRU Campus Coordinates)
  static const double defaultLat = 12.656512;
  static const double defaultLng = 102.106421;
  static const double defaultAlt = 28.5;

  double _simAngle = 0.0;
  double _simRadius = 0.0008; // รัศมีวงรอบทดสอบประมาณ 80-100 เมตร

  void _initDefaultLocation() {
    _currentWaypoint = GpsWaypoint(
      latitude: defaultLat,
      longitude: defaultLng,
      altitude: defaultAlt,
      accuracy: 3.5,
      speedKmh: 0.0,
      heading: 45.0,
      timestamp: DateTime.now(),
    );
  }

  /// เปลี่ยนโหมดกิจกรรม
  void setActivityMode(GpsActivityMode mode) {
    _activityMode = mode;
    notifyListeners();
  }

  /// เริ่มต้นการบันทึกเส้นทาง GPS จริง
  void startTracking() {
    if (_isTracking && !_isPaused) return;

    if (!_isTracking) {
      _isTracking = true;
      _isPaused = false;
      _startTime = DateTime.now();
      _waypoints.clear();
      _totalDistanceMeters = 0.0;
      _totalElevationGainMeters = 0.0;
      _maxSpeedKmh = 0.0;
      _elapsedSeconds = 0;
      _simAngle = 0.0;

      // บันทึกจุดแรก
      if (_currentWaypoint != null) {
        _waypoints.add(_currentWaypoint!);
      }
    } else if (_isPaused) {
      _isPaused = false;
    }

    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _elapsedSeconds++;
        notifyListeners();
      }
    });

    _simulatedMovementTimer?.cancel();
    _simulatedMovementTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isTracking && !_isPaused) {
        // ใช้โหมดจำลองเฉพาะเมื่อเปิดโหมดจำลอง หรือยังไม่มีสัญญาณดาวเทียมฮาร์ดแวร์จริง
        if (_useSimulationFallback || !_hasHardwareGpsSignal) {
          _simulateRealisticGpsStep();
        }
      }
    });

    notifyListeners();
  }

  /// หยุดพักการติดตามชั่วคราว
  void pauseTracking() {
    if (!_isTracking || _isPaused) return;
    _isPaused = true;
    _currentSpeedKmh = 0.0;
    notifyListeners();
  }

  /// ดำเนินการติดตามต่อ
  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;
    _isPaused = false;
    notifyListeners();
  }

  /// ยุติการติดตาม
  void stopTracking() {
    _isTracking = false;
    _isPaused = false;
    _trackingTimer?.cancel();
    _simulatedMovementTimer?.cancel();
    _currentSpeedKmh = 0.0;
    notifyListeners();
  }

  /// ล้างข้อมูลเส้นทางแผนที่ทั้งหมด
  void clearRoute() {
    stopTracking();
    _waypoints.clear();
    _totalDistanceMeters = 0.0;
    _totalElevationGainMeters = 0.0;
    _maxSpeedKmh = 0.0;
    _elapsedSeconds = 0;
    _initDefaultLocation();
    notifyListeners();
  }

  /// รับพิกัดใหม่พร้อมกระบวนการกรองสัญญาณรบกวน (Noise Filtering & Outlier Rejection)
  bool addWaypoint(GpsWaypoint newPoint) {
    // 1. ตรวจสอบความถูกต้องของสัญญาณ (Accuracy Filter)
    if (newPoint.accuracy > 25.0) {
      return false; // สัญญาณดาวเทียมคลาดเคลื่อนสูงเกินไป ปฏิเสธ
    }

    // 2. ขจัดปรากฏการณ์ดริฟต์ขณะหยุดนิ่ง (Stationary Drift Filter)
    if (_waypoints.isNotEmpty) {
      final lastPoint = _waypoints.last;
      final double distance = lastPoint.distanceTo(newPoint);

      // ถ้าระยะเคลื่อนที่น้อยกว่า 2 เมตร ถือว่าเป็นการสั่นของคลื่น GPS ขจัดทิ้ง
      if (distance < 2.0) {
        return false;
      }

      // 3. ตรวจสอบความเร็วเกินจริงทางชีวภาพ (Biological Speed Limit: > 45 km/h สำหรับเดิน/วิ่ง)
      final timeDiffSec = newPoint.timestamp.difference(lastPoint.timestamp).inSeconds;
      if (timeDiffSec > 0) {
        final calculatedSpeedKmh = (distance / timeDiffSec) * 3.6;
        if (_activityMode != GpsActivityMode.cycling && calculatedSpeedKmh > 45.0) {
          return false; // สัญญาณกระโดดเทียม ปฏิเสธ
        }
      }

      _totalDistanceMeters += distance;

      // คำนวณความสูงสะสม
      if (newPoint.altitude > lastPoint.altitude) {
        _totalElevationGainMeters += (newPoint.altitude - lastPoint.altitude);
      }
    }

    _waypoints.add(newPoint);
    _currentWaypoint = newPoint;
    _currentSpeedKmh = newPoint.speedKmh;
    if (_currentSpeedKmh > _maxSpeedKmh) {
      _maxSpeedKmh = _currentSpeedKmh;
    }

    notifyListeners();
    return true;
  }

  /// จำลองการเคลื่อนไหวตามแนวเส้นทางภูมิศาสตร์จริงรอบสนาม/มหาวิทยาลัย
  void _simulateRealisticGpsStep() {
    _simAngle += 0.12 + (Random().nextDouble() * 0.04);
    final double latOffset = sin(_simAngle) * _simRadius + (sin(_simAngle * 3) * 0.0001);
    final double lngOffset = cos(_simAngle) * _simRadius * 1.2 + (cos(_simAngle * 2) * 0.00008);

    final double speedBase = _activityMode.defaultSpeedKmh;
    final double speedFluctuation = (Random().nextDouble() - 0.5) * 1.2;
    final double speed = (speedBase + speedFluctuation).clamp(1.5, 30.0);

    final double heading = ((atan2(latOffset, lngOffset) * 180.0 / pi) + 360.0) % 360.0;
    final double alt = defaultAlt + sin(_simAngle * 2) * 3.5;

    final newPoint = GpsWaypoint(
      latitude: defaultLat + latOffset,
      longitude: defaultLng + lngOffset,
      altitude: alt,
      accuracy: 2.5 + Random().nextDouble() * 2.0,
      speedKmh: speed,
      heading: heading,
      timestamp: DateTime.now(),
    );

    addWaypoint(newPoint);
  }

  /// คำนวณความเร็วเฉลี่ย (กม./ชม.)
  double get averageSpeedKmh {
    if (_elapsedSeconds <= 0) return 0.0;
    final hours = _elapsedSeconds / 3600.0;
    return totalDistanceKm / hours;
  }

  /// อัตราความเร็วเพซ (Pace: นาทีต่อกิโลเมตร)
  String get currentPaceFormatted {
    if (_currentSpeedKmh <= 0.5) return "--:-- /km";
    final minutesPerKm = 60.0 / _currentSpeedKmh;
    final mins = minutesPerKm.floor();
    final secs = ((minutesPerKm - mins) * 60).round();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} /km';
  }

  /// จัดรูปแบบเวลาที่ใช้ (hh:mm:ss)
  String get formattedDuration {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// ส่งออกเส้นทางเป็นฟอร์แมต GeoJSON มาตรฐานสำหรับการวิเคราะห์ทางภูมิสารสนเทศ (GIS)
  String exportGeoJson() {
    final coordinates = _waypoints.map((wp) => [wp.longitude, wp.latitude, wp.altitude]).toList();
    final geoJsonMap = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': coordinates,
          },
          'properties': {
            'activity': _activityMode.label,
            'totalDistanceKm': totalDistanceKm,
            'durationSeconds': _elapsedSeconds,
            'avgSpeedKmh': averageSpeedKmh,
            'maxSpeedKmh': _maxSpeedKmh,
            'elevationGainM': _totalElevationGainMeters,
            'recordedAt': _startTime?.toIso8601String(),
          },
        }
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(geoJsonMap);
  }

  @override
  void dispose() {
    _hardwareGpsSubscription?.cancel();
    _trackingTimer?.cancel();
    _simulatedMovementTimer?.cancel();
    super.dispose();
  }
}
