import 'package:flutter/material.dart';
import '../../services/deep_health_ai_engine.dart';
import '../../services/movement_sensor_service.dart';
import '../theme/health_theme.dart';

class DeepAiAnalyticsCard extends StatefulWidget {
  final MovementSensorService sensor;

  const DeepAiAnalyticsCard({super.key, required this.sensor});

  @override
  State<DeepAiAnalyticsCard> createState() => _DeepAiAnalyticsCardState();
}

class _DeepAiAnalyticsCardState extends State<DeepAiAnalyticsCard> {
  bool _isTraining = false;
  DeepTrainingResult? _latestResult;

  Future<void> _handleRetrain() async {
    setState(() => _isTraining = true);
    // ทำการหน่วงเวลาเพื่อแสดงสถานะการคำนวณ Deep Learning
    await Future.delayed(const Duration(milliseconds: 400));
    final res = await widget.sensor.retrainAiModel(epochs: 16);
    setState(() {
      _latestResult = res;
      _isTraining = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: HealthTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: HealthTheme.emeraldActive, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ฝึกสอนโมเดลเชิงลึกสำเร็จ! Loss ลดลง ${res.lossReductionPercent.toStringAsFixed(1)}% (${res.totalParametersTrained} พารามิเตอร์)',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiInference = widget.sensor.latestAiInference;
    final engine = DeepHealthAiEngine();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HealthTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: HealthTheme.cyanPrimary.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: HealthTheme.cyanPrimary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AI Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HealthTheme.cyanPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.psychology, color: HealthTheme.cyanPrimary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'วิเคราะห์สุขภาพด้วย AI เชิงลึก',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'On-Device Deep Learning (รอบ 4 ชม.)',
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: HealthTheme.emeraldActive.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HealthTheme.emeraldActive.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_graph, color: HealthTheme.emeraldActive, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'แม่นยำ ${((aiInference?.confidence ?? 0.95) * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: HealthTheme.emeraldActive,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Primary AI Diagnosis Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131B2A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HealthTheme.cyanPrimary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: HealthTheme.cyanPrimary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        aiInference?.statusTitle ?? 'กำลังประเมินจลนศาสตร์การก้าว...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  aiInference?.description ??
                      'กำลังประมวลผลขนาดเวกเตอร์ความเร่งสามมิติร่วมกับความถี่ก้าวเพื่อจำแนกสภาวะกล้ามเนื้อ',
                  style: TextStyle(color: Colors.grey[300], fontSize: 11.5, height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates, color: HealthTheme.goldRBRU, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        aiInference?.exerciseRecommendation ?? 'เดินออกกำลังกายต่อเนื่องเพื่อสุขภาพหัวใจ',
                        style: const TextStyle(color: HealthTheme.goldRBRU, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4-Hour Predictive Forecasting Stats
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.local_fire_department,
                  iconColor: HealthTheme.orangeCalorie,
                  label: 'พยากรณ์เผาผลาญ 4 ชม. หน้า',
                  value: '${(aiInference?.forecastedCaloriesNext4h ?? 240).toStringAsFixed(0)} kcal',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.water_drop,
                  iconColor: HealthTheme.blueDistance,
                  label: 'ความต้องการน้ำ 4 ชม. หน้า',
                  value: '${(aiInference?.forecastedWaterNext4hMl ?? 450).toStringAsFixed(0)} mL',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // On-Device Training & Snapshot Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HealthTheme.cyanPrimary,
                    side: const BorderSide(color: HealthTheme.cyanPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('บันทึกรอบ 4 ชม.', style: TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final rec = await widget.sensor.captureAndSave4HourSnapshot();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: HealthTheme.surfaceElevated,
                          content: Text('บันทึกข้อมูลรอบ 4 ชั่วโมงสำเร็จ: ${rec.steps} ก้าว (${rec.aiDiagnosis})'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HealthTheme.cyanPrimary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isTraining
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.model_training, size: 16),
                  label: Text(
                    _isTraining ? 'กำลังเทรน...' : 'เทรนโมเดล AI',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isTraining ? null : _handleRetrain,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Live Deep Learning Telemetry Footer
          Center(
            child: Text(
              'Deep Learning Status: 3-Layer MLP • Loss: ${engine.currentModelLoss.toStringAsFixed(3)} • Total Epochs: ${engine.trainedEpochCount}',
              style: TextStyle(color: Colors.grey[500], fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: HealthTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey[400], fontSize: 9.5),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
