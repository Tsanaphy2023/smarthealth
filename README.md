# smarthealth — Smart Health Step & Movement Tracker (แอปพลิเคชันสุขภาพ นับก้าวและวิเคราะห์การขยับร่างกาย)

<p align="center">
  <img src="assets/icons/app_icon.png" alt="Smart Health 3D Pixar App Icon" width="180" style="border-radius: 36px; margin-right: 16px;" />
  <img src="latex_manual/figures/cover_front_smart_health.png" alt="Smart Health Tracker Manual Cover" width="380" />
</p>

**ผู้ออกแบบและพัฒนา:** ผู้ช่วยศาสตราจารย์ ดร.ชีวะ ทัศนา (สาขาวิชาฟิสิกส์ คณะวิทยาศาสตร์และเทคโนโลยี มหาวิทยาลัยราชภัฏรำไพพรรณี)  
**เอกสารคู่มือวิชาการและปฏิบัติการ (50 หน้า):** [`latex_manual/main.pdf`](latex_manual/main.pdf)

---

## 📲 ดาวน์โหลดติดตั้งแอปพลิเคชัน & รันผ่าน Web App (Downloads & Live Web App)

| แพลตฟอร์ม (Platform) | ลิงก์ดาวน์โหลด / เข้าใช้งาน (Direct Link) | รายละเอียดการติดตั้ง |
| :--- | :--- | :--- |
| 🌐 **GitHub Web App (Satellite Dashboard)** | [**เปิดใช้งานแดชบอร์ดพิกัดดาวเทียม GPS**](https://tsanaphy2023.github.io/smarthealth/) | แดชบอร์ดติดตามก้าวเดิน วิ่ง ปั่นจักรยาน และแผนที่ภาพถ่ายดาวเทียม |
| 📱 **Flutter Mobile Web App (PWA)** | [**เปิดแอปสมาร์ทโฟนบนเว็บ (Flutter Web)**](https://tsanaphy2023.github.io/smarthealth/app/) | รันตัวแอปมือถือผ่านเบราว์เซอร์ได้ทันที (รองรับติดตั้งเป็นไอคอนบน iOS/Android) |
| 🤖 **Android (.APK • 17 MB)** | [**ดาวน์โหลด `SmartHealthTracker-Android-v1.0.apk`**](downloads/SmartHealthTracker-Android-v1.0.apk) | สำหรับสมาร์ทโฟน Android (ARM64) ดาวน์โหลดและกดติดตั้งได้ทันที |
| 🍎 **iOS (.IPA • 7.3 MB & Safari Web App)** | [**ดาวน์โหลด `SmartHealthTracker-iOS-v1.0.ipa`**](downloads/SmartHealthTracker-iOS-v1.0.ipa) | ติดตั้งผ่าน Sideloadly / AltStore หรือเปิดลิงก์ Web App บน Safari แล้วกด *Share → Add to Home Screen* |
| 📘 **คู่มือวิชาการและปฏิบัติการ (PDF)** | [**ดาวน์โหลด `latex_manual/main.pdf` (50 หน้า)**](latex_manual/main.pdf) | ตำราและคู่มือปฏิบัติการฉบับสมบูรณ์พร้อมปก 3D Pixar |

---

แอปพลิเคชันสมาร์ทโฟนสำหรับการตรวจนับก้าว (**Hybrid Step Counting**) และวิเคราะห์การขยับร่างกาย (**Physical Movement, Fall Detection & Satellite Multi-Sport GPS Tracking**) แบบเรียลไทม์ พร้อมการคำนวณชีวสถิติ (แคลอรี, ระยะทาง, เวลาที่มีการเคลื่อนไหว) และวงแหวนแสดงเป้าหมายสุขภาพประจำวัน

พัฒนาด้วย **Flutter (Dart) + Hardware Pedometer + Sensors Plus + Physics-Informed Step Peak Detection Algorithm + Leaflet.js Satellite GPS & SQLite REST API**

---

## 🌟 คุณสมบัติเด่น (Key Features)

1. **ระบบนับก้าวแบบไฮบริด (Hybrid Step Counter - Hardware Pedometer + Physics-Informed Accelerometer)**:
   - ตรวจจับผ่าน **Hardware Step Counter Sensor** เพื่อการประหยัดพลังงานแบตเตอรี่สูงสุดขณะปิดหน้าจอ
   - พร้อมระบบสำรองและวัดแรงขยับสดด้วยเซ็นเซอร์ความเร่ง 3 แกน ($X, Y, Z$) หักล้างแรงโน้มถ่วง ด้วยอัลกอริทึม **Dynamic Peak Detection with Refractory Window**
2. **ระบบตรวจจับแรงกระแทกและการล้มฉับพลัน (Fall & Severe Impact Detection)**:
   - ตรวจจับความเร่งลัพธ์ฉับพลันที่เกินเกณฑ์ปลอดภัย (>32 $m/s^2$) พร้อมการสั่นเตือนและส่งสัญญาณเสียงเตือนความปลอดภัย
3. **เกจวัดแรงขยับร่างกายสด (Real-Time Motion Intensity Gauge)**:
   - แสดงระดับความเข้มข้นของการเคลื่อนไหวร่างกายแบบเรียลไทม์ (0% - 100%) พร้อมแสดงสถานะเซ็นเซอร์ Live
4. **เว็บแดชบอร์ด & REST API เชื่อมต่อคลาวด์ (Web Dashboard & SQLite Telemetry API)**:
   - เข้าดูแดชบอร์ดได้ทันทีผ่านเบราว์เซอร์ที่ `http://localhost/smart_health_tracker/` (ไฟล์ `index.html`)
   - รองรับการเชื่อมต่อ REST API ที่ `api.php` พร้อมฐานข้อมูล SQLite บันทึกสถิติก้าวเดินรายวันและ 24 ชั่วโมง
3. **การจำแนกประเภทกิจกรรม (Activity Classification)**:
   - 🧘‍♂️ **อยู่นิ่ง / พักผ่อน (Stationary)**
   - 🚶‍♂️ **กำลังเดิน (Walking)**
   - 🏃‍♂️ **กำลังวิ่ง (Running)**
   - 🏋️‍♂️ **ขยับร่างกายต่อเนื่อง (Active Motion)**
4. **การ์ดสรุปชีวสถิติ 3 มิติ**:
   - 🔥 **แคลอรีที่เผาผลาญ (kcal)**
   - 📍 **ระยะทางเดิน/วิ่ง (กม.)**
   - ⏱️ **เวลาที่ร่างกายขยับต่อเนื่อง (นาที)**
5. **วงแหวนความคืบหน้า (Activity Progress Ring)**:
   - วงแหวนนีออนมรกตแสดงเปอร์เซ็นต์ความคืบหน้าเทียบกับเป้าหมายประจำวัน (เช่น 6,540 / 10,000 ก้าว = 65%)
6. **แผนภูมิแท่งกิจกรรม 24 ชั่วโมง**:
   - บันทึกและแสดงสถิติก้าวเดินในแต่ละช่วงเวลาของวันตั้งแต่ 00:00 - 23:00 น.
7. **ระบบตั้งค่าเป้าหมายและโหมดจำลองเดิน**:
   - ปรับตั้งเป้าหมายก้าวต่อวันได้อิสระ (6,000, 8,000, 10,000, 12,000, 15,000 ก้าว)
   - มีปุ่มจำลองการเดินต่อเนื่อง (Live Simulation) และปุ่ม +1 ก้าวสำหรับการทดสอบและสาธิต

---

## 📁 โครงสร้างโปรเจกต์ (Project Structure)

```text
smart_health_tracker/
├── lib/
│   ├── main.dart                               # Entrypoint & การตั้งค่า MultiProvider
│   ├── models/
│   │   ├── activity_type.dart                  # ประเภทการเคลื่อนไหว (เดิน, วิ่ง, อยู่นิ่ง) และค่า MET
│   │   └── daily_health_metric.dart            # โมเดลข้อมูลก้าว, แคลอรี, ระยะทาง, สถิติรายชั่วโมง
│   ├── services/
│   │   ├── movement_sensor_service.dart        # ตรวจจับความเร่ง Accelerometer, อัลกอริทึมนับก้าว
│   │   └── health_storage_service.dart         # บันทึกประวัติก้าวประจำวันลง SharedPreferences
│   └── ui/
│       ├── theme/
│       │   └── health_theme.dart               # ธีม Energetic Dark Sport UI
│       ├── widgets/
│       │   ├── activity_ring_progress.dart     # วงแหวนความคืบหน้าและตัวเลขนับก้าวขนาดใหญ่
│       │   ├── live_motion_gauge.dart          # เกจวัดระดับความแรงของการขยับตัวสด
│       │   ├── metric_stat_cards.dart          # การ์ดแสดงผล แคลอรี, ระยะทาง, เวลาแอคทีฟ
│       │   ├── hourly_activity_chart.dart      # แผนภูมิแท่งสถิติตลอด 24 ชั่วโมง
│       │   └── goal_setting_dialog.dart        # ไดอะล็อกปรับตั้งเป้าหมายประจำวัน
│       └── screens/
│           └── home_tracker_screen.dart        # หน้าหลักติดตามสุขภาพสด
└── test/
    ├── step_detection_algorithm_test.dart      # Unit test สำหรับการคำนวณและจำแนกกิจกรรม
    └── widget_test.dart                        # Smoke test สำหรับแอปพลิเคชัน
```

---

## 🚀 วิธีการทดสอบและรันแอปพลิเคชัน

### 1. ติดตั้ง Dependencies
```bash
cd smart_health_tracker
flutter pub get
```

### 2. รันแอปพลิเคชันบนสมาร์ทโฟน
```bash
flutter run
```

### 3. รัน Unit Tests
```bash
flutter test
```
