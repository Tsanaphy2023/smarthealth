import 'package:flutter/material.dart';
import '../theme/health_theme.dart';

class LiveMotionGauge extends StatelessWidget {
  final double intensity; // 0.0 to 1.0
  final bool isSensorLive;

  const LiveMotionGauge({
    super.key,
    required this.intensity,
    required this.isSensorLive,
  });

  @override
  Widget build(BuildContext context) {
    final double clamped = intensity.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: HealthTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HealthTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.vibration,
                size: 16,
                color: isSensorLive ? HealthTheme.emeraldStep : HealthTheme.orangeCalorie,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'การขยับร่างกาย (Motion Intensity)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSensorLive
                      ? HealthTheme.emeraldStep.withValues(alpha: 0.15)
                      : HealthTheme.orangeCalorie.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSensorLive ? 'Live Sensor' : 'Active Mode',
                  style: TextStyle(
                    color: isSensorLive ? HealthTheme.emeraldStep : HealthTheme.orangeCalorie,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Intensity Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 10,
              width: double.infinity,
              color: HealthTheme.surfaceElevated,
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: clamped,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            HealthTheme.emeraldStep,
                            clamped > 0.5 ? HealthTheme.orangeCalorie : HealthTheme.cyanDistance,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'อยู่นิ่ง',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  'ระดับ ${(clamped * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Flexible(
                child: Text(
                  'เคลื่อนไหวเร็ว',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
