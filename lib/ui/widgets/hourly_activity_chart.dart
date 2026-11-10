import 'package:flutter/material.dart';
import '../../models/daily_health_metric.dart';
import '../theme/health_theme.dart';

class HourlyActivityChart extends StatelessWidget {
  final List<HourlyMovementRecord> records;

  const HourlyActivityChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    int maxSteps = 1;
    for (final r in records) {
      if (r.steps > maxSteps) maxSteps = r.steps;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: HealthTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HealthTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: HealthTheme.emeraldStep, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'กิจกรรมการขยับร่างกาย 24 ชั่วโมง',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'บันทึกสถิติก้าวเดินในแต่ละช่วงเวลาของวัน',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Bar Chart Canvas
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: records.map((record) {
                final double factor = (record.steps / maxSteps).clamp(0.04, 1.0);
                final bool isPeak = record.steps > 0 && record.steps == maxSteps;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Tooltip(
                      message: '${record.hour}:00 - ${record.steps} ก้าว',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 70 * factor,
                            decoration: BoxDecoration(
                              color: isPeak
                                  ? HealthTheme.orangeCalorie
                                  : record.steps > 0
                                      ? HealthTheme.emeraldStep.withValues(alpha: 0.85)
                                      : HealthTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Timeline Hour Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('06:00', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('12:00', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('18:00', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('23:00', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
