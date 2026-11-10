enum Gender {
  male,
  female;

  String get displayName => this == Gender.male ? 'ชาย' : 'หญิง';
}

class UserHealthProfile {
  final double weightKg;
  final double heightCm;
  final int age;
  final Gender gender;

  const UserHealthProfile({
    this.weightKg = 65.0,
    this.heightCm = 170.0,
    this.age = 25,
    this.gender = Gender.male,
  });

  /// Dynamic Stride Length based on Height & Gender (in meters)
  /// Male ~ Height * 0.414, Female ~ Height * 0.413
  double get baseStrideLengthM {
    final factor = gender == Gender.male ? 0.414 : 0.413;
    return (heightCm * factor) / 100.0;
  }

  /// Body Mass Index (BMI) = kg / m^2
  double get bmi {
    final heightM = heightCm / 100.0;
    if (heightM <= 0) return 22.0;
    return weightKg / (heightM * heightM);
  }

  /// BMI Asian-Pacific standard classification
  String get bmiCategory {
    final val = bmi;
    if (val < 18.5) return 'น้ำหนักน้อยกว่าเกณฑ์ (Underweight)';
    if (val < 23.0) return 'สมส่วนตามเกณฑ์ (Normal)';
    if (val < 25.0) return 'น้ำหนักเกิน (Overweight)';
    return 'ภาวะอ้วน (Obese)';
  }

  /// Basal Metabolic Rate (BMR) - Mifflin-St Jeor Equation
  /// Male: 10 * W + 6.25 * H - 5 * A + 5
  /// Female: 10 * W + 6.25 * H - 5 * A - 161
  double get bmrKcal {
    final base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age);
    return gender == Gender.male ? (base + 5.0) : (base - 161.0);
  }

  /// Total Daily Energy Expenditure estimate (Sedentary baseline + active)
  double calculateTdeeKcal(double activeCalories) {
    return (bmrKcal * 1.2) + activeCalories;
  }

  /// Personalized Stride Distance in Km
  double calculateDistanceKm(int steps, double speedMultiplier) {
    final dynamicStride = baseStrideLengthM * speedMultiplier;
    return (steps * dynamicStride) / 1000.0;
  }

  /// Hydration loss in milliliters (ml)
  /// Estimated perspiration ~0.35 to 0.50 ml per step under standard ambient
  double calculateHydrationLossMl(int steps, double intensity) {
    final ratePerStep = 0.35 + (intensity * 0.25); // 0.35 - 0.60 ml/step
    return steps * ratePerStep;
  }

  UserHealthProfile copyWith({
    double? weightKg,
    double? heightCm,
    int? age,
    Gender? gender,
  }) {
    return UserHealthProfile(
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toJson() => {
    'weightKg': weightKg,
    'heightCm': heightCm,
    'age': age,
    'gender': gender.index,
  };

  factory UserHealthProfile.fromJson(Map<String, dynamic> json) => UserHealthProfile(
    weightKg: (json['weightKg'] as num?)?.toDouble() ?? 65.0,
    heightCm: (json['heightCm'] as num?)?.toDouble() ?? 170.0,
    age: (json['age'] as num?)?.toInt() ?? 25,
    gender: (json['gender'] as int?) == 1 ? Gender.female : Gender.male,
  );
}
