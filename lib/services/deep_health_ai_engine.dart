import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/health_interval_record.dart';

/// ผลลัพธ์การฝึกสอนโมเดลการเรียนรู้เชิงลึกระดับอุปกรณ์ (On-Device Deep Learning Training Result)
class DeepTrainingResult {
  final int epochs;
  final double initialLoss;
  final double finalLoss;
  final double lossReductionPercent;
  final int totalParametersTrained;
  final DateTime trainedAt;

  const DeepTrainingResult({
    required this.epochs,
    required this.initialLoss,
    required this.finalLoss,
    required this.lossReductionPercent,
    required this.totalParametersTrained,
    required this.trainedAt,
  });
}

/// ผลการวินิจฉัยเชิงลึกด้วยโครงข่ายประสาทเทียม
class DeepHealthInference {
  final String statusTitle;
  final String description;
  final double confidence;
  final List<double> classProbabilities;
  final double forecastedCaloriesNext4h;
  final double forecastedWaterNext4hMl;
  final String exerciseRecommendation;

  const DeepHealthInference({
    required this.statusTitle,
    required this.description,
    required this.confidence,
    required this.classProbabilities,
    required this.forecastedCaloriesNext4h,
    required this.forecastedWaterNext4hMl,
    required this.exerciseRecommendation,
  });
}

/// โมเดลโครงข่ายประสาทเทียมเชิงลึกแบบปรับตัว On-Device สำหรับการวิเคราะห์จลนศาสตร์และสรีรวิทยา
class DeepHealthAiEngine {
  static final DeepHealthAiEngine _instance = DeepHealthAiEngine._internal();
  factory DeepHealthAiEngine() => _instance;
  DeepHealthAiEngine._internal() {
    _initializeWeights();
  }

  // ขนาดมิติของเลเยอร์: 6 -> 8 -> 6 -> 4
  static const int inputDim = 6;
  static const int hidden1Dim = 8;
  static const int hidden2Dim = 6;
  static const int outputDim = 4;

  late List<List<double>> _w1;
  late List<double> _b1;
  late List<List<double>> _w2;
  late List<double> _b2;
  late List<List<double>> _w3;
  late List<double> _b3;

  int _trainedEpochCount = 0;
  double _currentModelLoss = 0.384;
  DeepTrainingResult? _lastTrainingResult;

  int get trainedEpochCount => _trainedEpochCount;
  double get currentModelLoss => _currentModelLoss;
  DeepTrainingResult? get lastTrainingResult => _lastTrainingResult;

  /// การสุ่มค่าน้ำหนักเริ่มต้นตามการแจกแจงแบบ He (Kaiming Normal Initialization)
  void _initializeWeights() {
    final rand = math.Random(42);
    _w1 = List.generate(
      hidden1Dim,
      (_) => List.generate(inputDim, (_) => (rand.nextDouble() * 2 - 1) * math.sqrt(2.0 / inputDim)),
    );
    _b1 = List.filled(hidden1Dim, 0.05);

    _w2 = List.generate(
      hidden2Dim,
      (_) => List.generate(hidden1Dim, (_) => (rand.nextDouble() * 2 - 1) * math.sqrt(2.0 / hidden1Dim)),
    );
    _b2 = List.filled(hidden2Dim, 0.05);

    _w3 = List.generate(
      outputDim,
      (_) => List.generate(hidden2Dim, (_) => (rand.nextDouble() * 2 - 1) * math.sqrt(2.0 / hidden2Dim)),
    );
    _b3 = List.filled(outputDim, 0.02);
  }

  /// ฟังก์ชันกระตุ้น LeakyReLU
  double _leakyRelu(double x) => x > 0 ? x : 0.08 * x;
  double _leakyReluDerivative(double x) => x > 0 ? 1.0 : 0.08;

  /// ฟังก์ชันกระตุ้น Tanh
  double _tanh(double x) => (math.exp(x) - math.exp(-x)) / (math.exp(x) + math.exp(-x));
  double _tanhDerivative(double tanhVal) => 1.0 - (tanhVal * tanhVal);

