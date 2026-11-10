import 'package:flutter/material.dart';
import '../../services/movement_sensor_service.dart';
import '../../services/voice_alert_service.dart';
import '../theme/health_theme.dart';

class ComprehensiveGoalsDialog extends StatefulWidget {
  final MovementSensorService sensor;

  const ComprehensiveGoalsDialog({super.key, required this.sensor});

  @override
  State<ComprehensiveGoalsDialog> createState() => _ComprehensiveGoalsDialogState();
}

class _ComprehensiveGoalsDialogState extends State<ComprehensiveGoalsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late int _stepGoal;
  late double _targetWeight;
  late int _calorieDeficit;
  late int _sedentaryMinutes;
  late int _waterGoal;
  late bool _voiceAlertEnabled;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _stepGoal = widget.sensor.dailyGoal;
    _targetWeight = widget.sensor.targetWeightKg;
    _calorieDeficit = widget.sensor.targetCalorieDeficitKcal;
    _sedentaryMinutes = widget.sensor.sedentaryAlertMinutes;
    _waterGoal = widget.sensor.dailyWaterGoalMl;
    _voiceAlertEnabled = widget.sensor.isVoiceAlertEnabled;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    widget.sensor.updateComprehensiveSettings(
      dailyGoal: _stepGoal,
      targetWeightKg: _targetWeight,
      targetCalorieDeficit: _calorieDeficit,
      sedentaryAlertMinutes: _sedentaryMinutes,
      dailyWaterGoalMl: _waterGoal,
      voiceAlertEnabled: _voiceAlertEnabled,
    );
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: HealthTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: HealthTheme.emeraldActive),
            SizedBox(width: 8),
            Text('บันทึกการตั้งค่าเป้าหมายสำเร็จ'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: HealthTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 440,
        constraints: const BoxConstraints(maxHeight: 620),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune, color: HealthTheme.cyanPrimary, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'ตั้งค่าเป้าหมายสุขภาพ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: HealthTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: HealthTheme.cyanPrimary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: HealthTheme.cyanPrimary,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'เป้าหมายรายวัน'),
                  Tab(text: 'ลดน้ำหนัก'),
                  Tab(text: 'ระบบเตือนขยับ'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDailyGoalsTab(),
                  _buildWeightLossTab(),
                  _buildHealthAndAlertsTab(),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Bottom Buttons
            Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: HealthTheme.orangeCalorie),
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('รีเซตเป็น 0', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    widget.sensor.resetAllToZero();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('รีเซตสถิติทุกอย่างเป็น 0 เรียบร้อยแล้ว')),
                    );
                  },
                ),
                const Spacer(),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HealthTheme.cyanPrimary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveSettings,
                  child: const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 1. เป้าหมายรายวัน
  Widget _buildDailyGoalsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('เป้าหมายจำนวนก้าวต่อวัน', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_stepGoal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ก้าว',
                  style: const TextStyle(color: HealthTheme.cyanPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              Text('ระยะทาง ~${((_stepGoal * 0.72) / 1000).toStringAsFixed(1)} กม.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          Slider(
            value: _stepGoal.toDouble(),
            min: 2000,
            max: 30000,
            divisions: 28,
            activeColor: HealthTheme.cyanPrimary,
            inactiveColor: Colors.white12,
            onChanged: (v) => setState(() => _stepGoal = v.round()),
          ),
          Wrap(
            spacing: 6,
            children: [6000, 8000, 10000, 12000, 15000].map((preset) {
              final isSel = _stepGoal == preset;
              return ChoiceChip(
                label: Text('${preset ~/ 1000}k'),
                selected: isSel,
                selectedColor: HealthTheme.cyanPrimary,
                labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 11),
                backgroundColor: HealthTheme.surfaceElevated,
                onSelected: (_) => setState(() => _stepGoal = preset),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          const Text('เป้าหมายการดื่มน้ำบริสุทธิ์ต่อวัน', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_waterGoal mL',
                  style: const TextStyle(color: HealthTheme.blueDistance, fontSize: 20, fontWeight: FontWeight.bold)),
              Text('~${(_waterGoal / 250).toStringAsFixed(0)} แก้วมาตรฐาน',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          Slider(
            value: _waterGoal.toDouble(),
            min: 1500,
            max: 4500,
            divisions: 30,
            activeColor: HealthTheme.blueDistance,
            inactiveColor: Colors.white12,
            onChanged: (v) => setState(() => _waterGoal = v.round()),
          ),
        ],
      ),
    );
  }

  // 2. เป้าหมายลดน้ำหนัก
  Widget _buildWeightLossTab() {
    final currentWeight = widget.sensor.profile.weightKg;
    final diff = currentWeight - _targetWeight;
    final weeksEst = diff > 0 ? (diff * 7700) / (_calorieDeficit * 7) : 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('น้ำหนักปัจจุบัน', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  Text('${currentWeight.toStringAsFixed(1)} kg',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.arrow_forward, color: HealthTheme.orangeCalorie),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('เป้าหมายน้ำหนัก', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  Text('${_targetWeight.toStringAsFixed(1)} kg',
                      style: const TextStyle(color: HealthTheme.orangeCalorie, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Slider(
            value: _targetWeight,
            min: 40.0,
            max: 130.0,
            divisions: 90,
            activeColor: HealthTheme.orangeCalorie,
            inactiveColor: Colors.white12,
            onChanged: (v) => setState(() => _targetWeight = v),
          ),

          const SizedBox(height: 12),

          const Text('เป้าหมายพร่องแคลอรีต่อวัน (Calorie Deficit)',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_calorieDeficit kcal/วัน',
                  style: const TextStyle(color: HealthTheme.goldRBRU, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(diff > 0 ? 'คาดการณ์ถึงเป้าใน ~${weeksEst.toStringAsFixed(0)} สัปดาห์' : 'น้ำหนักตามเกณฑ์แล้ว',
                  style: TextStyle(color: Colors.grey[300], fontSize: 11.5)),
            ],
          ),
          Slider(
            value: _calorieDeficit.toDouble(),
            min: 200,
            max: 1000,
            divisions: 16,
            activeColor: HealthTheme.goldRBRU,
            inactiveColor: Colors.white12,
            onChanged: (v) => setState(() => _calorieDeficit = v.round()),
          ),
          Wrap(
            spacing: 6,
            children: [300, 500, 750, 1000].map((d) {
              final isSel = _calorieDeficit == d;
              return ChoiceChip(
                label: Text('$d kcal'),
                selected: isSel,
                selectedColor: HealthTheme.goldRBRU,
                labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 11),
                backgroundColor: HealthTheme.surfaceElevated,
                onSelected: (_) => setState(() => _calorieDeficit = d),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 3. เป้าหมายสุขภาพและระบบเตือนขยับ
  Widget _buildHealthAndAlertsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('แจ้งเตือนเมื่อนั่งนิ่งเกินกำหนด', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('ป้องกันภาวะดื้ออินซูลินและหลอดเลือดดำชะงัก', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: HealthTheme.alertRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_sedentaryMinutes นาที',
                    style: const TextStyle(color: HealthTheme.alertRed, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
          Slider(
            value: _sedentaryMinutes.toDouble(),
            min: 15,
            max: 60,
            divisions: 9,
            activeColor: HealthTheme.alertRed,
            inactiveColor: Colors.white12,
            onChanged: (v) => setState(() => _sedentaryMinutes = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [15, 30, 45, 60].map((mins) {
              final isSel = _sedentaryMinutes == mins;
              return ChoiceChip(
                label: Text('$mins นาที'),
                selected: isSel,
                selectedColor: HealthTheme.alertRed,
                labelStyle: TextStyle(color: isSel ? Colors.white : Colors.white70, fontSize: 11),
                backgroundColor: HealthTheme.surfaceElevated,
                onSelected: (_) => setState(() => _sedentaryMinutes = mins),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Voice Alert Toggle & Test
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HealthTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('เสียงพูดเตือน "ลุกค่ะ ลุกค่ะ"',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('ส่งเสียงกังวานและเสียงเตือนสดเมื่อนั่งนานครบ 30 นาที',
                      style: TextStyle(color: Colors.white60, fontSize: 11)),
                  activeColor: HealthTheme.emeraldActive,
                  value: _voiceAlertEnabled,
                  onChanged: (val) => setState(() => _voiceAlertEnabled = val),
                ),
                const Divider(color: Colors.white12, height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HealthTheme.emeraldActive.withOpacity(0.2),
                      foregroundColor: HealthTheme.emeraldActive,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: HealthTheme.emeraldActive),
                      ),
                    ),
                    icon: const Icon(Icons.record_voice_over, size: 18),
                    label: const Text('ทดสอบเสียงพูด "ลุกค่ะ ลุกค่ะ" ทันที'),
                    onPressed: () {
                      VoiceAlertService().playSedentaryVoiceAlert(force: true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: HealthTheme.emeraldActive,
                          content: Text('กำลังส่งสัญญาณเสียง: "ลุกค่ะ ลุกค่ะ! นั่งนานเกิน 30 นาทีแล้ว ได้เวลาขยับร่างกายแล้วค่ะ!"'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
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
