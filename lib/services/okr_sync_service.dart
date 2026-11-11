import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/okr_faculty_model.dart';

class OkrSyncService {
  static final OkrSyncService _instance = OkrSyncService._internal();
  factory OkrSyncService() => _instance;
  OkrSyncService._internal();

  static const String _keyStaffId = 'okr_staff_id';
  static const String _keyStaffName = 'okr_staff_name';
  static const String _keyStaffDept = 'okr_staff_department';
  static const String _keyStaffPos = 'okr_staff_position';
  static const String _keyApiUrl = 'okr_server_api_url';
  static const String _keyAutoSync = 'okr_auto_sync_enabled';

  String _staffId = 'SCI-001';
  String _fullName = 'ผศ.ดร.ชีวะ ทัศนา';
  String _department = 'สาขาวิชาฟิสิกส์';
  String _positionTitle = 'ผู้ช่วยศาสตราจารย์';
  String _serverApiUrl = 'http://localhost/smart_health_tracker/api.php';
  bool _autoSyncEnabled = true;
  DateTime _lastSyncedAt = DateTime.now();

  late List<StaffLeaderboardEntry> _staffRoster = _buildInitial64StaffRoster();

  String get staffId => _staffId;
  String get fullName => _fullName;
  String get department => _department;
  String get positionTitle => _positionTitle;
  String get serverApiUrl => _serverApiUrl;
  bool get autoSyncEnabled => _autoSyncEnabled;
  DateTime get lastSyncedAt => _lastSyncedAt;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _staffId = prefs.getString(_keyStaffId) ?? 'SCI-001';
      _fullName = prefs.getString(_keyStaffName) ?? 'ผศ.ดร.ชีวะ ทัศนา';
      _department = prefs.getString(_keyStaffDept) ?? 'สาขาวิชาฟิสิกส์';
      _positionTitle = prefs.getString(_keyStaffPos) ?? 'ผู้ช่วยศาสตราจารย์';
      _serverApiUrl =
          prefs.getString(_keyApiUrl) ?? 'http://localhost/smart_health_tracker/api.php';
      _autoSyncEnabled = prefs.getBool(_keyAutoSync) ?? true;
    } catch (_) {}
    _staffRoster = _buildInitial64StaffRoster();
  }

  Future<void> updateStaffRegistration({
    required String staffId,
    required String fullName,
    required String department,
    required String positionTitle,
    String? serverApiUrl,
    bool? autoSyncEnabled,
    required int currentTodaySteps,
    required String appEdition,
  }) async {
    _staffId = staffId.trim().isEmpty ? 'SCI-001' : staffId.trim().toUpperCase();
    _fullName = fullName.trim().isEmpty ? 'ผศ.ดร.ชีวะ ทัศนา' : fullName.trim();
    _department = department;
    _positionTitle =
        positionTitle.trim().isEmpty ? 'อาจารย์/บุคลากร' : positionTitle.trim();
    if (serverApiUrl != null && serverApiUrl.trim().isNotEmpty) {
      _serverApiUrl = serverApiUrl.trim();
    }
    if (autoSyncEnabled != null) {
      _autoSyncEnabled = autoSyncEnabled;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyStaffId, _staffId);
      await prefs.setString(_keyStaffName, _fullName);
      await prefs.setString(_keyStaffDept, _department);
      await prefs.setString(_keyStaffPos, _positionTitle);
      await prefs.setString(_keyApiUrl, _serverApiUrl);
      await prefs.setBool(_keyAutoSync, _autoSyncEnabled);
    } catch (_) {}

    syncStaffSteps(
      todaySteps: currentTodaySteps,
      appEdition: appEdition,
    );
  }

  /// ซิงค์จำนวนก้าวเดินของบุคลากรเข้าสู่ฐานข้อมูลกลาง OKR Key Result 3.2 (64+ คน)
  FacultyOkrSummary syncStaffSteps({
    required int todaySteps,
    required String appEdition,
  }) {
    _lastSyncedAt = DateTime.now();

    final idx = _staffRoster.indexWhere(
      (e) => e.staffId.toUpperCase() == _staffId.toUpperCase(),
    );

    if (idx >= 0) {
      final existing = _staffRoster[idx];
      _staffRoster[idx] = existing.copyWith(
        fullName: _fullName,
        department: _department,
        positionTitle: _positionTitle,
        appEdition: appEdition,
        todaySteps: todaySteps > 0 ? todaySteps : existing.todaySteps,
      );
    } else {
      // เพิ่มบุคลากรรายใหม่เข้าสู่ทะเบียนคณะวิทยาศาสตร์ฯ (> 60 คน)
      _staffRoster.add(
        StaffLeaderboardEntry(
          rank: _staffRoster.length + 1,
          staffId: _staffId,
          fullName: _fullName,
          department: _department,
          positionTitle: _positionTitle,
          appEdition: appEdition,
          priorFiscalSteps: 68500,
          todaySteps: todaySteps,
        ),
      );
    }

    return buildCurrentOkrSummary(
      currentUserTodaySteps: todaySteps,
      appEdition: appEdition,
    );
  }

  FacultyOkrSummary buildCurrentOkrSummary({
    required int currentUserTodaySteps,
    required String appEdition,
  }) {
    final List<StaffLeaderboardEntry> updatedList = [];
    for (final item in _staffRoster) {
      if (item.staffId.toUpperCase() == _staffId.toUpperCase()) {
        updatedList.add(
          item.copyWith(
            fullName: _fullName,
            department: _department,
            positionTitle: _positionTitle,
            appEdition: appEdition,
            todaySteps: currentUserTodaySteps > 0
                ? (item.todaySteps > currentUserTodaySteps
                    ? item.todaySteps
                    : currentUserTodaySteps)
                : item.todaySteps,
          ),
        );
      } else {
        updatedList.add(item);
      }
    }

    updatedList.sort((a, b) => b.totalSteps.compareTo(a.totalSteps));

    final List<StaffLeaderboardEntry> rankedList = [];
    int totalFacultySteps = 0;
    int activeToday = 0;

    for (int i = 0; i < updatedList.length; i++) {
      final entry = updatedList[i].copyWith(rank: i + 1);
      rankedList.add(entry);
      totalFacultySteps += entry.totalSteps;
      if (entry.todaySteps > 0) activeToday++;
    }

    // คำนวณสรุปแยกตาม 9 สาขาวิชา/หน่วยงานในคณะวิทยาศาสตร์และเทคโนโลยี
    final Map<String, List<StaffLeaderboardEntry>> deptGroups = {};
    for (final dept in FacultyOkrSummary.sciRbruDepartments) {
      deptGroups[dept] = [];
    }
    for (final entry in rankedList) {
      deptGroups.putIfAbsent(entry.department, () => []).add(entry);
    }

    final List<DepartmentOkrSummary> deptSummaries = [];
    deptGroups.forEach((deptName, members) {
      if (members.isEmpty) return;
      final dSteps = members.fold<int>(0, (sum, m) => sum + m.totalSteps);
      final dDist = dSteps * 0.00072;
      final dKcal = dSteps * 0.042;
      final pct = totalFacultySteps > 0 ? (dSteps / totalFacultySteps) * 100.0 : 0.0;
      deptSummaries.add(
        DepartmentOkrSummary(
          department: deptName,
          staffCount: members.length,
          totalSteps: dSteps,
          avgStepsPerPerson: (dSteps / members.length).round(),
          totalDistanceKm: dDist,
          totalCaloriesKcal: dKcal,
          percentOfFaculty: pct,
        ),
      );
    });

    deptSummaries.sort((a, b) => b.totalSteps.compareTo(a.totalSteps));

    return FacultyOkrSummary(
      totalFacultySteps: totalFacultySteps,
      totalStaffCount: rankedList.length,
      activeTodayCount: activeToday,
      departments: deptSummaries,
      leaderboard: rankedList,
      lastSyncedAt: _lastSyncedAt,
    );
  }

  StaffLeaderboardEntry getCurrentStaffEntry(FacultyOkrSummary summary) {
    return summary.leaderboard.firstWhere(
      (e) => e.staffId.toUpperCase() == _staffId.toUpperCase(),
      orElse: () => summary.leaderboard.first,
    );
  }

  /// สร้างข้อมูล JSON Payload มาตรฐานสำหรับส่งเข้า REST API (`api.php?action=okr_sync`)
  String buildSyncJsonPayload({
    required int todaySteps,
    required double distanceKm,
    required double caloriesKcal,
    required int activeMinutes,
    required int dailyGoal,
    required String appEdition,
    required Map<int, int> hourlySteps,
  }) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return jsonEncode({
      'staff_id': _staffId,
      'full_name': _fullName,
      'department': _department,
      'position_title': _positionTitle,
      'app_edition': appEdition,
      'daily_goal': dailyGoal,
      'fiscal_year': 2570,
      'record_date': dateStr,
      'steps': todaySteps,
      'distance_km': distanceKm,
      'calories_kcal': caloriesKcal,
      'active_minutes': activeMinutes,
      'hourly': hourlySteps.map((k, v) => MapEntry(k.toString(), v)),
    });
  }

  /// สร้างรายงานสรุปผลการดำเนินงาน OKR Key Result 3.2 (รูปแบบตารางรายงานและ CSV)
  String generateOfficialOkrReport(FacultyOkrSummary summary) {
    final buffer = StringBuffer();
    buffer.writeln('=============================================================');
    buffer.writeln('🏆 รายงานฐานข้อมูลกลาง OKR Key Result 3.2 (ปีงบประมาณ 2570)');
    buffer.writeln('คณะวิทยาศาสตร์และเทคโนโลยี มหาวิทยาลัยราชภัฏรำไพพรรณี');
    buffer.writeln('ตัวชี้วัด: ก้าวสะสมรวมของบุคลากรในคณะ มากกว่า 10,000,000 ก้าว');
    buffer.writeln('=============================================================');
    buffer.writeln(
      '• ก้าวสะสมรวมทั้งคณะปัจจุบัน: ${_formatInt(summary.totalFacultySteps)} / 10,000,000 ก้าว (${summary.progressPercent.toStringAsFixed(2)}%)',
    );
    buffer.writeln(
      '• จำนวนก้าวคงเหลือสู่เป้าหมาย 10 ล้านก้าว: ${_formatInt(summary.remainingSteps)} ก้าว',
    );
    buffer.writeln(
      '• จำนวนบุคลากรที่ลงทะเบียนในฐานข้อมูล: ${summary.totalStaffCount} คน (เกณฑ์ > 60 คน)',
    );
    buffer.writeln(
      '• ค่าเฉลี่ยก้าวสะสมต่อบุคลากร: ${_formatInt(summary.avgStepsPerStaff)} ก้าว/คน',
    );
    buffer.writeln(
      '• ระยะทางสะสมรวมทั้งคณะ: ${summary.totalDistanceKm.toStringAsFixed(1)} กม. | พลังงานสะสม: ${_formatInt(summary.totalCaloriesKcal.round())} kcal',
    );
    buffer.writeln('-------------------------------------------------------------');
    buffer.writeln('📊 สรุปแยกตามสาขาวิชา / หน่วยงาน (9 หน่วยงาน):');
    for (int i = 0; i < summary.departments.length; i++) {
      final d = summary.departments[i];
      buffer.writeln(
        '  ${i + 1}. ${d.department} (${d.staffCount} คน): รวม ${_formatInt(d.totalSteps)} ก้าว (เฉลี่ย ${_formatInt(d.avgStepsPerPerson)} ก้าว/คน • ${d.percentOfFaculty.toStringAsFixed(1)}%)',
      );
    }
    buffer.writeln('-------------------------------------------------------------');
    buffer.writeln('🥇 ตัวอย่างอันดับบุคลากรสูงสุด 10 อันดับแรก (จากทั้งหมด ${summary.totalStaffCount} คน):');
    for (int i = 0; i < summary.leaderboard.length && i < 10; i++) {
      final s = summary.leaderboard[i];
      buffer.writeln(
        '  #${s.rank} [${s.staffId}] ${s.fullName} (${s.department}) — สะสม ${_formatInt(s.totalSteps)} ก้าว (วันนี้ +${_formatInt(s.todaySteps)} ก้าว)',
      );
    }
    buffer.writeln('=============================================================');
    return buffer.toString();
  }

  String _formatInt(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  /// ทะเบียนบุคลากรตั้งต้น 64 ท่าน ของคณะวิทยาศาสตร์และเทคโนโลยี มรภ.รำไพพรรณี
  List<StaffLeaderboardEntry> _buildInitial64StaffRoster() {
    const depts = FacultyOkrSummary.sciRbruDepartments;
    final List<StaffLeaderboardEntry> list = [
      const StaffLeaderboardEntry(
        rank: 1,
        staffId: 'SCI-001',
        fullName: 'ผศ.ดร.ชีวะ ทัศนา',
        department: 'สาขาวิชาฟิสิกส์',
        positionTitle: 'ผู้ช่วยศาสตราจารย์',
        appEdition: 'SciRBRU Move+AI',
        priorFiscalSteps: 118500,
        todaySteps: 6420,
      ),
      const StaffLeaderboardEntry(
        rank: 2,
        staffId: 'SCI-002',
        fullName: 'รศ.ดร.กิตติพงศ์ วงศ์สวัสดิ์',
        department: 'สาขาวิชาฟิสิกส์',
        positionTitle: 'รองศาสตราจารย์',
        appEdition: 'ChewaPulse xAI',
        priorFiscalSteps: 92400,
        todaySteps: 6000,
      ),
      const StaffLeaderboardEntry(
        rank: 3,
        staffId: 'SCI-003',
        fullName: 'ผศ.ดร.นภัสสร ศรีสุวรรณ',
        department: 'สาขาวิชาวิทยาการคอมพิวเตอร์และเทคโนโลยีดิจิทัล',
        positionTitle: 'ผู้ช่วยศาสตราจารย์',
        appEdition: 'SciRBRU Move+AI',
        priorFiscalSteps: 89400,
        todaySteps: 5800,
      ),
      const StaffLeaderboardEntry(
        rank: 4,
        staffId: 'SCI-004',
        fullName: 'ดร.ธนากร เจริญผล',
        department: 'สาขาวิชาวิทยาการคอมพิวเตอร์และเทคโนโลยีดิจิทัล',
        positionTitle: 'อาจารย์ ดร.',
        appEdition: 'SciRBRU Move+AI',
        priorFiscalSteps: 86200,
        todaySteps: 5600,
      ),
      const StaffLeaderboardEntry(
        rank: 5,
        staffId: 'SCI-005',
        fullName: 'ผศ.ดร.ปิยะนุช วัฒนากูล',
        department: 'สาขาวิชาเคมี',
        positionTitle: 'ผู้ช่วยศาสตราจารย์',
        appEdition: 'ChewaPulse xAI',
        priorFiscalSteps: 84100,
        todaySteps: 5400,
      ),
      const StaffLeaderboardEntry(
        rank: 6,
        staffId: 'SCI-006',
        fullName: 'ผศ.ดร.อภิชาติ รัตนโชติ',
        department: 'สาขาวิชาชีววิทยา',
        positionTitle: 'ผู้ช่วยศาสตราจารย์',
        appEdition: 'SciRBRU Move+AI',
        priorFiscalSteps: 82300,
        todaySteps: 5300,
      ),
      const StaffLeaderboardEntry(
        rank: 7,
        staffId: 'SCI-007',
        fullName: 'ดร.ศิริพร ทองดี',
        department: 'สาขาวิชาคณิตศาสตร์และสถิติ',
        positionTitle: 'อาจารย์ ดร.',
        appEdition: 'SciRBRU Move+AI',
        priorFiscalSteps: 80200,
        todaySteps: 5200,
      ),
      const StaffLeaderboardEntry(
        rank: 8,
        staffId: 'SCI-008',
        fullName: 'ผศ.ดร.วรพจน์ แสงจันทร์',
        department: 'สาขาวิชาเทคโนโลยีการเกษตร',
        positionTitle: 'ผู้ช่วยศาสตราจารย์',
        appEdition: 'ChewaPulse xAI',
        priorFiscalSteps: 79000,
        todaySteps: 5100,
      ),
      const StaffLeaderboardEntry(
        rank: 9,
        staffId: 'SCI-009',
        fullName: 'ดร.กัญญาณัฐ บุญญฤทธิ์',
        department: 'สาขาวิชาวิทยาศาสตร์สิ่งแวดล้อม',
        positionTitle: 'อาจารย์ ดร.',
        appEdition: 'SciRBRU Move+AI',
        priorFiscalSteps: 76900,
        todaySteps: 5000,
      ),
      const StaffLeaderboardEntry(
        rank: 10,
        staffId: 'SCI-010',
        fullName: 'ผศ.สุภาพร จันทร์เพ็ญ',
        department: 'สาขาวิชาคหกรรมศาสตร์',
        positionTitle: 'ผู้ช่วยศาสตราจารย์',
        appEdition: 'SciRBRU Move+AI',
        priorFiscalSteps: 74700,
        todaySteps: 4900,
      ),
    ];

    const firstNames = [
      'กมล', 'เกรียงไกร', 'จักรกฤษณ์', 'ชุติมา', 'ณัฐวุฒิ', 'ดวงใจ', 'ถาวร', 'ทวีศักดิ์', 'ธนพล', 'นันทนา',
      'บุญส่ง', 'ประเสริฐ', 'พงศกร', 'พิชญา', 'ภัทรพล', 'มงคล', 'ยุพิน', 'รัตนา', 'ลักขณา', 'วิชัย',
      'ศุภชัย', 'สมชาย', 'สมศรี', 'สุรศักดิ์', 'อนันต์', 'อรอนงค์', 'อาคม', 'อิทธิพล', 'อุไรวรรณ', 'เอกชัย',
      'กนกวรรณ', 'ขวัญใจ', 'จินตนา', 'ชลธิชา', 'ณัฐกานต์', 'ดารณี', 'ทิพวรรณ', 'นฤมล', 'เบญจมาศ', 'ปวีณา',
      'ผกามาศ', 'พิมพ์ใจ', 'มยุรี', 'เยาวลักษณ์', 'รุ่งทิพย์', 'วรรณา', 'ศิริลักษณ์', 'สายชล', 'สุกัญญา', 'หทัยรัตน์',
      'อัจฉรา', 'อารยา', 'อินทิรา', 'เอมอร'
    ];
    const lastNames = [
      'จันทบุรีรักษ์', 'บูรพาภิรมย์', 'รำไพพัฒน์', 'ศรีเมืองจันท์', 'วัฒนธรรม',
      'เจริญสุข', 'เกียรติขจร', 'พิทักษ์ผล', 'สว่างวงศ์', 'อุดมทรัพย์',
      'สายชลธาร', 'พงษ์พานิช', 'รัตนากร', 'วงศ์วิเศษ', 'สุวรรณโชติ',
      'อินทร์จันทร์', 'ทองคำ', 'บุญประเสริฐ', 'ชัยมงคล', 'สุขสวัสดิ์'
    ];

    for (int i = 11; i <= 64; i++) {
      final code = 'SCI-${i.toString().padLeft(3, '0')}';
      final fn = firstNames[(i - 11) % firstNames.length];
      final ln = lastNames[(i - 11) % lastNames.length];
      final dept = depts[(i - 1) % depts.length];
      final pos = (i % 9 == 0)
          ? 'นักวิทยาศาสตร์ชำนาญการ'
          : ((i % 8 == 0) ? 'เจ้าหน้าที่บริหารงานทั่วไป' : 'อาจารย์');
      final ed = (i % 3 == 0) ? 'ChewaPulse xAI' : 'SciRBRU Move+AI';
      int cumSteps = 71000 - ((i - 11) * 580);
      if (cumSteps < 36000) cumSteps = 36500 + (i * 110);
      final tSteps = 3800 + ((i * 137) % 3400);

      list.add(
        StaffLeaderboardEntry(
          rank: i,
          staffId: code,
          fullName: 'อ.$fn $ln',
          department: dept,
          positionTitle: pos,
          appEdition: ed,
          priorFiscalSteps: cumSteps - tSteps,
          todaySteps: tSteps,
        ),
      );
    }

    return list;
  }
}

