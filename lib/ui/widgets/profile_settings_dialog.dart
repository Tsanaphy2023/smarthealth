import 'package:flutter/material.dart';
import '../../models/user_health_profile.dart';
import '../theme/health_theme.dart';

class ProfileSettingsDialog extends StatefulWidget {
  final UserHealthProfile profile;
  final ValueChanged<UserHealthProfile> onSave;

  const ProfileSettingsDialog({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<ProfileSettingsDialog> createState() => _ProfileSettingsDialogState();
}

class _ProfileSettingsDialogState extends State<ProfileSettingsDialog> {
  late double _weight;
  late double _height;
  late int _age;
  late Gender _gender;

  @override
  void initState() {
    super.initState();
    _weight = widget.profile.weightKg;
    _height = widget.profile.heightCm;
    _age = widget.profile.age;
    _gender = widget.profile.gender;
  }

  UserHealthProfile get _currentProfile => UserHealthProfile(
    weightKg: _weight,
    heightCm: _height,
    age: _age,
    gender: _gender,
  );

  @override
  Widget build(BuildContext context) {
    final preview = _currentProfile;

    return Dialog(
      backgroundColor: HealthTheme.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HealthTheme.cyanDistance.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: HealthTheme.cyanDistance, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'โปรไฟล์สรีรวิทยา & สุขภาพ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'คำนวณช่วงก้าว แคลอรี่ BMR และค่าสรีรวิทยาเฉพาะบุคคล',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Gender Selector
              const Text('เพศ (GENDER)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('ชาย (Male)')),
                      selected: _gender == Gender.male,
                      selectedColor: HealthTheme.cyanDistance.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: _gender == Gender.male ? HealthTheme.cyanDistance : Colors.white60,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _gender = Gender.male);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('หญิง (Female)')),
                      selected: _gender == Gender.female,
                      selectedColor: HealthTheme.orangeCalorie.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: _gender == Gender.female ? HealthTheme.orangeCalorie : Colors.white60,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _gender = Gender.female);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Weight Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('น้ำหนักตัว', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '${_weight.toStringAsFixed(1)} กก. (kg)',
                    style: const TextStyle(color: HealthTheme.emeraldStep, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: _weight,
                min: 30.0,
                max: 150.0,
                divisions: 240,
                activeColor: HealthTheme.emeraldStep,
                inactiveColor: Colors.white12,
                onChanged: (val) => setState(() => _weight = val),
              ),

              // Height Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ส่วนสูง', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '${_height.toStringAsFixed(0)} ซม. (cm)',
                    style: const TextStyle(color: HealthTheme.cyanDistance, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: _height,
                min: 120.0,
                max: 210.0,
                divisions: 90,
                activeColor: HealthTheme.cyanDistance,
                inactiveColor: Colors.white12,
                onChanged: (val) => setState(() => _height = val),
              ),

              // Age Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('อายุ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(
                    '$_age ปี (years)',
                    style: const TextStyle(color: HealthTheme.orangeCalorie, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: _age.toDouble(),
                min: 10.0,
                max: 100.0,
                divisions: 90,
                activeColor: HealthTheme.orangeCalorie,
                inactiveColor: Colors.white12,
                onChanged: (val) => setState(() => _age = val.round()),
              ),

              const SizedBox(height: 14),

              // Live Biometrics Calculation Preview Bento Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: HealthTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HealthTheme.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ดัชนีมวลกาย (BMI)', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(
                          '${preview.bmi.toStringAsFixed(1)} - ${preview.bmiCategory}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ความยาวก้าวฐาน (Base Stride)', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(
                          '${(preview.baseStrideLengthM * 100).toStringAsFixed(1)} ซม.',
                          style: const TextStyle(color: HealthTheme.cyanDistance, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('อัตราเผาผลาญพื้นฐาน (BMR)', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        Text(
                          '${preview.bmrKcal.round()} kcal / วัน',
                          style: const TextStyle(color: HealthTheme.orangeCalorie, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ยกเลิก', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HealthTheme.emeraldStep,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      widget.onSave(_currentProfile);
                      Navigator.pop(context);
                    },
                    child: const Text('บันทึกข้อมูล', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
