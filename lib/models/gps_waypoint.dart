import 'dart:math';

/// โมเดลพิกัดตำแหน่งทางภูมิศาสตร์ (GPS Waypoint) สำหรับการบันทึกเส้นทางเดินและวิ่งจริง
class GpsWaypoint {
  final double latitude;
  final double longitude;
  final double altitude; // เมตร
  final double accuracy; // เมตร (+/-)
  final double speedKmh; // กิโลเมตรต่อชั่วโมง
  final double heading; // องศา (0 - 360)
  final DateTime timestamp;

  const GpsWaypoint({
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.accuracy = 5.0,
    this.speedKmh = 0.0,
    this.heading = 0.0,
    required this.timestamp,
  });

  /// รัศมีเฉลี่ยของโลก (Earth Mean Radius) ในหน่วยเมตร
  static const double earthRadiusMeters = 6371000.0;

  /// คำนวณระยะทางภูมิศาสตร์ผิวโค้งวงกลมใหญ่ (Great-Circle Distance) ด้วยสูตร Haversine
  double distanceTo(GpsWaypoint other) {
    final double phi1 = latitude * (pi / 180.0);
    final double phi2 = other.latitude * (pi / 180.0);
    final double deltaPhi = (other.latitude - latitude) * (pi / 180.0);
    final double deltaLambda = (other.longitude - longitude) * (pi / 180.0);

    final double a = sin(deltaPhi / 2.0) * sin(deltaPhi / 2.0) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2.0) * sin(deltaLambda / 2.0);

    final double c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a));
    return earthRadiusMeters * c;
  }

  /// คำนวณมุมทิศทางเชิงราบ (Azimuth / Bearing) ระหว่างสองจุดในหน่วยองศา (0 - 360)
  double bearingTo(GpsWaypoint other) {
    final double phi1 = latitude * (pi / 180.0);
    final double phi2 = other.latitude * (pi / 180.0);
    final double deltaLambda = (other.longitude - longitude) * (pi / 180.0);

    final double y = sin(deltaLambda) * cos(phi2);
    final double x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);
    final double theta = atan2(y, x);
    final double bearingDegrees = (theta * 180.0 / pi + 360.0) % 360.0;
    return bearingDegrees;
  }

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
        'alt': altitude,
        'acc': accuracy,
        'speed': speedKmh,
        'head': heading,
        'time': timestamp.toIso8601String(),
      };

  factory GpsWaypoint.fromJson(Map<String, dynamic> json) {
    return GpsWaypoint(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lng'] as num).toDouble(),
      altitude: (json['alt'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['acc'] as num?)?.toDouble() ?? 5.0,
      speedKmh: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['head'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'GpsWaypoint(lat: ${latitude.toStringAsFixed(6)}, lng: ${longitude.toStringAsFixed(6)}, speed: ${speedKmh.toStringAsFixed(1)} km/h)';
  }
}
