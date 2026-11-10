import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/activity_type.dart';
import '../../models/health_interval_record.dart';
import '../../services/movement_sensor_service.dart';
import '../../services/gps_tracking_service.dart';
import '../theme/health_theme.dart';
import '../widgets/activity_ring_progress.dart';
import '../widgets/cadence_and_hydration_card.dart';
import '../widgets/comprehensive_goals_dialog.dart';
import '../widgets/deep_ai_analytics_card.dart';
import '../widgets/gps_route_map_card.dart';
import '../widgets/hourly_activity_chart.dart';
import '../widgets/kinetic_avatar_widget.dart';
import '../widgets/live_motion_gauge.dart';
import '../widgets/metric_stat_cards.dart';
import '../widgets/profile_settings_dialog.dart';
import '../widgets/responsive_layout_builder.dart';
import '../widgets/sedentary_alert_banner.dart';

class HomeTrackerScreen extends StatefulWidget {
  const HomeTrackerScreen({super.key});

  @override
  State<HomeTrackerScreen> createState() => _HomeTrackerScreenState();
}

class _HomeTrackerScreenState extends State<HomeTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovementSensorService>().initialize();
    });
  }

  void _openComprehensiveGoalsDialog() {
    final sensor = context.read<MovementSensorService>();
    showDialog(
      context: context,
      builder: (_) => ComprehensiveGoalsDialog(sensor: sensor),
    );
  }

  void _openProfileDialog() {
    final sensor = context.read<MovementSensorService>();
    showDialog(
      context: context,
      builder: (_) => ProfileSettingsDialog(
        profile: sensor.profile,
        onSave: (newProfile) => sensor.updateProfile(newProfile),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HealthTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('รีเซ็ตสถิติทุกอย่างเป็น 0?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'ต้องการเริ่มนับก้าว คำนวณแคลอรี และรอบเวลาใหม่ทั้งหมดเป็น 0 หรือไม่?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: HealthTheme.orangeCalorie),
            onPressed: () {
              context.read<MovementSensorService>().resetAllToZero();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('รีเซ็ตทุกค่าเริ่มต้นเป็น 0 เรียบร้อยแล้ว')),
              );
            },
            child: const Text('รีเซ็ตเป็น 0', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<MovementSensorService>();
    final gpsService = context.watch<GpsTrackingService>();
    final metric = sensor.currentMetric;
    final now = DateTime.now();
    final dateStr = DateFormat('d MMMM yyyy').format(now);

    final Color ambientColor1 = metric.currentActivity == ActivityType.running
        ? const Color(0xFF2A0D0A)
        : metric.currentActivity == ActivityType.walking
            ? const Color(0xFF082015)
            : metric.currentActivity == ActivityType.active
                ? const Color(0xFF0C1929)
                : const Color(0xFF0D121F);

    return Scaffold(
      backgroundColor: HealthTheme.background,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ambientColor1,
              HealthTheme.background,
              HealthTheme.background,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: metric.currentActivity.color.withOpacity(0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: metric.currentActivity.color.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/app_icon.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SMART HEALTH TRACKER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '$dateStr • เป้าหมาย ${sensor.dailyGoal} ก้าว',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: (gpsService.isTracking ? HealthTheme.neonCyan : Colors.white).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (gpsService.isTracking ? HealthTheme.neonCyan : Colors.white).withOpacity(0.2),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.satellite_alt_rounded,
                                      size: 10,
                                      color: gpsService.isTracking ? HealthTheme.neonCyan : Colors.grey,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      gpsService.isTracking
                                          ? '${gpsService.totalDistanceKm.toStringAsFixed(2)} km'
                                          : 'GPS IDLE',
                                      style: TextStyle(
                                        color: gpsService.isTracking ? HealthTheme.neonCyan : Colors.grey,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'ตั้งค่าเป้าหมายสุขภาพ & ลดน้ำหนัก',
                      onPressed: _openComprehensiveGoalsDialog,
                      icon: const Icon(Icons.tune, color: HealthTheme.cyanPrimary),
                    ),
                    IconButton(
                      tooltip: 'โปรไฟล์สรีรวิทยา',
                      onPressed: _openProfileDialog,
                      icon: const Icon(Icons.person_outline, color: HealthTheme.cyanDistance),
                    ),
                    IconButton(
                      tooltip: 'รีเซ็ตข้อมูลเป็น 0',
                      onPressed: _confirmReset,
                      icon: const Icon(Icons.restart_alt, color: HealthTheme.orangeCalorie),
                    ),
                  ],
                ),
              ),

              // Responsive Body Container
              Expanded(
                child: ResponsiveLayoutBuilder(
                  builder: (context, breakpoint, constraints) {
                    if (breakpoint == ResponsiveBreakpoint.expanded) {
                      return _buildExpandedLayout(sensor, metric, gpsService);
                    } else if (breakpoint == ResponsiveBreakpoint.medium) {
                      return _buildMediumLayout(sensor, metric, gpsService);
                    } else {
                      return _buildCompactLayout(sensor, metric, gpsService);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact Layout (< 600dp) - Mobile Phones
  Widget _buildCompactLayout(
      MovementSensorService sensor, dynamic metric, GpsTrackingService gpsService) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        children: [
          if (metric.needsActiveBreak)
            SedentaryAlertBanner(
              sedentaryMinutes: metric.sedentaryMinutes,
              onDismiss: () => sensor.dismissActiveBreak(),
            ),
          const SizedBox(height: 6),
          ActivityRingProgress(metric: metric, onGoalTap: _openComprehensiveGoalsDialog),
          const SizedBox(height: 18),
          KineticAvatarWidget(
            activity: metric.currentActivity,
            intensity: metric.motionIntensity,
            cadenceSpm: metric.cadenceSpm,
          ),
          const SizedBox(height: 16),
          // Deep Learning AI Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DeepAiAnalyticsCard(sensor: sensor),
          ),
          const SizedBox(height: 16),
          // GPS Live Route Map Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GpsRouteMapCard(
              gpsService: gpsService,
              pedometerDistanceKm: metric.distanceKm,
            ),
          ),
          const SizedBox(height: 16),
          MetricStatCards(metric: metric),
          const SizedBox(height: 16),
          CadenceAndHydrationCard(
            cadenceSpm: metric.cadenceSpm,
            hydrationLossMl: metric.hydrationLostMl,
            tdeeKcal: metric.tdeeKcal,
            bmrKcal: sensor.profile.bmrKcal,
          ),
          const SizedBox(height: 16),
          // 4-Hour Interval Snapshot History
          _buildIntervalHistorySection(sensor),
          const SizedBox(height: 16),
          LiveMotionGauge(intensity: metric.motionIntensity, isSensorLive: sensor.isSensorActive),
          const SizedBox(height: 16),
          HourlyActivityChart(records: sensor.hourlyRecords),
          const SizedBox(height: 20),
          _buildControls(sensor),
        ],
      ),
    );
  }

  /// Medium Layout (600 - 840dp) - Foldable Phones / Tablets Portrait
  Widget _buildMediumLayout(
      MovementSensorService sensor, dynamic metric, GpsTrackingService gpsService) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          if (metric.needsActiveBreak)
            SedentaryAlertBanner(
              sedentaryMinutes: metric.sedentaryMinutes,
              onDismiss: () => sensor.dismissActiveBreak(),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    ActivityRingProgress(metric: metric, onGoalTap: _openComprehensiveGoalsDialog),
                    const SizedBox(height: 16),
                    KineticAvatarWidget(
                      activity: metric.currentActivity,
                      intensity: metric.motionIntensity,
                      cadenceSpm: metric.cadenceSpm,
                    ),
                    const SizedBox(height: 16),
                    DeepAiAnalyticsCard(sensor: sensor),
                    const SizedBox(height: 16),
                    GpsRouteMapCard(
                      gpsService: gpsService,
                      pedometerDistanceKm: metric.distanceKm,
                    ),
                    const SizedBox(height: 16),
                    LiveMotionGauge(intensity: metric.motionIntensity, isSensorLive: sensor.isSensorActive),
                    const SizedBox(height: 16),
                    _buildControls(sensor),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right Column
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    MetricStatCards(metric: metric),
                    const SizedBox(height: 16),
                    CadenceAndHydrationCard(
                      cadenceSpm: metric.cadenceSpm,
                      hydrationLossMl: metric.hydrationLostMl,
                      tdeeKcal: metric.tdeeKcal,
                      bmrKcal: sensor.profile.bmrKcal,
                    ),
                    const SizedBox(height: 16),
                    _buildIntervalHistorySection(sensor),
                    const SizedBox(height: 16),
                    HourlyActivityChart(records: sensor.hourlyRecords),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Expanded Layout (> 840dp) - Large Tablets / Landscape / Web
  Widget _buildExpandedLayout(
      MovementSensorService sensor, dynamic metric, GpsTrackingService gpsService) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          if (metric.needsActiveBreak)
            SedentaryAlertBanner(
              sedentaryMinutes: metric.sedentaryMinutes,
              onDismiss: () => sensor.dismissActiveBreak(),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Ring & Profile Summary
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    ActivityRingProgress(metric: metric, onGoalTap: _openComprehensiveGoalsDialog),
                    const SizedBox(height: 18),
                    _buildProfileSummaryCard(sensor),
                    const SizedBox(height: 18),
                    _buildControls(sensor),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Column 2: Kinetic Motion, AI Engine & GPS Route Map
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    KineticAvatarWidget(
                      activity: metric.currentActivity,
                      intensity: metric.motionIntensity,
                      cadenceSpm: metric.cadenceSpm,
                    ),
                    const SizedBox(height: 16),
                    DeepAiAnalyticsCard(sensor: sensor),
                    const SizedBox(height: 16),
                    GpsRouteMapCard(
                      gpsService: gpsService,
                      pedometerDistanceKm: metric.distanceKm,
                    ),
                    const SizedBox(height: 16),
                    CadenceAndHydrationCard(
                      cadenceSpm: metric.cadenceSpm,
                      hydrationLossMl: metric.hydrationLostMl,
                      tdeeKcal: metric.tdeeKcal,
                      bmrKcal: sensor.profile.bmrKcal,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Column 3: Metrics & 4h Interval History
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    MetricStatCards(metric: metric),
                    const SizedBox(height: 16),
                    _buildIntervalHistorySection(sensor),
                    const SizedBox(height: 16),
                    LiveMotionGauge(intensity: metric.motionIntensity, isSensorLive: sensor.isSensorActive),
                    const SizedBox(height: 16),
                    HourlyActivityChart(records: sensor.hourlyRecords),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 4-Hour Interval Snapshot History Section
  Widget _buildIntervalHistorySection(MovementSensorService sensor) {
    final intervals = sensor.intervalRecords;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HealthTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.history_toggle_off, color: HealthTheme.goldRBRU, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'สถิติบันทึกอัตโนมัติรอบ 4 ชม.',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${intervals.length} รายการ',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (intervals.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              alignment: Alignment.center,
              child: Text(
                'ระบบจะบันทึกสแน็ปช็อตอัตโนมัติทุก 4 ชั่วโมง\nหรือกด "บันทึกรอบ 4 ชม." ในการ์ด AI เพื่อทดสอบได้ทันที',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 11.5, height: 1.5),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: intervals.length.clamp(0, 3),
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 14),
              itemBuilder: (context, idx) {
                final item = intervals[idx];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: HealthTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.intervalLabel,
                        style: const TextStyle(color: HealthTheme.cyanPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.steps} ก้าว • ${item.caloriesKcal.toStringAsFixed(0)} kcal • Cadence ${item.meanCadenceSpm} SPM',
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'AI: ${item.aiDiagnosis}',
                            style: const TextStyle(color: HealthTheme.goldRBRU, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.distanceKm.toStringAsFixed(2)} กม.',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  /// Profile Summary Bento Box
  Widget _buildProfileSummaryCard(MovementSensorService sensor) {
    final p = sensor.profile;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HealthTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HealthTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ข้อมูลสรีรวิทยา & เป้าหมาย', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              TextButton(
                onPressed: _openProfileDialog,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 24)),
                child: const Text('แก้ไข', style: TextStyle(color: HealthTheme.cyanDistance, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _profileMiniItem('BMI', p.bmi.toStringAsFixed(1), HealthTheme.emeraldStep),
              _profileMiniItem('เป้าหมายน้ำหนัก', '${sensor.targetWeightKg.toStringAsFixed(0)} kg', HealthTheme.orangeCalorie),
              _profileMiniItem('พร่องแคลอรี', '${sensor.targetCalorieDeficitKcal} kcal', HealthTheme.goldRBRU),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileMiniItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
      ],
    );
  }

  /// Simulation & Manual Control Row
  Widget _buildControls(MovementSensorService sensor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: sensor.isSimulating ? HealthTheme.orangeCalorie : HealthTheme.surfaceElevated,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: sensor.isSimulating ? HealthTheme.orangeCalorie : HealthTheme.border,
                  ),
                ),
              ),
              onPressed: () => sensor.toggleSimulation(),
              icon: Icon(sensor.isSimulating ? Icons.stop_circle : Icons.directions_walk, size: 18),
              label: Text(
                sensor.isSimulating ? 'หยุดการจำลองเดิน' : 'จำลองการเดินต่อเนื่อง',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: HealthTheme.emeraldStep,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: HealthTheme.emeraldStep, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => sensor.addManualStep(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+1 ก้าว', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
