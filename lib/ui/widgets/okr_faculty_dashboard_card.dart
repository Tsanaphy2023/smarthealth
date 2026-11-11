import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/okr_faculty_model.dart';
import '../../services/movement_sensor_service.dart';
import '../../services/okr_sync_service.dart';
import '../theme/health_theme.dart';

class OkrFacultyDashboardCard extends StatelessWidget {
  final MovementSensorService sensor;

  const OkrFacultyDashboardCard({super.key, required this.sensor});

  String _formatNum(int val) {
    return val.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  void _openStaffRegistrationDialog(BuildContext context) {
    final okrService = OkrSyncService();
    final idCtrl = TextEditingController(text: okrService.staffId);
    final nameCtrl = TextEditingController(text: okrService.fullName);
    final posCtrl = TextEditingController(text: okrService.positionTitle);
    final urlCtrl = TextEditingController(text: okrService.serverApiUrl);
    String selectedDept = okrService.department;
    if (!FacultyOkrSummary.sciRbruDepartments.contains(selectedDept)) {
      selectedDept = FacultyOkrSummary.sciRbruDepartments.first;
    }
    bool autoSync = okrService.autoSyncEnabled;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final brand = sensor.brandEdition;
            return Dialog(
              backgroundColor: HealthTheme.surfaceCard,
              insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, color: brand.primaryColor, size: 22),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'ลงทะเบียนบุคลากร • OKR 3.2 (ปีงบ 2570)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, color: Colors.white54),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'รหัสบุคลากร (เช่น SCI-001 ถึง SCI-064 หรืออีเมล)',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: idCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: HealthTheme.surfaceElevated,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'ชื่อ-นามสกุล บุคลากร',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: nameCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: HealthTheme.surfaceElevated,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'สาขาวิชา / หน่วยงาน (คณะวิทยาศาสตร์และเทคโนโลยี)',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: selectedDept,
                                isExpanded: true,
                                dropdownColor: HealthTheme.surfaceElevated,
                                style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: HealthTheme.surfaceElevated,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: FacultyOkrSummary.sciRbruDepartments
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(
                                          d,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => selectedDept = val);
                                  }
                                },
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'ตำแหน่งทางวิชาการ / ตำแหน่งงาน',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: posCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: HealthTheme.surfaceElevated,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'URL ฐานข้อมูลกลางคณะฯ (REST API / Cloud Endpoint)',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: urlCtrl,
                                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: HealthTheme.surfaceElevated,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: autoSync,
                                activeColor: brand.primaryColor,
                                title: const Text(
                                  'ซิงค์ก้าวสะสมเข้าฐานข้อมูล OKR อัตโนมัติ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: const Text(
                                  'ส่งยอดก้าวเดินรายวันเข้าฐานข้อมูลกลางโดยอัตโนมัติ',
                                  style: TextStyle(color: Colors.white54, fontSize: 10.5),
                                ),
                                onChanged: (v) => setModalState(() => autoSync = v),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('ยกเลิก', style: TextStyle(color: Colors.white70)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brand.primaryColor,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () async {
                                await sensor.updateStaffOkrRegistration(
                                  staffId: idCtrl.text,
                                  fullName: nameCtrl.text,
                                  department: selectedDept,
                                  positionTitle: posCtrl.text,
                                  serverApiUrl: urlCtrl.text,
                                  autoSyncEnabled: autoSync,
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: HealthTheme.surfaceElevated,
                                      content: Text(
                                        'บันทึกข้อมูลบุคลากร [${idCtrl.text}] และซิงค์เข้าฐานข้อมูล OKR 3.2 สำเร็จ',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'บันทึก & ซิงค์ทันที',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openFullOkrLeaderboardDialog(BuildContext context, FacultyOkrSummary summary) {
    final brand = sensor.brandEdition;
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: HealthTheme.surfaceCard,
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, color: brand.primaryColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ฐานข้อมูล OKR 3.2 • บุคลากร ${summary.totalStaffCount} ท่าน (ปีงบ 2570)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📊 สรุปก้าวสะสมแยกตามสาขาวิชา / หน่วยงาน (9 หน่วยงาน)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...summary.departments.map(
                            (d) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: HealthTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.department,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'บุคลากร ${d.staffCount} คน • เฉลี่ย ${_formatNum(d.avgStepsPerPerson)} ก้าว/คน',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_formatNum(d.totalSteps)} ก้าว',
                                    style: TextStyle(
                                      color: brand.primaryColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '🥇 อันดับก้าวสะสมบุคลากรในคณะฯ (แสดง 15 อันดับแรกจาก ${summary.totalStaffCount} คน)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...summary.leaderboard.take(15).map(
                            (s) => Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: s.staffId == OkrSyncService().staffId
                                    ? brand.primaryColor.withValues(alpha: 0.16)
                                    : Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: s.staffId == OkrSyncService().staffId
                                      ? brand.primaryColor
                                      : Colors.white10,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '#${s.rank}',
                                      style: TextStyle(
                                        color: s.rank <= 3 ? HealthTheme.goldRBRU : Colors.white70,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${s.fullName} (${s.staffId})',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${s.department} • วันนี้ +${_formatNum(s.todaySteps)} ก้าว',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${_formatNum(s.totalSteps)} ก้าว',
                                    style: TextStyle(
                                      color: brand.secondaryColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brand.primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: () async {
                        final report = OkrSyncService().generateOfficialOkrReport(summary);
                        await Clipboard.setData(ClipboardData(text: report));
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'คัดลอกรายงานผลการดำเนินงาน OKR Key Result 3.2 (บุคลากร 64 คน) ลงคลิปบอร์ดแล้ว',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_all_rounded, size: 18),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'คัดลอกรายงานสรุปผล OKR 3.2 (ครบ 9 สาขา • 64 คน)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = sensor.brandEdition;
    final summary = sensor.okrSummary;
    final me = OkrSyncService().getCurrentStaffEntry(summary);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthTheme.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: brand.primaryColor.withValues(alpha: 0.45),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: brand.primaryColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: OKR Key Result 3.2 Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HealthTheme.goldRBRU.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: HealthTheme.goldRBRU,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'OKR Key Result 3.2 • คณะวิทยาศาสตร์ฯ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: HealthTheme.goldRBRU.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ปีงบ 2570',
                            style: TextStyle(
                              color: HealthTheme.goldRBRU,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'เป้าหมายก้าวสะสมรวมบุคลากร > 10,000,000 ก้าว (ลงทะเบียนแล้ว ${summary.totalStaffCount} คน)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 10 Million Steps Progress Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HealthTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'สะสมรวมคณะฯ: ${_formatNum(summary.totalFacultySteps)} / 10,000,000 ก้าว',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${summary.progressPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: brand.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: summary.progressRatio,
                    minHeight: 10,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(brand.primaryColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '👥 บุคลากร ${summary.totalStaffCount} คน (เดินวันนี้ ${summary.activeTodayCount} คน)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'เฉลี่ย ${_formatNum(summary.avgStepsPerStaff)} ก้าว/คน',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: brand.secondaryColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Current Staff Member Status Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brand.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_rounded, size: 16, color: brand.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[${me.staffId}] ${me.fullName} • ${me.department}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'สะสมปีงบ 2570: ${_formatNum(me.totalSteps)} ก้าว (อันดับ #${me.rank} ของคณะฯ)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Action Buttons Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brand.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final updated = sensor.syncStepsToFacultyOkr();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: HealthTheme.surfaceElevated,
                        content: Text(
                          'ซิงค์ก้าวเดินเข้าฐานข้อมูล OKR 3.2 สำเร็จ! ยอดรวมคณะฯ: ${_formatNum(updated.totalFacultySteps)} ก้าว',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.cloud_upload_rounded, size: 15),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'ซิงค์ก้าว OKR',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    side: BorderSide(color: brand.secondaryColor.withValues(alpha: 0.6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _openStaffRegistrationDialog(context),
                  icon: Icon(Icons.badge_outlined, size: 15, color: brand.secondaryColor),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'ตั้งค่าบุคลากร',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HealthTheme.goldRBRU,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    side: BorderSide(color: HealthTheme.goldRBRU.withValues(alpha: 0.6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _openFullOkrLeaderboardDialog(context, summary),
                  icon: const Icon(Icons.leaderboard_rounded, size: 15, color: HealthTheme.goldRBRU),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'ตาราง 64 คน',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

