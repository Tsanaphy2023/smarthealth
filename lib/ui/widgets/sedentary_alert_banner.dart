import 'package:flutter/material.dart';
import '../../services/voice_alert_service.dart';
import '../theme/health_theme.dart';

class SedentaryAlertBanner extends StatelessWidget {
  final int sedentaryMinutes;
  final VoidCallback onDismiss;

  const SedentaryAlertBanner({
    super.key,
    required this.sedentaryMinutes,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2E0F12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HealthTheme.alertRed.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: HealthTheme.alertRed.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: HealthTheme.alertRed.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.record_voice_over, color: HealthTheme.alertRed, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'เสียงเตือน: "ลุกค่ะ ลุกค่ะ!"',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.volume_up, color: HealthTheme.alertRed, size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'คุณอยู่นิ่งต่อเนื่องมา $sedentaryMinutes นาทีแล้ว (เกินเกณฑ์ 30 นาที) ลุกขึ้นขยับร่างกายเพื่อกระตุ้นการไหลเวียนเลือดค่ะ',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'ฟังเสียงเตือนซ้ำ',
            icon: const Icon(Icons.play_circle_fill, color: HealthTheme.alertRed, size: 28),
            onPressed: () {
              VoiceAlertService().playSedentaryVoiceAlert(force: true);
            },
          ),
          IconButton(
            tooltip: 'ปิดการแจ้งเตือน',
            onPressed: onDismiss,
            icon: const Icon(Icons.close, color: Colors.white54, size: 18),
          ),
        ],
      ),
    );
  }
}
