class DepartmentOkrSummary {
  final String department;
  final int staffCount;
  final int totalSteps;
  final int avgStepsPerPerson;
  final double totalDistanceKm;
  final double totalCaloriesKcal;
  final double percentOfFaculty;

  const DepartmentOkrSummary({
    required this.department,
    required this.staffCount,
    required this.totalSteps,
    required this.avgStepsPerPerson,
    required this.totalDistanceKm,
    required this.totalCaloriesKcal,
    required this.percentOfFaculty,
  });

  factory DepartmentOkrSummary.fromJson(Map<String, dynamic> json) {
    return DepartmentOkrSummary(
      department: (json['department'] ?? '').toString(),
      staffCount: (json['staff_count'] as num?)?.toInt() ?? 1,
      totalSteps: (json['total_steps'] as num?)?.toInt() ?? 0,
      avgStepsPerPerson: (json['avg_steps_per_person'] as num?)?.toInt() ?? 0,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      totalCaloriesKcal: (json['total_calories_kcal'] as num?)?.toDouble() ?? 0.0,
      percentOfFaculty: (json['percent_of_faculty'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StaffLeaderboardEntry {
  final int rank;
  final String staffId;
  final String fullName;
  final String department;
  final String positionTitle;
  final String appEdition;
  final int priorFiscalSteps;
  final int todaySteps;

  const StaffLeaderboardEntry({
    required this.rank,
    required this.staffId,
    required this.fullName,
    required this.department,
    required this.positionTitle,
    required this.appEdition,
    required this.priorFiscalSteps,
    required this.todaySteps,
  });

  int get totalSteps => priorFiscalSteps + todaySteps;
  double get totalDistanceKm => totalSteps * 0.00072;
  double get totalCaloriesKcal => totalSteps * 0.042;

  StaffLeaderboardEntry copyWith({
    int? rank,
    String? fullName,
    String? department,
    String? positionTitle,
    String? appEdition,
    int? priorFiscalSteps,
    int? todaySteps,
  }) {
    return StaffLeaderboardEntry(
      rank: rank ?? this.rank,
      staffId: staffId,
      fullName: fullName ?? this.fullName,
      department: department ?? this.department,
      positionTitle: positionTitle ?? this.positionTitle,
      appEdition: appEdition ?? this.appEdition,
      priorFiscalSteps: priorFiscalSteps ?? this.priorFiscalSteps,
      todaySteps: todaySteps ?? this.todaySteps,
    );
  }
}

class FacultyOkrSummary {
  static const int targetSteps2570 = 10000000; // 10 ล้านก้าว
  static const int fiscalYear2570 = 2570;

  static const List<String> sciRbruDepartments = [
    'สาขาวิชาฟิสิกส์',
    'สาขาวิชาวิทยาการคอมพิวเตอร์และเทคโนโลยีดิจิทัล',
    'สาขาวิชาเคมี',
    'สาขาวิชาชีววิทยา',
    'สาขาวิชาคณิตศาสตร์และสถิติ',
    'สาขาวิชาวิทยาศาสตร์สิ่งแวดล้อม',
    'สาขาวิชาเทคโนโลยีการเกษตร',
    'สาขาวิชาคหกรรมศาสตร์',
    'สำนักงานคณบดีคณะวิทยาศาสตร์และเทคโนโลยี',
  ];

  final int totalFacultySteps;
  final int totalStaffCount;
  final int activeTodayCount;
  final List<DepartmentOkrSummary> departments;
  final List<StaffLeaderboardEntry> leaderboard;
  final DateTime lastSyncedAt;

  const FacultyOkrSummary({
    required this.totalFacultySteps,
    required this.totalStaffCount,
    required this.activeTodayCount,
    required this.departments,
    required this.leaderboard,
    required this.lastSyncedAt,
  });

  int get remainingSteps =>
      (targetSteps2570 - totalFacultySteps).clamp(0, targetSteps2570);

  double get progressRatio =>
      (totalFacultySteps / targetSteps2570).clamp(0.0, 1.0);

  double get progressPercent => progressRatio * 100.0;

  int get avgStepsPerStaff =>
      totalStaffCount > 0 ? (totalFacultySteps / totalStaffCount).round() : 0;

  double get totalDistanceKm => totalFacultySteps * 0.00072;
  double get totalCaloriesKcal => totalFacultySteps * 0.042;
}

