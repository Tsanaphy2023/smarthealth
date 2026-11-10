import 'package:flutter/material.dart';
import '../theme/health_theme.dart';

class CadenceAndHydrationCard extends StatelessWidget {
  final int cadenceSpm;
  final double hydrationLossMl;
  final double tdeeKcal;
  final double bmrKcal;

  const CadenceAndHydrationCard({
    super.key,
    required this.cadenceSpm,
    required this.hydrationLossMl,
    required this.tdeeKcal,
    required this.bmrKcal,
  });

  String get cadenceZoneText {
    if (cadenceSpm == 0) return 'อยู่นิ่ง / พักผ่อน';
    if (cadenceSpm < 80) return 'เดินผ่อนคลาย (Light)';
    if (cadenceSpm < 100) return 'เดินทั่วไป (Moderate)';
    if (cadenceSpm < 120) return 'เดินเร็ว (Brisk Walk ⚡)';
    return 'วิ่งแอโรบิก (Aerobic 🔥)';
  }

  Color get cadenceZoneColor {
    if (cadenceSpm == 0) return Colors.white54;
    if (cadenceSpm < 100) return HealthTheme.cyanDistance;
    if (cadenceSpm < 120) return HealthTheme.emeraldStep;
    return HealthTheme.orangeCalorie;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HealthTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              const Icon(Icons.monitor_heart, color: HealthTheme.cyanDistance, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'จังหวะก้าว & สรีรวิทยาการฟื้นฟู',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'BIOMETRICS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2-Column Bento Modules: Cadence & Hydration
          Row(
            children: [
              // 1. Cadence Module
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HealthTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cadenceZoneColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_walk, color: cadenceZoneColor, size: 14),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'รอบก้าว (SPM)',
                              style: TextStyle(color: Colors.white60, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$cadenceSpm',
                                style: TextStyle(
                                  color: cadenceZoneColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const TextSpan(
                                text: ' SPM',
                                style: TextStyle(color: Colors.white54, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cadenceZoneText,
                        style: TextStyle(
                          color: cadenceZoneColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Hydration Balance Module
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HealthTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: HealthTheme.cyanDistance.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.water_drop, color: HealthTheme.cyanDistance, size: 14),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'เหงื่อ & น้ำชดเชย',
                              style: TextStyle(color: Colors.white60, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${hydrationLossMl.round()}',
                                style: const TextStyle(
                                  color: HealthTheme.cyanDistance,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const TextSpan(
                                text: ' ml',
                                style: TextStyle(color: Colors.white54, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ดื่มน้ำ ~${((hydrationLossMl + 350) / 250).ceil()} แก้ว',
                        style: const TextStyle(
                          color: HealthTheme.cyanDistance,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Total Daily Energy Expenditure (TDEE & BMR) Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: HealthTheme.surfaceCard.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: HealthTheme.orangeCalorie, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'การเผาผลาญรวมประจำวัน (TDEE)',
                        style: TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${tdeeKcal.round()} kcal/วัน (BMR ~${bmrKcal.round()})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
