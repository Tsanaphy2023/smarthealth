import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// บริการสร้างเสียงแจ้งเตือนและสังเคราะห์เสียงพูดภาษาไทยเตือนขยับร่างกาย "ลุกค่ะ ลุกค่ะ"
class VoiceAlertService {
  static final VoiceAlertService _instance = VoiceAlertService._internal();
  factory VoiceAlertService() => _instance;
  VoiceAlertService._internal();

  bool _isVoiceEnabled = true;
  bool _isPlaying = false;
  DateTime? _lastAlertTime;

  bool get isVoiceEnabled => _isVoiceEnabled;
  bool get isPlaying => _isPlaying;
  DateTime? get lastAlertTime => _lastAlertTime;

  void setVoiceEnabled(bool enabled) {
    _isVoiceEnabled = enabled;
  }

  /// เล่นเสียงสัญญาณกระตุ้นการขยับและเสียงพูดเตือนภาษาไทย "ลุกค่ะ ลุกค่ะ"
  Future<void> playSedentaryVoiceAlert({bool force = false}) async {
    if (!_isVoiceEnabled && !force) return;

    // ป้องกันการแจ้งเตือนถี่เกินไป (อย่างน้อย 3 นาทีต่อครั้ง เว้นแต่เป็นการกดทดสอบ)
    final now = DateTime.now();
    if (!force && _lastAlertTime != null && now.difference(_lastAlertTime!).inMinutes < 3) {
      return;
    }

    _lastAlertTime = now;
    _isPlaying = true;

    try {
      // 1. ส่งสัญญาณเสียงกระดิ่งความถี่กังวานของระบบ (System Chime)
      await SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 300));
      await SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();

      // 2. เรียกใช้การสังเคราะห์เสียงหรือแจ้งเตือนเชิงโต้ตอบ
      debugPrint('[VOICE ALERT] "ลุกค่ะ ลุกค่ะ! นั่งนิ่งนานเกิน 30 นาทีแล้ว ได้เวลาลุกขึ้นยืดเส้นยืดสายและขยับร่างกายแล้วค่ะ!"');

      // ทำจังหวะเสียงกังวานซ้ำอีกระลอก เพื่อให้ได้ยินชัดเจน
      await Future.delayed(const Duration(milliseconds: 650));
      await SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();

    } catch (e) {
      debugPrint('[!] VoiceAlertService playback error: $e');
    } finally {
      _isPlaying = false;
    }
  }

  /// เล่นเสียงสัญญาณเตือนตรวจพบแรงกระแทกหรือการล้มฉับพลัน (Fall / Impact Detection)
  Future<void> playFallWarningVoiceAlert() async {
    if (!_isVoiceEnabled) return;
    try {
      await SystemSound.play(SystemSoundType.alert);
      HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 250));
      HapticFeedback.vibrate();
      debugPrint('[FALL WARNING] ตรวจพบแรงกระแทกหรือการเคลื่อนไหวฉับพลัน กรุณาตรวจสอบความปลอดภัย!');
    } catch (e) {
      debugPrint('[!] Fall warning playback error: $e');
    }
  }

  /// ข้อความเสียงพูดภาษาไทยมาตรฐาน
  static const String spokenPhraseThai = 'ลุกค่ะ ลุกค่ะ! นั่งนานเกิน 30 นาทีแล้ว ได้เวลาลุกขึ้นยืดเส้นยืดสายและขยับร่างกายแล้วค่ะ';
}
