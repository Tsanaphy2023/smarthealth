import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/daily_health_metric.dart';
import '../theme/health_theme.dart';

class ActivityRingProgress extends StatelessWidget {
  final DailyHealthMetric metric;
  final VoidCallback onGoalTap;

  const ActivityRingProgress({
    super.key,
    required this.metric,
    required this.onGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final double ratio = metric.progressRatio.clamp(0.0, 1.0);

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Stack(
          alignment: Alignment.center,
          children: [
          // Circular Ring Canvas
          CustomPaint(
            size: const Size(250, 250),
            painter: _RingPainter(
              progress: ratio,
              trackColor: HealthTheme.surfaceElevated,
              ringColor: HealthTheme.emeraldStep,
            ),
          ),

          // Center Stats Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current Activity Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: metric.currentActivity.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: metric.currentActivity.color, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(metric.currentActivity.icon, size: 14, color: metric.currentActivity.color),
                    const SizedBox(width: 6),
                    Text(
                      metric.currentActivity.nameTh,
                      style: TextStyle(
                        color: metric.currentActivity.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Main Step Number
              Text(
                numberFormat.format(metric.steps),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              const Text(
                'ก้าว (STEPS)',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              // Goal button
              GestureDetector(
                onTap: onGoalTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x991E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: HealthTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag_outlined, size: 12, color: HealthTheme.emeraldStep),
                      const SizedBox(width: 4),
                      Text(
                        'เป้าหมาย ${numberFormat.format(metric.stepGoal)} (${metric.progressPercent}%)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.edit, size: 10, color: Colors.white38),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color ringColor;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 18.0;

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progress arc
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      ringPaint,
    );

    // Glowing tip dot
    final tipAngle = startAngle + sweepAngle;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);

    final glowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(tipX, tipY), 4.5, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.trackColor != trackColor;
  }
}
