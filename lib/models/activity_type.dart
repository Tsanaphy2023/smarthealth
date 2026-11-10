import 'package:flutter/material.dart';

enum ActivityType {
  stationary(
    nameTh: 'อยู่นิ่ง / พักผ่อน',
    nameEn: 'Stationary / Idle',
    icon: Icons.chair_outlined,
    color: Color(0xFF94A3B8),
    met: 1.2,
  ),
  walking(
    nameTh: 'กำลังเดิน',
    nameEn: 'Walking',
    icon: Icons.directions_walk,
    color: Color(0xFF00E676),
    met: 3.5,
  ),
  running(
    nameTh: 'กำลังวิ่ง',
    nameEn: 'Running',
    icon: Icons.directions_run,
    color: Color(0xFFFF9100),
    met: 8.0,
  ),
  active(
    nameTh: 'ขยับร่างกายต่อเนื่อง',
    nameEn: 'Active Motion',
    icon: Icons.fitness_center,
    color: Color(0xFF00E5FF),
    met: 4.5,
  );

  final String nameTh;
  final String nameEn;
  final IconData icon;
  final Color color;
  final double met;

  const ActivityType({
    required this.nameTh,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.met,
  });

  double get metValue => met;
  String get thaiLabel => nameTh;
}
