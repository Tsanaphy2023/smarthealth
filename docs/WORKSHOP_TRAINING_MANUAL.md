# คู่มือการจัดกิจกรรมอบรมเชิงปฏิบัติการ (Workshop Training Manual)
## หลักสูตร: การพัฒนาแอปพลิเคชันสมาร์ทโฟนเพื่อสุขภาพและการตรวจจับการเคลื่อนไหวร่างกาย
### (Digital Health & Kinematic Mobile Application Development with Flutter & Physics-Informed AI)

---

> **จัดทำโดย**: หน่วยวิเคราะห์-ติดตามคุณภาพดินและสภาพอากาศเชิงพื้นที่  
> ร่วมกับศูนย์ความเป็นเลิศด้านเทคโนโลยีสุขภาพและปัญญาประดิษฐ์ มหาวิทยาลัยราชภัฏรำไพพรรณี  
> **กลุ่มเป้าหมาย**: นักศึกษา, คณาจารย์, นักวิจัย, นักพัฒนาซอฟต์แวร์ และผู้สนใจด้านวิทยาศาสตร์สุขภาพดิจิทัล (Digital Health)  
> **ระยะเวลาการอบรม**: 1 วันเต็ม (6 ชั่วโมง) หรือแบ่งเป็น 2 วัน (วันละ 3 ชั่วโมง)  
> **โค้ดโปรเจกต์อ้างอิง**: `smart_health_tracker/`

---

## สารบัญหลักสูตร (Workshop Curriculum)

