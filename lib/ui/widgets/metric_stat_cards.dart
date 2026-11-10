import 'package:flutter/material.dart';
import '../../models/daily_health_metric.dart';
import '../theme/health_theme.dart';

class MetricStatCards extends StatelessWidget {
  final DailyHealthMetric metric;

  const MetricStatCards({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          // 1. Calories
          Expanded(
            child: _buildCard(
              icon: Icons.local_fire_department,
              iconColor: HealthTheme.orangeCalorie,
              title: 'แคลอรี',
              subtitle: 'CALORIES',
              value: metric.caloriesKcal.toStringAsFixed(0),
              unit: 'kcal',
            ),
          ),
          const SizedBox(width: 10),

          // 2. Distance
          Expanded(
            child: _buildCard(
              icon: Icons.place_outlined,
              iconColor: HealthTheme.cyanDistance,
              title: 'ระยะทาง',
              subtitle: 'DISTANCE',
              value: metric.distanceKm.toStringAsFixed(2),
              unit: 'กม.',
            ),
          ),
          const SizedBox(width: 10),

          // 3. Active Time
          Expanded(
            child: _buildCard(
              icon: Icons.timer_outlined,
              iconColor: HealthTheme.purpleTime,
              title: 'ขยับต่อเนื่อง',
              subtitle: 'ACTIVE TIME',
              value: '${metric.activeMinutes}',
              unit: 'นาที',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: HealthTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HealthTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
