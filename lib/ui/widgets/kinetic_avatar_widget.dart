import 'package:flutter/material.dart';
import '../../models/activity_type.dart';
import '../theme/health_theme.dart';

class KineticAvatarWidget extends StatefulWidget {
  final ActivityType activity;
  final double intensity; // 0.0 - 1.0
  final int cadenceSpm;

  const KineticAvatarWidget({
    super.key,
    required this.activity,
    required this.intensity,
    required this.cadenceSpm,
  });

  @override
  State<KineticAvatarWidget> createState() => _KineticAvatarWidgetState();
}

class _KineticAvatarWidgetState extends State<KineticAvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant KineticAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Speed up pulse animation if cadence or intensity is high
    if (widget.cadenceSpm > 0) {
      final periodMs = (60000 / widget.cadenceSpm.clamp(50, 180)).round();
      _pulseController.duration = Duration(milliseconds: periodMs);
    } else {
      _pulseController.duration = const Duration(milliseconds: 1400);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.activity.color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthTheme.surfaceElevated.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated Kinetic Hologram Silhouette
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.08 * (widget.intensity + 0.3));
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        themeColor.withValues(alpha: 0.35),
                        themeColor.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: themeColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      widget.activity == ActivityType.running
                          ? Icons.directions_run
                          : widget.activity == ActivityType.walking
                              ? Icons.directions_walk
                              : widget.activity == ActivityType.active
                                  ? Icons.bolt
                                  : Icons.accessibility_new,
                      color: themeColor,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),

          // Kinetic Biometrics Readout
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'สภาวะร่างกาย (KINETIC)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.60),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.activity.thaiLabel,
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      (widget.intensity * 10).toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'm/s²',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speed, color: themeColor, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              widget.cadenceSpm > 0 ? '${widget.cadenceSpm} SPM' : '0 SPM',
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Smooth Dynamic Motion Wave Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.intensity.clamp(0.05, 1.0),
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    minHeight: 4,
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