1. [โครงสร้างและผลลัพธ์การเรียนรู้ (Learning Outcomes & Schedule)](#1-โครงสร้างและผลลัพธ์การเรียนรู้)
2. [Module 1: สถาปัตยกรรมสุขภาพดิจิทัลและเซนเซอร์สมาร์ทโฟน](#module-1-สถาปัตยกรรมสุขภาพดิจิทัลและเซนเซอร์สมาร์ทโฟน)
3. [Module 2: ฟิสิกส์และการประมวลผลสัญญาณการเคลื่อนไหว (Physics-Informed Signal Processing)](#module-2-ฟิสิกส์และการประมวลผลสัญญาณการเคลื่อนไหว)
4. [Module 3: เวชศาสตร์การออกกำลังกายและชีวกลศาสตร์ในซอฟต์แวร์ (Exercise Science & Biomechanics)](#module-3-เวชศาสตร์การออกกำลังกายและชีวกลศาสตร์ในซอฟต์แวร์)
5. [Module 4: การออกแบบ UI/UX สไตล์ Bento Grid และระบบ Responsive รองรับทุกขนาดหน้าจอ](#module-4-การออกแบบ-uiux-สไตล์-bento-grid-และระบบ-responsive)
6. [Module 5: ปฏิบัติการทีละขั้นตอน (Step-by-Step Hands-on Labs)](#module-5-ปฏิบัติการทีละขั้นตอน-step-by-step-hands-on-labs)
   - [Lab 1: การติดตั้ง Environment และกำหนดสิทธิ์ Android](#lab-1-การติดตั้ง-environment-และกำหนดสิทธิ์-android)
   - [Lab 2: การพัฒนา MovementSensorService และ Peak Detection](#lab-2-การพัฒนา-movementsensorservice-และ-peak-detection)
   - [Lab 3: การคำนวณ Cadence, Stride Length, BMR และ TDEE](#lab-3-การคำนวณ-cadence-stride-length-bmr-และ-tdee)
   - [Lab 4: การสร้าง Bento Grid Dashboard และ Adaptive Breakpoints](#lab-4-การสร้าง-bento-grid-dashboard-และ-adaptive-breakpoints)
   - [Lab 5: การทดสอบอัตโนมัติ (Flutter Test) และการ Deploy สู่สมาร์ทโฟนจริง](#lab-5-การทดสอบอัตโนมัติ-และการ-deploy-สู่สมาร์ทโฟนจริง)
7. [Module 6: การประเมินผลและการต่อยอดเชิงวิจัยและนวัตกรรม](#module-6-การประเมินผลและการต่อยอดเชิงวิจัยและนวัตกรรม)

---

## 1. โครงสร้างและผลลัพธ์การเรียนรู้

### ผลลัพธ์การเรียนรู้ที่คาดหวัง (Expected Learning Outcomes - ELOs)
เมื่อสิ้นสุดการอบรมเชิงปฏิบัติการ ผู้เข้าร่วมอบรมจะสามารถ:
1. **ELO-1**: อธิบายหลักการทำงานของเซนเซอร์ Accelerometer บนสมาร์ทโฟน และคณิตศาสตร์เวกเตอร์ 3 แกนได้
2. **ELO-2**: เขียนอัลกอริทึมกรองสัญญาณ (Filter) เพื่อแยกแยะแรงโน้มถ่วง ตรวจจับยอดคลื่น (Peak Detection) และนับก้าวได้อย่างแม่นยำ
3. **ELO-3**: บูรณาการทฤษฎีเวชศาสตร์การออกกำลังกาย (Cadence, MET, BMR, TDEE, Stride adaptation) ลงในซอฟต์แวร์จริงได้
4. **ELO-4**: ออกแบบหน้าจอแดชบอร์ดสุขภาพสไตล์ Bento Grid และเขียนโค้ดรองรับการปรับสัดส่วนอัตโนมัติตามทุกขนาดหน้าจอ (Smartphones, Foldables, Tablets) โดยปราศจากข้อผิดพลาด RenderFlex Overflow
5. **ELO-5**: Build, Debug และ Deploy แอปพลิเคชันลงในสมาร์ทโฟน Android ผ่านเครื่องมือ ADB ได้สำเร็จ

### กำหนดการอบรมเชิงปฏิบัติการ 1 วัน (6 ชั่วโมง)
| ช่วงเวลา | หัวข้อการบรรยายและปฏิบัติการ | รูปแบบกิจกรรม |
| :---: | :--- | :---: |
| **09:00 - 10:00** | **Module 1 & 2**: ทฤษฎีเซนเซอร์สมาร์ทโฟน, เวกเตอร์ 3 แกน, Dynamic Peak Detection | บรรยาย + สาธิตกราฟสัญญาณสด |
| **10:00 - 10:15** | *พักรับประทานอาหารว่าง (Morning Break)* | - |
| **10:15 - 12:00** | **Module 3 & Hands-on Lab 1-2**: ลงมือเขียนโค้ดอัลกอริทึมนับก้าว และทดสอบด้วย Walking Simulator | ปฏิบัติการคอมพิวเตอร์ (Hands-on) |
| **12:00 - 13:00** | *พักรับประทานอาหารกลางวัน (Lunch)* | - |
| **13:00 - 14:15** | **Module 4 & Hands-on Lab 3**: คำนวณ Cadence, สรีรวิทยาการเผาผลาญ BMR/TDEE และสมดุลน้ำดื่ม | บรรยาย + ปฏิบัติการโค้ดชีวกลศาสตร์ |
| **14:15 - 14:30** | *พักรับประทานอาหารว่าง (Afternoon Break)* | - |
| **14:30 - 16:00** | **Module 5 & Hands-on Lab 4-5**: สร้าง Adaptive Bento Grid UI, รัน Test และ Deploy ลงสมาร์ทโฟน | ปฏิบัติการ + ติดตั้งลงเครื่องจริง |
| **16:00 - 16:30** | **Module 6 & Q&A**: สรุปบทเรียน มอบประกาศนียบัตร และแนวทางการต่อยอดสู่ Health AI | สรุปผลและตอบข้อซักถาม |

---

## Module 1: สถาปัตยกรรมสุขภาพดิจิทัลและเซนเซอร์สมาร์ทโฟน

### 1.1 เซนเซอร์ Accelerometer บนสมาร์ทโฟนทำงานอย่างไร?
สมาร์ทโฟนยุคใหม่มีชิปเซมิคอนดักเตอร์ประเภท **MEMS (Micro-Electro-Mechanical Systems)** ซึ่งมีมวลขนาดจิ๋วแขวนอยู่บนโครงสร้างสปริงซิลิคอน เมื่อโทรศัพท์เคลื่อนที่ มวลจะขยับทำให้ค่าความจุไฟฟ้า (Capacitance) เปลี่ยนแปลง ชิปจะแปลงเป็นค่าความเร่งใน 3 แกนอิสระ:
* **แกน X ($a_x$)**: ความเร่งในแนวขวาง ซ้าย-ขวา
* **แกน Y ($a_y$)**: ความเร่งในแนวยาว บน-ล่าง (ขนานกับความยาวตัวเครื่อง)
* **แกน Z ($a_z$)**: ความเร่งในแนวตั้งฉาก พุ่งเข้า-ออกจากหน้าจอ

### 1.2 ความท้าทาย: สัญญาณความเร่งแบบรวม (Total Acceleration) เทียบกับ ความเร่งผู้ใช้ (User Acceleration)
เมื่อสมาร์ทโฟนอยู่นิ่งบนโต๊ะ เซนเซอร์ Accelerometer ทั่วไปจะยังคงวัดได้ความเร่งโน้มถ่วงโลก ($g \approx 9.80665 \text{ m/s}^2$) ในแกนที่ชี้ลงพื้น ดังนั้น ในการพัฒนาแอปพลิเคชันตรวจจับก้าวเดิน เราจำเป็นต้องใช้ **User Accelerometer** (ความเร่งที่ไม่รวมเวกเตอร์แรงโน้มถ่วง) หรือทำ **High-Pass Filter** เพื่อตัดค่าคงที่ของแรงโน้มถ่วงออก

---

## Module 2: ฟิสิกส์และการประมวลผลสัญญาณการเคลื่อนไหว

### 2.1 การคำนวณขนาดเวกเตอร์ลัพธ์ความเร่ง (Vector Magnitude)
เนื่องจากผู้ใช้งานสามารถถือสมาร์ทโฟนในท่าทางใดก็ได้ (ถือในมือ, ใส่กระเป๋ากางเกง, สะพายกระเป๋า) เราจึงไม่สามารถอิงกับแกนใดแกนหนึ่งได้ อัลกอริทึมต้องคำนวณ **ขนาดเวกเตอร์ความเร่งลัพธ์ (Euclidean Magnitude)**:

$$M = \sqrt{a_x^2 + a_y^2 + a_z^2}$$

### 2.2 อัลกอริทึม Dynamic Peak Detection พร้อม Refractory Period
การก้าวเท้าของมนุษย์ประกอบด้วย 2 จังหวะหลัก:
1. **Heel-Strike (ส้นเท้าสัมผัสพื้น)**: ก่อให้เกิดยอดคลื่นความเร่งสูงฉับพลัน (Peak)
2. **Swing Phase (จังหวะยกเท้าก้าวไปข้างหน้า)**: ความเร่งจะลดฮวบลง

```
ความเร่ง (m/s²)
 ^
 |             Peak 1                      Peak 2
 |               /\                          /\
 |  Threshold --/--\------------------------/--\----------- (1.85 m/s²)
 |             /    \                      /    \
 |            /      \                    /      \
 |-----------/--------\------------------/--------\-------- (Baseline)
 |                     \      /\        /
 |                      \____/  \______/
 +----------------------------------------------------------> เวลา (ms)
                      |<-- Refractory -->|
                      |   Period 280ms   |
```

* **Dynamic Threshold ($\ge 1.85 \text{ m/s}^2$)**: กรองการแกว่งเบาๆ หรือการเขย่ามือทั่วไป
* **Refractory Period ($280\text{ ms}$)**: สรีรวิทยาการเดินของมนุษย์ปกติ ไม่สามารถก้าวเร็วกว่า $3.5$ ก้าว/วินาที ($< 280\text{ ms}$) หากมียอดคลื่นสะท้อนซ้ำภายใน $280\text{ ms}$ ระบบจะตัดทิ้งทันทีเพื่อป้องกันการนับเบิ้ล

---

## Module 3: เวชศาสตร์การออกกำลังกายและชีวกลศาสตร์ในซอฟต์แวร์

### 3.1 รอบก้าวต่อนาที (Cadence) กับสุขภาพหัวใจและหลอดเลือด
* **Cadence $< 80\text{ SPM}$**: การเดินผ่อนคลาย (Light Physical Activity)
* **Cadence $80 - 99\text{ SPM}$**: การเดินระดับปานกลาง (Moderate Pace)
* **Cadence $100 - 119\text{ SPM}$**: **Brisk Walking (เดินเร็วเพื่อสุขภาพ)** — สมาคมโรคหัวใจอเมริกัน (AHA) แนะนำอย่างน้อย 150 นาที/สัปดาห์ เพื่อกระตุ้นการทำงานของกล้ามเนื้อหัวใจและระบบไหลเวียนโลหิต
* **Cadence $\ge 120\text{ SPM}$**: Aerobic / Jogging / Running Zone

### 3.2 การปรับความยาวก้าวเฉพาะบุคคล (Dynamic Stride Length)
สูตรคำนวณชีวกลศาสตร์อิงตามความสูงและเพศ:
* เพศชาย: $L_{\text{base}} = \text{Height (m)} \times 0.414$
* เพศหญิง: $L_{\text{base}} = \text{Height (m)} \times 0.413$
* **Dynamic Multiplier**: เมื่อวิ่ง ความยาวก้าวจะยืดออกประมาณ $1.25\times$

### 3.3 อัตราการเผาผลาญพลังงาน (BMR & TDEE)
* **Mifflin-St Jeor Equation**:
  * ชาย: $\text{BMR} = 10W + 6.25H - 5A + 5$
  * หญิง: $\text{BMR} = 10W + 6.25H - 5A - 161$
* **TDEE (Total Daily Energy Expenditure)**:
  $$\text{TDEE} = (\text{BMR} \times 1.2) + \text{Active Calories}$$

### 3.4 พฤติกรรมเนือยนิ่งและการแจ้งเตือน Active Break
การนั่งนิ่งต่อเนื่องเกิน 60 นาที ส่งผลเสียต่อการทำงานของอินซูลินและการสลายไขมันในหลอดเลือด แอปพลิเคชันมีระบบ Inactivity Timer เตือนให้ผู้ใช้ลุกขึ้นขยับร่างกายทันทีเมื่อครบ 60 นาที

---

## Module 4: การออกแบบ UI/UX สไตล์ Bento Grid และระบบ Responsive

### 4.1 สถาปัตยกรรม Bento Grid สไตล์ Sport Tech
จัดวางโมดูลข้อมูลสุขภาพแบบกล่อง Bento ขอบมน พื้นหลัง Frosted Glass (Glassmorphism) มีแสง Ambient Glow เรืองตามสภาวะการขยับร่างกาย (เขียว, ฟ้า, ส้ม)

### 4.2 ระบบ Responsive Breakpoints ปรับตัวตามขนาดหน้าจอ 100%
```dart
enum ResponsiveBreakpoint {
  compact, // สมาร์ทโฟนแนวตั้งทั่วไป (< 600dp) -> 1-Column Bento Grid
  medium,  // สมาร์ทโฟนจอพับ Foldables / แท็บเล็ตแนวตั้ง (600-840dp) -> 2-Column Bento Grid
  expanded // แท็บเล็ต / จอแนวนอน (> 840dp) -> 3-Column Studio Dashboard
}
```
* ใช้ `LayoutBuilder` ตรวจจับความกว้างจริง
* ใช้ `FittedBox(fit: BoxFit.scaleDown)` ป้องกันข้อความหรือตัวเลขก้าวเดินล้นหน้าจอ
* ใช้ `Expanded` และ `Flexible` กำหนดให้ทุก Row มีขอบเขตยืดหยุ่น ป้องกัน RenderFlex Overflow 100%

---

## Module 5: ปฏิบัติการทีละขั้นตอน (Step-by-Step Hands-on Labs)

### Lab 1: การติดตั้ง Environment และกำหนดสิทธิ์ Android
1. เพิ่ม Dependencies ใน `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     provider: ^6.1.2
     sensors_plus: ^6.1.1
     shared_preferences: ^2.3.2
     intl: ^0.19.0
   ```
2. กำหนดสิทธิ์ใน `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
   <uses-permission android:name="android.permission.BODY_SENSORS" />
   <uses-permission android:name="android.permission.HIGH_SAMPLING_RATE_SENSORS" />
   ```

### Lab 2: การพัฒนา MovementSensorService และ Peak Detection
สร้างคลาสบริการที่รับข้อมูลสตรีมเซนเซอร์และตรวจจับการก้าว:
```dart
void _processAccelerometerData(double x, double y, double z) {
  final double magnitude = math.sqrt(x * x + y * y + z * z);
  final int nowMs = DateTime.now().millisecondsSinceEpoch;

  if (magnitude > 1.85 && _lastMagnitude <= 1.85) {
    if (nowMs - _lastStepTimestampMs > 280) {
      _onStepDetected(nowMs, magnitude);
    }
  }
  _lastMagnitude = magnitude;
}
```

### Lab 3: การคำนวณ Cadence, Stride Length, BMR และ TDEE
เขียนฟังก์ชันคำนวณรอบก้าวจาก Sliding Window:
```dart
void _calculateCadence(int nowMs) {
  _recentStepTimestamps.removeWhere((ts) => nowMs - ts > 8000);
  if (_recentStepTimestamps.length >= 2) {
    final int dt = _recentStepTimestamps.last - _recentStepTimestamps.first;
    if (dt > 600) {
      final double minutes = dt / 60000.0;
      _cadenceSpm = ((_recentStepTimestamps.length - 1) / minutes).round().clamp(0, 240);
    }
  } else {
    _cadenceSpm = 0;
  }
}
```

### Lab 4: การสร้าง Bento Grid Dashboard และ Adaptive Breakpoints
สร้างโครงสร้างหน้าจอที่สลับคอลัมน์อัตโนมัติ:
```dart
ResponsiveLayoutBuilder(
  builder: (context, breakpoint, constraints) {
    if (breakpoint == ResponsiveBreakpoint.expanded) {
      return _build3ColumnStudio(sensor, metric);
    } else if (breakpoint == ResponsiveBreakpoint.medium) {
      return _build2ColumnGrid(sensor, metric);
    } else {
      return _build1ColumnStacked(sensor, metric);
    }
  },
)
```

### Lab 5: การทดสอบอัตโนมัติ และการ Deploy สู่สมาร์ทโฟนจริง
1. **การทดสอบความถูกต้องของโค้ด**:
   ```bash
   flutter analyze
   flutter test
   ```
2. **การติดตั้งลงสมาร์ทโฟนผ่าน ADB**:
   ```bash
   flutter build apk --debug
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   adb shell am start -n com.rbru.health.smart_health_tracker/.MainActivity
   ```

---

## Module 6: การประเมินผลและการต่อยอดเชิงวิจัยและนวัตกรรม

### 6.1 เกณฑ์การประเมินผลชิ้นงานผู้เข้ารับการอบรม (Rubrics)
| เกณฑ์การประเมิน | ดีเยี่ยม (5) | ดี (4) | พอใช้ (3) | ปรับปรุง (1-2) |
| :--- | :--- | :--- | :--- | :--- |
| **1. ความแม่นยำของการนับก้าว** | กรองสัญญาณรบกวนได้สมบูรณ์ ไม่นับเบิ้ล มี Refractory Period | นับก้าวได้ตรงเป็นส่วนใหญ่ มีสะดุดเล็กน้อย | นับก้าวได้แต่ยังไวต่อการสั่น | นับก้าวผิดพลาดอย่างเห็นได้ชัด |
| **2. ความถูกต้องทางสรีรวิทยา** | คำนวณ BMR, Stride, Cadence, TDEE ถูกต้องตามหลักการแพทย์ | คำนวณถูกต้อง 3 ใน 4 มิติ | มีการคำนวณแต่สูตรยังไม่สมบูรณ์ | ใช้ค่าคงที่ทั่วไป ไม่เฉพาะบุคคล |
| **3. Responsive & UI/UX** | ปรับหน้าจอ 1-3 คอลัมน์ได้สวยงาม ไร้ Overflow 100% | ปรับหน้าจอได้ มีช่องว่างไม่สม่ำเสมอเล็กน้อย | แสดงผลได้เฉพาะบางขนาดจอ | เกิดข้อผิดพลาด RenderFlex Overflow |
| **4. การติดตั้งและทดสอบ** | Build APK และติดตั้งลงสมาร์ทโฟนจริงสำเร็จ 100% | ติดตั้งลงเครื่องได้ แต่ต้องแก้ไขหลายครั้ง | รันได้เฉพาะบน Simulator | ไม่สามารถ Build หรือรันได้ |

### 6.2 ทิศทางการต่อยอดในอนาคต (Future Work)
1. **Edge AI & Machine Learning Classification**: การนำโมเดล TensorFlow Lite หรือ Scikit-Learn (เช่น Random Forest หรือ 1D-CNN) มาประมวลผลข้อมูลความเร่งแบบ Raw Accelerometer Time-Series เพื่อตรวจจับกิจกรรมที่ซับซ้อนขึ้น (เช่น การขึ้น-ลงบันได, ปั่นจักรยาน, พายเรือ)
2. **Photoplethysmography (PPG) Heart Rate Integration**: การใช้กล้องสมาร์ทโฟนร่วมกับไฟแฟลชตรวจจับการเต้นของหัวใจผ่านปลายนิ้ว เพื่อวิเคราะห์ความแปรปรวนของการเต้นของหัวใจ (Heart Rate Variability - HRV)
3. **Smart Wearable Bluetooth BLE Bridge**: การเชื่อมต่อข้อมูลกับนาฬิกา Smartwatch หรือสายรัดข้อมือเพื่อความแม่นยำระดับห้องวิจัยชีวกลศาสตร์

---

*เอกสารฉบับนี้พร้อมนำไปจัดพิมพ์เป็นรูปเล่มคู่มืออบรมเชิงปฏิบัติการ และใช้ประกอบการบรรยายได้ทันที*
