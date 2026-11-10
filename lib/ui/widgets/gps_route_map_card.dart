import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/gps_waypoint.dart';
import '../../services/gps_tracking_service.dart';
import '../theme/health_theme.dart';

/// การ์ดแสดงผลแผนที่เส้นทางการเดินทางจริงด้วยระบบ GPS (Bento GPS Route Map Card)
class GpsRouteMapCard extends StatefulWidget {
  final GpsTrackingService gpsService;
  final double pedometerDistanceKm;

  const GpsRouteMapCard({
    super.key,
    required this.gpsService,
    this.pedometerDistanceKm = 0.0,
  });

  @override
  State<GpsRouteMapCard> createState() => _GpsRouteMapCardState();
}

class _GpsRouteMapCardState extends State<GpsRouteMapCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;
  bool _isAutoCenter = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    setState(() {
      _zoomLevel = 1.0;
      _panOffset = Offset.zero;
      _isAutoCenter = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gps = widget.gpsService;
    final waypoints = gps.waypoints;
    final currentPoint = gps.currentWaypoint;

    return Container(
      decoration: BoxDecoration(
        color: HealthTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gps.isTracking
              ? HealthTheme.neonCyan.withOpacity(0.5)
              : Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (gps.isTracking ? HealthTheme.neonCyan : Colors.black)
                .withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Bar: Title, GPS Status, Mode Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HealthTheme.neonCyan.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.explore_rounded,
                    color: HealthTheme.neonCyan,
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
                              'แผนที่เส้นทางจริง (GPS ROUTE)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (gps.isTracking)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: HealthTheme.neonEmerald.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: HealthTheme.neonEmerald.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: HealthTheme.neonEmerald,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'REC',
                                    style: TextStyle(
                                      color: HealthTheme.neonEmerald,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentPoint != null
                            ? '${currentPoint.latitude.toStringAsFixed(5)}°N, ${currentPoint.longitude.toStringAsFixed(5)}°E • แม่นยำ ±${currentPoint.accuracy.toStringAsFixed(1)}m'
                            : 'กำลังเชื่อมต่อสัญญาณดาวเทียม...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                // Mode Dropdown / Button
                _buildModeBadge(gps),
              ],
            ),
          ),

          // 2. Interactive Map Viewport (CustomPainter)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 230,
                color: const Color(0xFF0A0F18),
                child: Stack(
                  children: [
                    // Gesture Detector for Pan & Zoom
                    GestureDetector(
                      onScaleUpdate: (details) {
                        setState(() {
                          _zoomLevel = (_zoomLevel * details.scale).clamp(0.5, 5.0);
                          _panOffset += details.focalPointDelta;
                          _isAutoCenter = false;
                        });
                      },
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: Size.infinite,
                            painter: GpsRoutePainter(
                              waypoints: waypoints,
                              currentPosition: currentPoint,
                              pulseValue: _pulseController.value,
                              zoomLevel: _zoomLevel,
                              panOffset: _panOffset,
                              isAutoCenter: _isAutoCenter,
                            ),
                          );
                        },
                      ),
                    ),

                    // Map Overlays: Compass & Legend
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.rotate(
                              angle: ((currentPoint?.heading ?? 0) * pi / 180.0),
                              child: const Icon(
                                Icons.navigation_rounded,
                                color: HealthTheme.neonCyan,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${currentPoint?.heading.toStringAsFixed(0) ?? '0'}° N',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Floating Map Controls (+, -, Recenter, Fullscreen)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMapIconButton(
                            icon: Icons.add,
                            tooltip: 'ซูมเข้า',
                            onTap: () {
                              setState(() {
                                _zoomLevel = (_zoomLevel * 1.25).clamp(0.5, 5.0);
                              });
                            },
                          ),
                          const SizedBox(height: 6),
                          _buildMapIconButton(
                            icon: Icons.remove,
                            tooltip: 'ซูมออก',
                            onTap: () {
                              setState(() {
                                _zoomLevel = (_zoomLevel / 1.25).clamp(0.5, 5.0);
                              });
                            },
                          ),
                          const SizedBox(height: 6),
                          _buildMapIconButton(
                            icon: Icons.my_location_rounded,
                            tooltip: 'กึ่งกลางพิกัดปัจจุบัน',
                            isActive: _isAutoCenter,
                            onTap: _recenterMap,
                          ),
                          const SizedBox(height: 6),
                          _buildMapIconButton(
                            icon: Icons.fullscreen_rounded,
                            tooltip: 'ขยายเต็มจอ',
                            onTap: () => _openFullscreenMap(context, gps),
                          ),
                        ],
                      ),
                    ),

                    // Bottom-Left Distance Scale Indicator
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${waypoints.length} จุดพิกัด • Haversine WGS84',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Telemetry HUD Bar: Distance, Speed, Pace, Elevation
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                _buildTelemetryTile(
                  label: 'ระยะทาง GPS',
                  value: '${gps.totalDistanceKm.toStringAsFixed(2)} km',
                  subtext: widget.pedometerDistanceKm > 0
                      ? 'นับก้าว: ${widget.pedometerDistanceKm.toStringAsFixed(2)} km'
                      : 'ความแม่นยำสูง',
                  accentColor: HealthTheme.neonCyan,
                  icon: Icons.straighten_rounded,
                ),
                const SizedBox(width: 8),
                _buildTelemetryTile(
                  label: 'ความเร็วสด',
                  value: '${gps.currentSpeedKmh.toStringAsFixed(1)} km/h',
                  subtext: 'Pace: ${gps.currentPaceFormatted}',
                  accentColor: HealthTheme.neonEmerald,
                  icon: Icons.speed_rounded,
                ),
                const SizedBox(width: 8),
                _buildTelemetryTile(
                  label: 'เวลาบันทึก',
                  value: gps.formattedDuration,
                  subtext: 'ความสูง +${gps.totalElevationGainMeters.toStringAsFixed(0)}m',
                  accentColor: HealthTheme.neonOrange,
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
          ),

          // 4. Action Buttons Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Row(
              children: [
                // Primary Start/Pause/Resume Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!gps.isTracking) {
                        gps.startTracking();
                      } else if (gps.isPaused) {
                        gps.resumeTracking();
                      } else {
                        gps.pauseTracking();
                      }
                    },
                    icon: Icon(
                      !gps.isTracking
                          ? Icons.play_arrow_rounded
                          : gps.isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                    label: Text(
                      !gps.isTracking
                          ? 'เริ่มบันทึกเส้นทาง'
                          : gps.isPaused
                              ? 'บันทึกต่อ'
                              : 'พักการเดินทาง',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !gps.isTracking
                          ? HealthTheme.neonCyan
                          : gps.isPaused
                              ? HealthTheme.neonEmerald
                              : HealthTheme.neonOrange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Stop/Save Button
                if (gps.isTracking) ...[
                  IconButton.filledTonal(
                    onPressed: () => gps.stopTracking(),
                    icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.25),
                      padding: const EdgeInsets.all(12),
                    ),
                    tooltip: 'สิ้นสุดการเดินทาง',
                  ),
                  const SizedBox(width: 8),
                ],
                // Clear Route Button
                IconButton.filledTonal(
                  onPressed: waypoints.isEmpty ? null : () => _confirmClearRoute(context, gps),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.08),
                    padding: const EdgeInsets.all(12),
                  ),
                  tooltip: 'ล้างเส้นทาง',
                ),
                const SizedBox(width: 8),
                // Export GeoJSON
                IconButton.filledTonal(
                  onPressed: waypoints.isEmpty ? null : () => _showExportDialog(context, gps),
                  icon: const Icon(Icons.share_location_rounded, color: HealthTheme.neonCyan, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: HealthTheme.neonCyan.withOpacity(0.12),
                    padding: const EdgeInsets.all(12),
                  ),
                  tooltip: 'ส่งออกข้อมูล GeoJSON',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive
              ? HealthTheme.neonCyan.withOpacity(0.3)
              : Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? HealthTheme.neonCyan
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? HealthTheme.neonCyan : Colors.white,
        ),
      ),
    );
  }

  Widget _buildModeBadge(GpsTrackingService gps) {
    return PopupMenuButton<GpsActivityMode>(
      initialValue: gps.activityMode,
      color: const Color(0xFF1E2638),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (mode) => gps.setActivityMode(mode),
      itemBuilder: (context) => GpsActivityMode.values.map((mode) {
        return PopupMenuItem(
          value: mode,
          child: Row(
            children: [
              Icon(
                mode == GpsActivityMode.walking
                    ? Icons.directions_walk_rounded
                    : mode == GpsActivityMode.running
                        ? Icons.directions_run_rounded
                        : Icons.directions_bike_rounded,
                color: HealthTheme.neonCyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                mode.label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              gps.activityMode == GpsActivityMode.walking
                  ? Icons.directions_walk_rounded
                  : gps.activityMode == GpsActivityMode.running
                      ? Icons.directions_run_rounded
                      : Icons.directions_bike_rounded,
              color: HealthTheme.neonCyan,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              gps.activityMode.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryTile({
    required String label,
    required String value,
    required String subtext,
    required Color accentColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1522),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: TextStyle(
                color: accentColor,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearRoute(BuildContext context, GpsTrackingService gps) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('ล้างเส้นทาง GPS หรือไม่?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'ข้อมูลพิกัดการเดินทางจริงและสถิติทั้งหมดของรอบนี้จะถูกรีเซ็ต',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              gps.clearRoute();
              _recenterMap();
            },
            child: const Text('ล้างข้อมูล', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, GpsTrackingService gps) {
    final geoJson = gps.exportGeoJson();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.code_rounded, color: HealthTheme.neonCyan),
            SizedBox(width: 8),
            Text('GeoJSON Route Data', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                geoJson,
                style: const TextStyle(
                  color: HealthTheme.neonEmerald,
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openFullscreenMap(BuildContext context, GpsTrackingService gps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0F18),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'แผนที่พิกัดการเดินทางจริงเต็มจอ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: GpsRoutePainter(
                  waypoints: gps.waypoints,
                  currentPosition: gps.currentWaypoint,
                  pulseValue: _pulseController.value,
                  zoomLevel: 1.2,
                  panOffset: Offset.zero,
                  isAutoCenter: true,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF121927),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFsStat('ระยะทาง', '${gps.totalDistanceKm.toStringAsFixed(2)} km'),
                  _buildFsStat('ความเร็วเฉลี่ย', '${gps.averageSpeedKmh.toStringAsFixed(1)} km/h'),
                  _buildFsStat('เวลา', gps.formattedDuration),
                  _buildFsStat('จุดพิกัด', '${gps.waypoints.length} จุด'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFsStat(String title, String val) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// CustomPainter สำหรับการเรนเดอร์พิกัด GPS ลงบนผืนผ้าใบแบบเวกเตอร์คอนทราสต์สูง
class GpsRoutePainter extends CustomPainter {
  final List<GpsWaypoint> waypoints;
  final GpsWaypoint? currentPosition;
  final double pulseValue;
  final double zoomLevel;
  final Offset panOffset;
  final bool isAutoCenter;

  GpsRoutePainter({
    required this.waypoints,
    required this.currentPosition,
    required this.pulseValue,
    required this.zoomLevel,
    required this.panOffset,
    required this.isAutoCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. วาดตารางพิกัดไซเบอร์เนติก (Cyber Grid Lines)
    _drawGridBackground(canvas, size);

    if (waypoints.isEmpty && currentPosition == null) {
      _drawNoGpsMessage(canvas, size);
      return;
    }

    // 2. คำนวณขอบเขตพิกัดภูมิศาสตร์ (Bounding Box)
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    final allPoints = <GpsWaypoint>[
      ...waypoints,
      if (currentPosition != null) currentPosition!,
    ];

    for (var pt in allPoints) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }

    // ป้องกันการหารด้วยศูนย์เมื่อมีจุดเดียว
    const double paddingDelta = 0.0004;
    if ((maxLat - minLat).abs() < 0.00005) {
      minLat -= paddingDelta;
      maxLat += paddingDelta;
    }
    if ((maxLng - minLng).abs() < 0.00005) {
      minLng -= paddingDelta;
      maxLng += paddingDelta;
    }

    // เพิ่มระยะขอบหน้าจอ
    final double margin = 36.0;
    final double drawW = size.width - (margin * 2);
    final double drawH = size.height - (margin * 2);

    Offset toCanvas(double lat, double lng) {
      final double normalizedX = (lng - minLng) / (maxLng - minLng);
      final double normalizedY = (maxLat - lat) / (maxLat - minLat); // พลิกแกน Y สำหรับพิกัดหน้าจอ

      double px = margin + (normalizedX * drawW);
      double py = margin + (normalizedY * drawH);

      // นำ Zoom และ Pan มาแปลงจุด
      final center = Offset(size.width / 2, size.height / 2);
      px = center.dx + (px - center.dx) * zoomLevel + panOffset.dx;
      py = center.dy + (py - center.dy) * zoomLevel + panOffset.dy;

      return Offset(px, py);
    }

    // 3. วาดเส้นทางโพลีไลน์ (Route Polyline) ด้วยสีนีออนเรืองแสง
    if (waypoints.length > 1) {
      final path = Path();
      final glowPath = Path();

      final firstScreenPoint = toCanvas(waypoints.first.latitude, waypoints.first.longitude);
      path.moveTo(firstScreenPoint.dx, firstScreenPoint.dy);
      glowPath.moveTo(firstScreenPoint.dx, firstScreenPoint.dy);

      for (int i = 1; i < waypoints.length; i++) {
        final screenPoint = toCanvas(waypoints[i].latitude, waypoints[i].longitude);
        path.lineTo(screenPoint.dx, screenPoint.dy);
        glowPath.lineTo(screenPoint.dx, screenPoint.dy);
      }

      // วาดชั้นเรืองแสงรอบนอก (Outer Glow)
      final glowPaint = Paint()
        ..color = HealthTheme.neonCyan.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(glowPath, glowPaint);

      // วาดเส้นแกนหลักนีออน
      final linePaint = Paint()
        ..shader = const LinearGradient(
          colors: [HealthTheme.neonEmerald, HealthTheme.neonCyan],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, linePaint);

      // 4. วาดจุดเริ่มต้น (Start Point Pin)
      _drawStartPin(canvas, firstScreenPoint);

      // วาดจุดกึ่งกลางหรือไมล์สโตน (Milestone Nodes)
      if (waypoints.length > 5) {
        final midIdx = waypoints.length ~/ 2;
        final midScreenPoint = toCanvas(waypoints[midIdx].latitude, waypoints[midIdx].longitude);
        _drawWayPointNode(canvas, midScreenPoint, 'MID');
      }
    }

    // 5. วาดจุดตำแหน่งปัจจุบัน (Current Position Beacon with Pulse Effect)
    if (currentPosition != null) {
      final curScreenPoint = toCanvas(currentPosition!.latitude, currentPosition!.longitude);
      _drawCurrentPositionBeacon(canvas, curScreenPoint, currentPosition!.heading);
    }
  }

  void _drawGridBackground(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF131F33).withOpacity(0.6)
      ..strokeWidth = 1.0;

    const double step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawStartPin(Canvas canvas, Offset point) {
    // วงกลมเขียวนีออนจุดเริ่ม
    final pinPaint = Paint()
      ..color = HealthTheme.neonEmerald
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 5.0, pinPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(point, 5.0, borderPaint);
  }

  void _drawWayPointNode(Canvas canvas, Offset point, String label) {
    final nodePaint = Paint()
      ..color = HealthTheme.neonOrange
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 3.5, nodePaint);
  }

  void _drawCurrentPositionBeacon(Canvas canvas, Offset point, double heading) {
    // คลื่นเรดาร์กะพริบ 2 ชั้น (Radar Pulsing Ripple)
    final double maxRadius = 24.0;
    final double r1 = 6.0 + (pulseValue * (maxRadius - 6.0));
    final double opacity1 = (1.0 - pulseValue).clamp(0.0, 1.0) * 0.6;

    final pulsePaint = Paint()
      ..color = HealthTheme.neonCyan.withOpacity(opacity1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(point, r1, pulsePaint);

    // วงแหวนกลาง
    final innerPaint = Paint()
      ..color = HealthTheme.neonCyan.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 10.0, innerPaint);

    // จุดศูนย์กลางตำแหน่งจริง
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 5.0, corePaint);

    final coreBorder = Paint()
      ..color = HealthTheme.neonCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(point, 5.0, coreBorder);

    // ลูกศรทิศทาง (Heading Direction Indicator)
    if (heading >= 0) {
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(heading * pi / 180.0);

      final arrowPath = Path()
        ..moveTo(0, -14)
        ..lineTo(-5, -6)
        ..lineTo(5, -6)
        ..close();

      final arrowPaint = Paint()
        ..color = HealthTheme.neonCyan
        ..style = PaintingStyle.fill;
      canvas.drawPath(arrowPath, arrowPaint);

      canvas.restore();
    }
  }

  void _drawNoGpsMessage(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      color: Colors.grey,
      fontSize: 12,
    );
    const textSpan = TextSpan(
      text: 'กดปุ่ม "เริ่มบันทึกเส้นทาง" เพื่อเริ่มวาดแผนที่ GPS จริง',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width - 40);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant GpsRoutePainter oldDelegate) {
    return true; // รีเพนต์ตามการเปลี่ยนแปลงพิกัดและการหมุนของแอนิเมชันเรดาร์
  }
}