  /// การสกัดและปรับมาตรวัดคุณลักษณะ (Feature Normalization) จากข้อมูลรอบ 4 ชั่วโมง
  List<double> extractFeatures({
    required int steps4h,
    required int meanCadence,
    required int sedentaryMinutes,
    required double motionIntensity,
    required double calories,
    required double hydrationLossMl,
  }) {
    // 1. ความเร็วและปริมาณก้าว (normalized 0..10,000)
    final f1 = (steps4h / 5000.0).clamp(0.0, 2.0);
    // 2. จังหวะความถี่ก้าว (normalized 0..160 SPM)
    final f2 = (meanCadence / 120.0).clamp(0.0, 1.5);
    // 3. ดัชนีการเคลื่อนไหวต่อเนื่อง vs การแกว่งตัว
    final f3 = motionIntensity.clamp(0.0, 1.0);
    // 4. สัดส่วนการนั่งนิ่งในรอบ 4 ชม. (240 นาที)
    final f4 = (sedentaryMinutes / 240.0).clamp(0.0, 1.0);
    // 5. อัตราการเผาผลาญเทียบเคียง (normalized 0..600 kcal)
    final f5 = (calories / 400.0).clamp(0.0, 2.0);
    // 6. ภาวะสมดุลน้ำและการสูญเสียเหงื่อ
    final f6 = (hydrationLossMl / 1000.0).clamp(0.0, 2.0);

    return [f1, f2, f3, f4, f5, f6];
  }

