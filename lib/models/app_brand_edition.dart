import 'package:flutter/material.dart';

/// โหมดแบรนด์แอปพลิเคชันคู่ (Dual-Brand Edition):
/// 1. ChewaPulse xAI (ชีวะพัลส์ เอ็กซ์เอไอ)
/// 2. SciRBRU Move+AI (ไซน์-อาร์บีอาร์ยู มูฟพลัสเอไอ)
enum AppBrandEdition {
  chewaPulseXai,
  sciRbruMoveAi;

  String get appName {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return 'ChewaPulse xAI';
      case AppBrandEdition.sciRbruMoveAi:
        return 'SciRBRU Move+AI';
    }
  }

  String get thaiName {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return 'ชีวะพัลส์ เอ็กซ์เอไอ';
      case AppBrandEdition.sciRbruMoveAi:
        return 'ไซน์-อาร์บีอาร์ยู มูฟพลัสเอไอ';
    }
  }

  /// คำโปรยที่เป็นมิตรและเข้าใจง่าย (แทนคำว่าชีวกลศาสตร์)
  String get tagline {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return 'สมดุลจังหวะก้าวเดิน & โค้ชสุขภาพอัจฉริยะ';
      case AppBrandEdition.sciRbruMoveAi:
        return 'อัจฉริยภาพการเคลื่อนไหว & พลังงานสุขภาพดิจิทัล';
    }
  }

  String get badgeText {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return 'xAI PULSE';
      case AppBrandEdition.sciRbruMoveAi:
        return 'SciRBRU+AI';
    }
  }

  String get switchButtonLabel {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return 'สลับเป็น SciRBRU Move+AI';
      case AppBrandEdition.sciRbruMoveAi:
        return 'สลับเป็น ChewaPulse xAI';
    }
  }

  String get aiCardTitle {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return 'โค้ชวิเคราะห์สุขภาพ ChewaPulse xAI';
      case AppBrandEdition.sciRbruMoveAi:
        return 'ศูนย์วิเคราะห์การขยับตัว SciRBRU Move+AI';
    }
  }

  String get aiCardSubtitle {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return 'Explainable AI วิเคราะห์จังหวะก้าวและสมดุลราย 4 ชม.';
      case AppBrandEdition.sciRbruMoveAi:
        return 'นวัตกรรมสุขภาพดิจิทัล คณะวิทยาศาสตร์และเทคโนโลยี มรภ.รำไพพรรณี';
    }
  }

  String get developerCredit {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return 'ออกแบบและพัฒนาโดย ผศ.ดร.ชีวะ ทัศนา';
      case AppBrandEdition.sciRbruMoveAi:
        return 'ผศ.ดร.ชีวะ ทัศนา • คณะวิทยาศาสตร์และเทคโนโลยี มรภ.รำไพพรรณี';
    }
  }

  String get iconAsset {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return 'assets/icons/app_icon_chewapulse.png';
      case AppBrandEdition.sciRbruMoveAi:
        return 'assets/icons/app_icon_scirbru.png';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return const Color(0xFF00E676); // Cyber Emerald
      case AppBrandEdition.sciRbruMoveAi:
        return const Color(0xFFFFD54F); // SciRBRU Royal Gold
    }
  }

  Color get secondaryColor {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return const Color(0xFF00E5FF); // Neon Cyan
      case AppBrandEdition.sciRbruMoveAi:
        return const Color(0xFF38BDF8); // Sapphire Sky Blue
    }
  }

  Color get accentColor {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return const Color(0xFFFF6D00); // Pulse Orange
      case AppBrandEdition.sciRbruMoveAi:
        return const Color(0xFFF43F5E); // RBRU Rose Pink
    }
  }

  List<Color> get backgroundGradient {
    switch (this) {
      case AppBrandEdition.chewaPulseXai:
        return const [
          Color(0xFF07111A),
          Color(0xFF0C1A26),
          Color(0xFF090D16),
        ];
      case AppBrandEdition.sciRbruMoveAi:
        return const [
          Color(0xFF0B132B),
          Color(0xFF141E3C),
          Color(0xFF090D18),
        ];
    }
  }
}

/// ข้อมูลสรุปสถิติสุขภาพรายวันสำหรับกราฟย้อนหลัง 7 วัน (Weekly History)
class DailyHistorySummary {
  final String dayLabel; // เช่น 'จ.', 'อ.', 'พ.', 'วันนี้'
  final String fullDateLabel;
  final int steps;
  final int stepGoal;
  final double caloriesKcal;
  final double distanceKm;
  final int activeMinutes;
  final double weightKg;

  const DailyHistorySummary({
    required this.dayLabel,
    required this.fullDateLabel,
    required this.steps,
    required this.stepGoal,
    required this.caloriesKcal,
    required this.distanceKm,
    required this.activeMinutes,
    required this.weightKg,
  });

  double get completionRatio => (steps / (stepGoal > 0 ? stepGoal : 10000)).clamp(0.0, 1.5);
  bool get isGoalMet => steps >= stepGoal;
}
