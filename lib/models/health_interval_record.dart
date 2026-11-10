import 'dart:convert';

/// บันทึกสถิติสุขภาพรอบ 4 ชั่วโมง สำหรับการวิเคราะห์ด้วยปัญญาประดิษฐ์เชิงลึก
class HealthIntervalRecord {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int steps;
  final double distanceKm;
  final double caloriesKcal;
  final double hydrationMl;
  final int meanCadenceSpm;
  final int maxCadenceSpm;
  final int sedentaryMinutes;
  final double motionIntensity;
  final String aiDiagnosis;
  final double aiConfidence;

  HealthIntervalRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.steps,
    required this.distanceKm,
    required this.caloriesKcal,
    required this.hydrationMl,
    required this.meanCadenceSpm,
    required this.maxCadenceSpm,
    required this.sedentaryMinutes,
    required this.motionIntensity,
    required this.aiDiagnosis,
    required this.aiConfidence,
  });

  String get intervalLabel {
    final startH = startTime.hour.toString().padLeft(2, '0');
    final startM = startTime.minute.toString().padLeft(2, '0');
    final endH = endTime.hour.toString().padLeft(2, '0');
    final endM = endTime.minute.toString().padLeft(2, '0');
    return '$startH:$startM - $endH:$endM';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'steps': steps,
    'distanceKm': distanceKm,
    'caloriesKcal': caloriesKcal,
    'hydrationMl': hydrationMl,
    'meanCadenceSpm': meanCadenceSpm,
    'maxCadenceSpm': maxCadenceSpm,
    'sedentaryMinutes': sedentaryMinutes,
    'motionIntensity': motionIntensity,
    'aiDiagnosis': aiDiagnosis,
    'aiConfidence': aiConfidence,
  };

  factory HealthIntervalRecord.fromJson(Map<String, dynamic> json) => HealthIntervalRecord(
    id: json['id'] as String? ?? '',
    startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ?? DateTime.now(),
    endTime: DateTime.tryParse(json['endTime'] as String? ?? '') ?? DateTime.now(),
    steps: (json['steps'] as num?)?.toInt() ?? 0,
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
    caloriesKcal: (json['caloriesKcal'] as num?)?.toDouble() ?? 0.0,
    hydrationMl: (json['hydrationMl'] as num?)?.toDouble() ?? 0.0,
    meanCadenceSpm: (json['meanCadenceSpm'] as num?)?.toInt() ?? 0,
    maxCadenceSpm: (json['maxCadenceSpm'] as num?)?.toInt() ?? 0,
    sedentaryMinutes: (json['sedentaryMinutes'] as num?)?.toInt() ?? 0,
    motionIntensity: (json['motionIntensity'] as num?)?.toDouble() ?? 0.0,
    aiDiagnosis: json['aiDiagnosis'] as String? ?? 'ปกติสมดุล',
    aiConfidence: (json['aiConfidence'] as num?)?.toDouble() ?? 0.95,
  );

  static String encodeList(List<HealthIntervalRecord> list) =>
      jsonEncode(list.map((i) => i.toJson()).toList());

  static List<HealthIntervalRecord> decodeList(String jsonStr) {
    if (jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => HealthIntervalRecord.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