  /// การส่งสัญญาณไปข้างหน้า (Forward Propagation)
  List<double> forwardPass(List<double> x, {List<double>? h1Out, List<double>? h2Out}) {
    // Hidden Layer 1
    final h1 = List<double>.filled(hidden1Dim, 0.0);
    for (int i = 0; i < hidden1Dim; i++) {
      double sum = _b1[i];
      for (int j = 0; j < inputDim; j++) {
        sum += _w1[i][j] * x[j];
      }
      h1[i] = _leakyRelu(sum);
    }
    if (h1Out != null) {
      h1Out.clear();
      h1Out.addAll(h1);
    }

    // Hidden Layer 2
    final h2 = List<double>.filled(hidden2Dim, 0.0);
    for (int i = 0; i < hidden2Dim; i++) {
      double sum = _b2[i];
      for (int j = 0; j < hidden1Dim; j++) {
        sum += _w2[i][j] * h1[j];
      }
      h2[i] = _tanh(sum);
    }
    if (h2Out != null) {
      h2Out.clear();
      h2Out.addAll(h2);
    }

    // Output Layer (Logits)
    final logits = List<double>.filled(outputDim, 0.0);
    for (int i = 0; i < outputDim; i++) {
      double sum = _b3[i];
      for (int j = 0; j < hidden2Dim; j++) {
        sum += _w3[i][j] * h2[j];
      }
      logits[i] = sum;
    }

    // Softmax Activation
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sumExps = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / (sumExps > 0 ? sumExps : 1.0)).toList();
  }

  /// วิเคราะห์ข้อมูลรอบ 4 ชั่วโมงด้วยโมเดลโครงข่ายประสาทเทียม
  DeepHealthInference analyze4HourInterval({
    required int steps4h,
    required int meanCadence,
    required int sedentaryMinutes,
    required double motionIntensity,
    required double calories,
    required double hydrationLossMl,
  }) {
    final features = extractFeatures(
      steps4h: steps4h,
      meanCadence: meanCadence,
      sedentaryMinutes: sedentaryMinutes,
      motionIntensity: motionIntensity,
      calories: calories,
      hydrationLossMl: hydrationLossMl,
    );

    final probs = forwardPass(features);

    // คลาสที่มีความน่าจะเป็นสูงสุด
    int maxIdx = 0;
    double maxProb = probs[0];
    for (int i = 1; i < outputDim; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIdx = i;
      }
    }

    // พยากรณ์ช่วง 4 ชั่วโมงข้างหน้า
    final double forecastCalories = (steps4h > 1500 ? calories * 1.05 : 180.0) + (meanCadence * 0.4);
    final double forecastWaterMl = (hydrationLossMl > 200 ? hydrationLossMl * 1.15 : 450.0);

    String title;
    String desc;
    String rec;

    switch (maxIdx) {
      case 0:
        title = 'จังหวะก้าวปกติสมบูรณ์ (Balanced Gait)';
        desc = 'การกระจายแรงกระแทกและจังหวะก้าวสม่ำเสมอ ชีวกลศาสตร์การเดินอยู่ในสภาวะสมดุลยอดเยี่ยม';
        rec = 'รักษาระดับการเดินต่อเนื่อง 100-110 SPM เพื่อส่งเสริมหลอดเลือดหัวใจ';
        break;
      case 1:
        title = 'สัญญาณกล้ามเนื้อล้าสะสม (Muscle Fatigue Detected)';
        desc = 'ตรวจพบความแปรปรวนของจังหวะก้าวสูงและการลดลงของแอมพลิจูดความเร่ง บ่งชี้กล้ามเนื้อขาส่วนล่างเริ่มล้า';
        rec = 'แนะนำยืดเหยียดกล้ามเนื้อน่องและสะโพก 3-5 นาที และพักดื่มน้ำ';
        break;
      case 2:
        title = 'แอโรบิกประสิทธิภาพสูง (High Aerobic Efficiency)';
        desc = 'ความถี่ก้าวอยู่ในช่วงคาร์ดิโอที่เหมาะสม มีอัตราการเผาผลาญไขมันสูงสุด (Fat-Burning Zone)';
        rec = 'จิบน้ำชดเชยทุกๆ 15-20 นาที เพื่อป้องกันภาวะขาดน้ำในเลือด';
        break;
      case 3:
      default:
        title = 'ความเสี่ยงการนั่งนิ่งผิดปกติ (Sedentary Stagnation)';
        desc = 'มีการอยู่นิ่งติดต่อกันนาน ระบบการไหลเวียนเลือดดำส่วนล่างชะลอตัว เอนไซม์ LPL ทำงานลดลง';
        rec = 'ลุกขึ้นยืน แกว่งแขน หรือเดินเปลี่ยนอิริยาบถทันทีอย่างน้อย 30 ก้าว!';
        break;
    }

    return DeepHealthInference(
      statusTitle: title,
      description: desc,
      confidence: maxProb,
      classProbabilities: probs,
      forecastedCaloriesNext4h: forecastCalories,
      forecastedWaterNext4hMl: forecastWaterMl,
      exerciseRecommendation: rec,
    );
  }

  /// การฝึกสอนแบบ On-Device Deep Learning ด้วยอัลกอริทึม Backpropagation และ SGD
  Future<DeepTrainingResult> trainOnUserKinematics({
    required List<HealthIntervalRecord> historicalRecords,
    int epochs = 12,
    double learningRate = 0.045,
  }) async {
    if (historicalRecords.isEmpty) {
      // สร้างชุดข้อมูลเสมือนจริงสำหรับการเทรนเริ่มต้น
      return _trainSyntheticBaseline(epochs, learningRate);
    }

    double initialLoss = 0.0;
    double finalLoss = 0.0;

    // เตรียมคู่ Input & Target One-Hot
    final List<List<double>> trainingInputs = [];
    final List<List<double>> trainingTargets = [];

    for (final rec in historicalRecords) {
      final x = extractFeatures(
        steps4h: rec.steps,
        meanCadence: rec.meanCadenceSpm,
        sedentaryMinutes: rec.sedentaryMinutes,
        motionIntensity: rec.motionIntensity,
        calories: rec.caloriesKcal,
        hydrationLossMl: rec.hydrationMl,
      );

      // กำหนดเป้าหมายการจำแนกตามพฤติกรรมจริง
      final target = List<double>.filled(outputDim, 0.0);
      if (rec.sedentaryMinutes > 150) {
        target[3] = 1.0; // Sedentary
      } else if (rec.meanCadenceSpm >= 115) {
        target[2] = 1.0; // High Aerobic
      } else if (rec.motionIntensity > 0.4 && rec.meanCadenceSpm < 85) {
        target[1] = 1.0; // Fatigue
      } else {
        target[0] = 1.0; // Balanced
      }

      trainingInputs.add(x);
      trainingTargets.add(target);
    }

    // คำนวณ Loss ก่อนเทรน
    for (int k = 0; k < trainingInputs.length; k++) {
      final p = forwardPass(trainingInputs[k]);
      initialLoss += _crossEntropyLoss(p, trainingTargets[k]);
    }
    initialLoss /= trainingInputs.length;

    // วงรอบการเทรนโครงข่ายประสาทเทียม (Epochs)
    final h1 = <double>[];
    final h2 = <double>[];

    for (int ep = 0; ep < epochs; ep++) {
      double epochLoss = 0.0;

      for (int k = 0; k < trainingInputs.length; k++) {
        final x = trainingInputs[k];
        final y = trainingTargets[k];

        // 1. Forward Pass พร้อมบันทึกสถานะ Activation
        final probs = forwardPass(x, h1Out: h1, h2Out: h2);
        epochLoss += _crossEntropyLoss(probs, y);

        // 2. Backpropagation: คำนวณ Gradient Output Layer
        final dLogits = List<double>.filled(outputDim, 0.0);
        for (int i = 0; i < outputDim; i++) {
          dLogits[i] = probs[i] - y[i]; // Softmax Cross-Entropy gradient
        }

        // Gradients สำหรับ W3 และ b3
        final dW3 = List.generate(
          outputDim,
          (i) => List.generate(hidden2Dim, (j) => dLogits[i] * h2[j]),
        );
        final db3 = List<double>.from(dLogits);

        // Gradient ส่งผ่านสู่ Hidden Layer 2
        final dH2 = List<double>.filled(hidden2Dim, 0.0);
        for (int j = 0; j < hidden2Dim; j++) {
          double sum = 0.0;
          for (int i = 0; i < outputDim; i++) {
            sum += _w3[i][j] * dLogits[i];
          }
          dH2[j] = sum * _tanhDerivative(h2[j]);
        }

        // Gradients สำหรับ W2 และ b2
        final dW2 = List.generate(
          hidden2Dim,
          (i) => List.generate(hidden1Dim, (j) => dH2[i] * h1[j]),
        );
        final db2 = List<double>.from(dH2);

        // Gradient ส่งผ่านสู่ Hidden Layer 1
        final dH1 = List<double>.filled(hidden1Dim, 0.0);
        for (int j = 0; j < hidden1Dim; j++) {
          double sum = 0.0;
          for (int i = 0; i < hidden2Dim; i++) {
            sum += _w2[i][j] * dH2[i];
          }
          dH1[j] = sum * _leakyReluDerivative(h1[j]);
        }

        // Gradients สำหรับ W1 และ b1
        final dW1 = List.generate(
          hidden1Dim,
          (i) => List.generate(inputDim, (j) => dH1[i] * x[j]),
        );
        final db1 = List<double>.from(dH1);

        // 3. Stochastic Gradient Descent (SGD) Parameter Update
        for (int i = 0; i < outputDim; i++) {
          _b3[i] -= learningRate * db3[i];
          for (int j = 0; j < hidden2Dim; j++) {
            _w3[i][j] -= learningRate * dW3[i][j];
          }
        }

        for (int i = 0; i < hidden2Dim; i++) {
          _b2[i] -= learningRate * db2[i];
          for (int j = 0; j < hidden1Dim; j++) {
            _w2[i][j] -= learningRate * dW2[i][j];
          }
        }

        for (int i = 0; i < hidden1Dim; i++) {
          _b1[i] -= learningRate * db1[i];
          for (int j = 0; j < inputDim; j++) {
            _w1[i][j] -= learningRate * dW1[i][j];
          }
        }
      }

      finalLoss = epochLoss / trainingInputs.length;
    }

    _trainedEpochCount += epochs;
    _currentModelLoss = finalLoss;

    final reduction = initialLoss > 0 ? ((initialLoss - finalLoss) / initialLoss) * 100.0 : 0.0;
    final totalParams = (inputDim * hidden1Dim + hidden1Dim) +
        (hidden1Dim * hidden2Dim + hidden2Dim) +
        (hidden2Dim * outputDim + outputDim);

    _lastTrainingResult = DeepTrainingResult(
      epochs: epochs,
      initialLoss: initialLoss,
      finalLoss: finalLoss,
      lossReductionPercent: reduction.clamp(0.0, 100.0),
      totalParametersTrained: totalParams,
      trainedAt: DateTime.now(),
    );

    debugPrint('[AI] On-Device Deep Learning finished: ${epochs} epochs, Loss: ${initialLoss.toStringAsFixed(3)} -> ${finalLoss.toStringAsFixed(3)} (-${reduction.toStringAsFixed(1)}%)');
    return _lastTrainingResult!;
  }

  double _crossEntropyLoss(List<double> probs, List<double> target) {
    double loss = 0.0;
    for (int i = 0; i < probs.length; i++) {
      if (target[i] > 0) {
        loss -= target[i] * math.log(math.max(probs[i], 1e-9));
      }
    }
    return loss;
  }

  Future<DeepTrainingResult> _trainSyntheticBaseline(int epochs, double lr) async {
    // ชุดข้อมูลพื้นฐานจำลอง 12 จุด
    final dummy = List.generate(
      12,
      (i) => HealthIntervalRecord(
        id: 'init_$i',
        startTime: DateTime.now().subtract(Duration(hours: 4 * (12 - i))),
        endTime: DateTime.now().subtract(Duration(hours: 4 * (11 - i))),
        steps: 800 + (i * 250),
        distanceKm: 0.6 + (i * 0.18),
        caloriesKcal: 40.0 + (i * 18.0),
        hydrationMl: 100.0 + (i * 45.0),
        meanCadenceSpm: 90 + (i % 4) * 8,
        maxCadenceSpm: 125,
        sedentaryMinutes: 180 - (i * 8),
        motionIntensity: 0.25 + (i * 0.03),
        aiDiagnosis: 'กำลังวิเคราะห์พื้นฐาน',
        aiConfidence: 0.88,
      ),
    );
    return trainOnUserKinematics(historicalRecords: dummy, epochs: epochs, learningRate: lr);
  }
}
