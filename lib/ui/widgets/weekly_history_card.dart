import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_brand_edition.dart';
import '../../services/movement_sensor_service.dart';
import '../theme/health_theme.dart';

/// การ์ดแสดงสถิติสุขภาพย้อนหลัง 7 วัน (Weekly History & Trend Analytics)
/// พร้อมระบบบันทึกน้ำหนักตัวและส่งออกรายงานสรุปผลสุขภาพ
class WeeklyHistoryCard extends StatelessWidget {
  final MovementSensorService sensor;

  const WeeklyHistoryCard({super.key, required this.sensor});

  @override
  Widget build(BuildContext context) {
    final brand = sensor.brandEdition;
    final history = sensor.weeklyHistory;
    final int totalWeekSteps = history.fold(0, (sum, d) => sum + d.steps);
    final double avgSteps = history.isEmpty ? 0 : totalWeekSteps / history.length;
    final double totalWeekKcal = history.fold(0.0, (sum, d) => sum + d.caloriesKcal);
    final int daysGoalMet = history.where((d) => d.isGoalMet).length;

    int maxSteps = sensor.dailyGoal;
    for (final d in history) {
      if (d.steps > maxSteps) maxSteps = d.steps;
    }
    if (maxSteps < 1000) maxSteps = 10000;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HealthTheme.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: brand.primaryColor.withValues(alpha: 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: brand.primaryColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: brand.primaryColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.insights_rounded, color: brand.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'แนวโน้มสุขภาพย้อนหลัง 7 วัน',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'สะสมรวม $totalWeekSteps ก้าว • เฉลี่ย ${avgSteps.toStringAsFixed(0)} ก้าว/วัน',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showHealthReportDialog(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: brand.secondaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: brand.secondaryColor.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, color: brand.secondaryColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'รายงาน',
                        style: TextStyle(
                          color: brand.secondaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3 Summary Mini Badges
          Row(
            children: [
              Expanded(
                child: _buildSummaryChip(
                  label: 'บรรลุเป้าหมาย',
                  value: '$daysGoalMet / 7 วัน',
                  color: brand.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryChip(
                  label: 'เผาผลาญ 7 วัน',
                  value: '${totalWeekKcal.toStringAsFixed(0)} kcal',
                  color: brand.accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryChip(
                  label: 'น้ำหนักเป้าหมาย',
                  value: '${sensor.targetWeightKg.toStringAsFixed(1)} kg',
                  color: brand.secondaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 7-Day Bar Chart
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: history.asMap().entries.map((entry) {
                final int idx = entry.key;
                final DailyHistorySummary item = entry.value;
                final bool isToday = idx == history.length - 1;
                final double ratio = (item.steps / maxSteps).clamp(0.06, 1.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.steps >= 1000
                                ? '${(item.steps / 1000).toStringAsFixed(1)}k'
                                : '${item.steps}',
                            style: TextStyle(
                              color: isToday ? brand.primaryColor : Colors.white70,
                              fontSize: 9.5,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 82 * ratio,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isToday
                                  ? [brand.secondaryColor, brand.primaryColor]
                                  : item.isGoalMet
                                      ? [
                                          brand.primaryColor.withValues(alpha: 0.5),
                                          brand.primaryColor.withValues(alpha: 0.9),
                                        ]
                                      : [
                                          Colors.white.withValues(alpha: 0.15),
                                          Colors.white.withValues(alpha: 0.35),
                                        ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: isToday
                                ? Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.dayLabel,
                            style: TextStyle(
                              color: isToday ? brand.primaryColor : Colors.white60,
                              fontSize: 10,
                              fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: HealthTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthReportDialog(BuildContext context) {
    final reportText = sensor.generateHealthSummaryReport();
    final brand = sensor.brandEdition;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HealthTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.verified_user_rounded, color: brand.primaryColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'รายงานสุขภาพ • ${brand.appName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                reportText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: brand.primaryColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('คัดลอกรายงาน', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reportText));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: brand.primaryColor,
                  content: const Text(
                    'คัดลอกรายงานสรุปผลสุขภาพเรียบร้อยแล้ว สามารถวางส่งใน LINE หรือเอกสารได้ทันที',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
