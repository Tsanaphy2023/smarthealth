import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/activity_type.dart';
import '../../models/app_brand_edition.dart';
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
import '../widgets/weekly_history_card.dart';

class HomeTrackerScreen extends StatefulWidget {
  const HomeTrackerScreen({super.key});

  @override
  State<HomeTrackerScreen> createState() => _HomeTrackerScreenState();
}

class _HomeTrackerScreenState extends State<HomeTrackerScreen> {
  int _selectedTabIndex = 0;

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
    final brand = sensor.brandEdition;
    final metric = sensor.currentMetric;
    final now = DateTime.now();
    final dateStr = DateFormat('d MMM yyyy').format(now);

    final Color ambientColor1 = metric.currentActivity == ActivityType.running
        ? const Color(0xFF2A0D0A)
        : brand == AppBrandEdition.sciRbruMoveAi
            ? const Color(0xFF101C3B)
            : metric.currentActivity == ActivityType.walking
                ? const Color(0xFF082015)
                : const Color(0xFF0B1624);

    return Scaffold(
      backgroundColor: HealthTheme.background,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ambientColor1,
              brand.backgroundGradient[1],
              HealthTheme.background,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Custom Brand App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 10, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => sensor.toggleBrandEdition(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: brand.primaryColor.withValues(alpha: 0.9),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: brand.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            brand.iconAsset,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/icons/app_icon.png',
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  brand.appName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: brand.primaryColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: brand.primaryColor.withValues(alpha: 0.6),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  brand.badgeText,
                                  style: TextStyle(
                                    color: brand.primaryColor,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${brand.tagline} • $dateStr',
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'ตั้งค่าเป้าหมายสุขภาพ & ลดน้ำหนัก',
                      onPressed: _openComprehensiveGoalsDialog,
                      icon: Icon(Icons.tune, color: brand.secondaryColor, size: 21),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'ข้อมูลร่างกาย & โปรไฟล์ส่วนตัว',
                      onPressed: _openProfileDialog,
                      icon: Icon(Icons.person_outline, color: brand.primaryColor, size: 21),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'รีเซ็ตข้อมูลเป็น 0',
                      onPressed: _confirmReset,
                      icon: const Icon(Icons.restart_alt, color: HealthTheme.orangeCalorie, size: 21),
                    ),
                  ],
                ),
              ),

              // Dual-Brand Instant Switcher Bar (ChewaPulse xAI <-> SciRBRU Move+AI)
              _buildBrandSwitcherBar(sensor, gpsService),

              // Main Responsive Content Area
              Expanded(
                child: ResponsiveLayoutBuilder(
                  builder: (context, breakpoint, constraints) {
                    if (_selectedTabIndex == 1) {
                      return _buildMapFocusedTab(sensor, metric, gpsService);
                    } else if (_selectedTabIndex == 2) {
                      return _buildAnalyticsAndHistoryTab(sensor, metric);
                    } else if (_selectedTabIndex == 3) {
                      return _buildProfileAndBrandTab(sensor);
                    }

                    // Tab 0 (หน้าหลักวันนี้) รองรับ Responsive 3 ขนาดหน้าจอ
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
      bottomNavigationBar: _buildModernBottomNav(brand, gpsService),
    );
  }

  /// แถบสลับโหมด 2 แอปพลิเคชัน (ChewaPulse xAI ⚡ SciRBRU Move+AI) แบบกดสลับได้ทันทีใน 1 คลิก
  Widget _buildBrandSwitcherBar(MovementSensorService sensor, GpsTrackingService gpsService) {
    final activeBrand = sensor.brandEdition;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: HealthTheme.surfaceElevated.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildBrandOptionPill(
                sensor: sensor,
                edition: AppBrandEdition.chewaPulseXai,
                isSelected: activeBrand == AppBrandEdition.chewaPulseXai,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildBrandOptionPill(
                sensor: sensor,
                edition: AppBrandEdition.sciRbruMoveAi,
                isSelected: activeBrand == AppBrandEdition.sciRbruMoveAi,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandOptionPill({
    required MovementSensorService sensor,
    required AppBrandEdition edition,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => sensor.setBrandEdition(edition),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? edition.primaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? edition.primaryColor
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.asset(
                edition.iconAsset,
                width: 18,
                height: 18,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.bolt,
                  size: 14,
                  color: edition.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                edition.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Navigation Bar 4 แท็บหลัก (วันนี้ • แผนที่ดาวเทียม • สถิติย้อนหลัง 7 วัน • โปรไฟล์)
  Widget _buildModernBottomNav(AppBrandEdition brand, GpsTrackingService gpsService) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1524),
        border: Border(
          top: BorderSide(color: brand.primaryColor.withValues(alpha: 0.25), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (idx) => setState(() => _selectedTabIndex = idx),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: brand.primaryColor,
        unselectedItemColor: Colors.white54,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10.5),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_rounded, size: 20),
            label: 'วันนี้',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.satellite_alt_rounded,
              size: 20,
              color: gpsService.isTracking ? HealthTheme.neonEmerald : null,
            ),
            label: 'แผนที่ดาวเทียม',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded, size: 20),
            label: 'สถิติ 7 วัน & AI',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined, size: 20),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }

  /// แท็บที่ 1 (Index 1): โหมดแผนที่ดาวเทียมและเส้นทาง GPS เต็มรูปแบบ
  Widget _buildMapFocusedTab(
      MovementSensorService sensor, dynamic metric, GpsTrackingService gpsService) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        children: [
          GpsRouteMapCard(
            gpsService: gpsService,
            pedometerDistanceKm: metric.distanceKm,
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
        ],
      ),
    );
  }

  /// แท็บที่ 2 (Index 2): สถิติย้อนหลัง 7 วัน & โค้ชวิเคราะห์ AI
  Widget _buildAnalyticsAndHistoryTab(MovementSensorService sensor, dynamic metric) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 28),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: WeeklyHistoryCard(sensor: sensor),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DeepAiAnalyticsCard(sensor: sensor),
          ),
          const SizedBox(height: 16),
          _buildIntervalHistorySection(sensor),
          const SizedBox(height: 16),
          HourlyActivityChart(records: sensor.hourlyRecords),
          const SizedBox(height: 16),
          LiveMotionGauge(intensity: metric.motionIntensity, isSensorLive: sensor.isSensorActive),
        ],
      ),
    );
  }

  /// แท็บที่ 3 (Index 3): โปรไฟล์ร่างกาย ตั้งค่าเป้าหมาย และสลับแบรนด์แอปคู่
  Widget _buildProfileAndBrandTab(MovementSensorService sensor) {
    final brand = sensor.brandEdition;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        children: [
          // Dual-Brand Showcase Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: HealthTheme.surfaceCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: brand.primaryColor.withValues(alpha: 0.45), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        brand.iconAsset,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/icons/app_icon.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brand.appName,
                            style: TextStyle(
                              color: brand.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            brand.thaiName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            brand.tagline,
                            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),
                Text(
                  brand.developerCredit,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: brand.secondaryColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildProfileSummaryCard(sensor),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: brand.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _openComprehensiveGoalsDialog,
              icon: const Icon(Icons.tune_rounded),
              label: const Text(
                'ตั้งค่าเป้าหมายก้าวเดิน • ลดน้ำหนัก • เตือนลุกนั่ง',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: brand.secondaryColor.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _openProfileDialog,
              icon: Icon(Icons.person_outline, color: brand.secondaryColor),
              label: const Text(
                'แก้ไขข้อมูลร่างกาย (เพศ • น้ำหนัก • ส่วนสูง • อายุ)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
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
          const SizedBox(height: 16),
          KineticAvatarWidget(
            activity: metric.currentActivity,
            intensity: metric.motionIntensity,
            cadenceSpm: metric.cadenceSpm,
          ),
          const SizedBox(height: 16),
          MetricStatCards(metric: metric),
          const SizedBox(height: 16),
          // 7-Day Weekly History Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: WeeklyHistoryCard(sensor: sensor),
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
                    WeeklyHistoryCard(sensor: sensor),
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

              // Column 3: Metrics, 7-Day Weekly History & 4h Interval History
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    MetricStatCards(metric: metric),
                    const SizedBox(height: 16),
                    WeeklyHistoryCard(sensor: sensor),
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
              const Flexible(
                child: Text(
                  'ข้อมูลร่างกาย & เป้าหมายส่วนตัว',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _openProfileDialog,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 24)),
                child: const Text('แก้ไข', style: TextStyle(color: HealthTheme.cyanDistance, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _profileMiniItem('BMI', p.bmi.toStringAsFixed(1), HealthTheme.emeraldStep)),
              const SizedBox(width: 6),
              Expanded(child: _profileMiniItem('เป้าหมายน้ำหนัก', '${sensor.targetWeightKg.toStringAsFixed(0)} kg', HealthTheme.orangeCalorie)),
              const SizedBox(width: 6),
              Expanded(child: _profileMiniItem('พร่องแคลอรี', '${sensor.targetCalorieDeficitKcal} kcal', HealthTheme.goldRBRU)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileMiniItem(String title, String val, Color color) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(title, maxLines: 1, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(val, maxLines: 1, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  /// Simulation & Manual Control Row
  Widget _buildControls(MovementSensorService sensor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sensor.isSimulating ? HealthTheme.orangeCalorie : HealthTheme.surfaceElevated,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: sensor.isSimulating ? HealthTheme.orangeCalorie : HealthTheme.border,
                      ),
                    ),
                  ),
                  onPressed: () => sensor.toggleSimulation(),
                  icon: Icon(sensor.isSimulating ? Icons.stop_circle : Icons.directions_walk, size: 18),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      sensor.isSimulating ? 'หยุดการจำลองเดิน' : 'จำลองการเดินต่อเนื่อง',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HealthTheme.emeraldStep,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    side: const BorderSide(color: HealthTheme.emeraldStep, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => sensor.addManualStep(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('+1 ก้าว', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: HealthTheme.alertRed,
                backgroundColor: HealthTheme.alertRed.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                side: BorderSide(color: HealthTheme.alertRed.withValues(alpha: 0.65), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => sensor.triggerSedentaryAlertDemo(),
              icon: const Icon(Icons.record_voice_over_rounded, size: 18),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '🔊 ทดสอบเสียงเตือน 30 นาที: "ลุกคะ ลุกค่ะ!" (นิ่ง ${sensor.sedentaryMinutes}/${sensor.sedentaryAlertMinutes} นาที)',
                  maxLines: 1,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
