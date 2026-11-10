import 'package:flutter/material.dart';
import '../theme/health_theme.dart';

class GoalSettingDialog extends StatefulWidget {
  final int currentGoal;
  final Function(int newGoal) onSave;

  const GoalSettingDialog({
    super.key,
    required this.currentGoal,
    required this.onSave,
  });

  @override
  State<GoalSettingDialog> createState() => _GoalSettingDialogState();
}

class _GoalSettingDialogState extends State<GoalSettingDialog> {
  late int _selectedGoal;

  final List<int> _presetGoals = [6000, 8000, 10000, 12000, 15000];

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.currentGoal;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: HealthTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: HealthTheme.border),
      ),
      title: const Row(
        children: [
          Icon(Icons.flag, color: HealthTheme.emeraldStep, size: 22),
          SizedBox(width: 8),
          Text(
            'ตั้งเป้าหมายก้าวประจำวัน',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'เลือกเป้าหมายจำนวนก้าวที่เหมาะสมกับสุขภาพและการออกกำลังกายของคุณ',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 16),

          // Display selected goal
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: HealthTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HealthTheme.emeraldStep, width: 1.5),
            ),
            child: Text(
              '$_selectedGoal ก้าว / วัน',
              style: const TextStyle(
                color: HealthTheme.emeraldStep,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Presets wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetGoals.map((g) {
              final isSel = g == _selectedGoal;
              return ChoiceChip(
                selected: isSel,
                label: Text('$g'),
                labelStyle: TextStyle(
                  color: isSel ? Colors.black : Colors.white70,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
                selectedColor: HealthTheme.emeraldStep,
                backgroundColor: HealthTheme.surface,
                onSelected: (_) {
                  setState(() {
                    _selectedGoal = g;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: HealthTheme.emeraldStep,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            widget.onSave(_selectedGoal);
            Navigator.pop(context);
          },
          child: const Text('บันทึกเป้าหมาย', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
