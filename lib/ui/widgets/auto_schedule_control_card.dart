import 'package:flutter/material.dart';
import '../../services/movement_sensor_service.dart';
import '../theme/health_theme.dart';

class AutoScheduleControlCard extends StatelessWidget {
  final MovementSensorService sensor;

  const AutoScheduleControlCard({super.key, required this.sensor});

  Future<void> _pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: sensor.autoStartHour,
        minute: sensor.autoStartMinute,
      ),
      helpText: 'ตั้งเวลาเริ่มนับก้าวอัตโนมัติ',
      cancelText: 'ยกเลิก',
      confirmText: 'บันทึกเวลาเริ่ม',
    );
    if (picked != null) {
      await sensor.updateAutoScheduleSettings(
        autoTrackEnabled: true,
        auto24HourMode: false,
        startHour: picked.hour,
        startMinute: picked.minute,
      );
    }
  }

  Future<void> _pickEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: sensor.autoEndHour,
        minute: sensor.autoEndMinute,
      ),
      helpText: 'ตั้งเวลาสิ้นสุดการนับก้าวอัตโนมัติ',
      cancelText: 'ยกเลิก',
      confirmText: 'บันทึกเวลาสิ้นสุด',
    );
    if (picked != null) {
      await sensor.updateAutoScheduleSettings(
        autoTrackEnabled: true,
        auto24HourMode: false,
        endHour: picked.hour,
        endMinute: picked.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = sensor.brandEdition;
    final isActiveNow = sensor.isWithinScheduledWindow();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HealthTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActiveNow
              ? brand.primaryColor.withValues(alpha: 0.5)
              : Colors.white24,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isActiveNow
                ? brand.primaryColor.withValues(alpha: 0.12)
                : Colors.black26,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Auto-Track Switch
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isActiveNow ? brand.primaryColor : Colors.grey)
                      .withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  sensor.isAuto24HourMode
                      ? Icons.all_inclusive_rounded
                      : Icons.schedule_rounded,
                  color: isActiveNow ? brand.primaryColor : Colors.white54,
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
                            'ระบบนับก้าวอัตโนมัติ 24 ชม. (แม้ปิดแอป)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isActiveNow
                                ? HealthTheme.emeraldActive.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isActiveNow ? 'ทำงานสด' : 'รอรอบเวลา',
                            style: TextStyle(
                              color: isActiveNow
                                  ? HealthTheme.emeraldActive
                                  : Colors.orangeAccent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sensor.scheduleStatusDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: sensor.isAutoTrackEnabled,
                activeColor: brand.primaryColor,
                onChanged: (val) {
                  sensor.updateAutoScheduleSettings(autoTrackEnabled: val);
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Mode Selector: 24 Hours Continuous vs User Custom Time Schedule
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  label: 'นับตลอด 24 ชม. (00:00-23:59)',
                  icon: Icons.autorenew_rounded,
                  isSelected:
                      sensor.isAutoTrackEnabled && sensor.isAuto24HourMode,
                  accentColor: brand.primaryColor,
                  onTap: () => sensor.updateAutoScheduleSettings(
                    autoTrackEnabled: true,
                    auto24HourMode: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModeButton(
                  label: 'กำหนดเวลาเริ่ม-หยุดเอง',
                  icon: Icons.alarm_on_rounded,
                  isSelected:
                      sensor.isAutoTrackEnabled && !sensor.isAuto24HourMode,
                  accentColor: brand.secondaryColor,
                  onTap: () => sensor.updateAutoScheduleSettings(
                    autoTrackEnabled: true,
                    auto24HourMode: false,
                  ),
                ),
              ),
            ],
          ),

          // Time Pickers & Quick Schedule Presets
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: HealthTheme.surfaceElevated.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickStartTime(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !sensor.isAuto24HourMode
                                  ? brand.primaryColor.withValues(alpha: 0.6)
                                  : Colors.white12,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_outline_rounded,
                                size: 15,
                                color: brand.primaryColor,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'เริ่ม: ${sensor.isAuto24HourMode ? "00:00" : sensor.formattedAutoStartTime} น.',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white38,
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickEndTime(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !sensor.isAuto24HourMode
                                  ? brand.secondaryColor.withValues(alpha: 0.6)
                                  : Colors.white12,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.stop_circle_outlined,
                                size: 15,
                                color: brand.secondaryColor,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'สิ้นสุด: ${sensor.isAuto24HourMode ? "23:59" : sensor.formattedAutoEndTime} น.',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildPresetChip(
                      label: 'ตลอด 24 ชม.',
                      isSelected: sensor.isAuto24HourMode,
                      color: brand.primaryColor,
                      onTap: () => sensor.updateAutoScheduleSettings(
                        autoTrackEnabled: true,
                        auto24HourMode: true,
                      ),
                    ),
                    _buildPresetChip(
                      label: '05:00 - 21:00',
                      isSelected: !sensor.isAuto24HourMode &&
                          sensor.autoStartHour == 5 &&
                          sensor.autoEndHour == 21,
                      color: brand.secondaryColor,
                      onTap: () => sensor.updateAutoScheduleSettings(
                        autoTrackEnabled: true,
                        auto24HourMode: false,
                        startHour: 5,
                        startMinute: 0,
                        endHour: 21,
                        endMinute: 0,
                      ),
                    ),
                    _buildPresetChip(
                      label: '06:00 - 22:00',
                      isSelected: !sensor.isAuto24HourMode &&
                          sensor.autoStartHour == 6 &&
                          sensor.autoEndHour == 22,
                      color: brand.secondaryColor,
                      onTap: () => sensor.updateAutoScheduleSettings(
                        autoTrackEnabled: true,
                        auto24HourMode: false,
                        startHour: 6,
                        startMinute: 0,
                        endHour: 22,
                        endMinute: 0,
                      ),
                    ),
                    _buildPresetChip(
                      label: '07:00 - 23:00',
                      isSelected: !sensor.isAuto24HourMode &&
                          sensor.autoStartHour == 7 &&
                          sensor.autoEndHour == 23,
                      color: brand.secondaryColor,
                      onTap: () => sensor.updateAutoScheduleSettings(
                        autoTrackEnabled: true,
                        auto24HourMode: false,
                        startHour: 7,
                        startMinute: 0,
                        endHour: 23,
                        endMinute: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.18)
              : HealthTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white12,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? accentColor : Colors.white54,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.22) : Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
