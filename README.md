# ChewaPulse xAI & SciRBRU Move+AI (v2.0) — ระบบนิเวศแอปพลิเคชันสุขภาพอัจฉริยะ นับก้าวอัตโนมัติ 24 ชั่วโมง และฐานข้อมูลกลาง OKR Key Result 3.2 (เป้าหมาย 10 ล้านก้าว)

<p align="center">
  <img src="latex_manual/figures/app_icon_chewapulse.png" alt="ChewaPulse xAI 3D Pixar App Icon" width="145" style="border-radius: 32px; margin-right: 12px;" />
  <img src="latex_manual/figures/app_icon_scirbru.png" alt="SciRBRU Move+AI 3D Pixar App Icon" width="145" style="border-radius: 32px; margin-right: 16px;" />
  <img src="latex_manual/figures/cover_front_smart_health.png" alt="ChewaPulse xAI & SciRBRU Move+AI Manual Cover" width="360" />
</p>

**ผู้ออกแบบและพัฒนา:** ผู้ช่วยศาสตราจารย์ ดร.ชีวะ ทัศนา (สาขาวิชาฟิสิกส์ คณะวิทยาศาสตร์และเทคโนโลยี มหาวิทยาลัยราชภัฏรำไพพรรณี)  
**ตำราและคู่มือปฏิบัติการฉบับสมบูรณ์ (54 หน้า • รุ่นปรับปรุง v2.0):** [`latex_manual/main.pdf`](latex_manual/main.pdf)

---

## 📲 ดาวน์โหลดติดตั้งทั้ง 2 แอปพลิเคชันอิสระ & รันผ่าน Web App (Downloads & Live Web Apps)

| แอปพลิเคชัน / แพลตฟอร์ม | ลิงก์ดาวน์โหลด / เข้าใช้งาน (Direct Link) | รายละเอียดการใช้งาน |
| :--- | :--- | :--- |
| 💚 **App 1: `ChewaPulse xAI` (Android .APK)** | [**ดาวน์โหลด `ChewaPulse-xAI-Android-v2.0.apk`**](downloads/ChewaPulse-xAI-Android-v2.0.apk) | แอปวิเคราะห์สัญญาณชีพจรการก้าวเดิน & ชีวกลศาสตร์เอ็กซ์เอไอ (`com.rbru.health.smart_health_tracker`) |
| 💛 **App 2: `SciRBRU Move+AI` (Android .APK)** | [**ดาวน์โหลด `SciRBRU-MovePlusAI-Android-v2.0.apk`**](downloads/SciRBRU-MovePlusAI-Android-v2.0.apk) | แอปขับเคลื่อนภารกิจก้าวเดินสะสม คณะวิทยาศาสตร์และเทคโนโลยี มรภ.รำไพพรรณี (`com.scirbru.move.ai`) |
| 🌐 **Web App 1: `ChewaPulse xAI` (PWA)** | [**เปิดแอป `ChewaPulse xAI` บนเบราว์เซอร์**](https://tsanaphy2023.github.io/smarthealth/app/) | รันตัวแอป `ChewaPulse xAI` ผ่านเว็บได้ทันที (รองรับ Android/iOS/Desktop) |
| 🌐 **Web App 2: `SciRBRU Move+AI` (PWA)** | [**เปิดแอป `SciRBRU Move+AI` บนเบราว์เซอร์**](https://tsanaphy2023.github.io/smarthealth/scirbru_app/) | รันตัวแอป `SciRBRU Move+AI` ผ่านเว็บได้ทันที (รองรับ Android/iOS/Desktop) |
| 🛰️ **OKR 3.2 & Satellite GPS Web Dashboard** | [**เปิดแดชบอร์ดกลาง OKR 3.2 (10 ล้านก้าว) & แผนที่ดาวเทียม**](https://tsanaphy2023.github.io/smarthealth/) | แดชบอร์ดติดตามเป้าหมาย 10,000,000 ก้าว บุคลากร 64+ คน 9 สาขาวิชา พร้อมส่งออก CSV |
| 📘 **ตำราและคู่มือปฏิบัติการ (PDF • 54 หน้า)** | [**ดาวน์โหลด `latex_manual/main.pdf` (54 หน้า)**](latex_manual/main.pdf) | ตำราและคู่มือปฏิบัติการ 5 บท 12 ปฏิบัติการ พร้อมปก 3D Pixar |

---

## 🌟 คุณสมบัติเด่นรุ่น 2.0 (Key Features in v2.0)

1. **สถาปัตยกรรม 2 แอปพลิเคชันอิสระ (Dual Standalone Applications)**:
   - **`ChewaPulse xAI` (`smart_health_tracker`)**: โทนสีเขียวมรกตไซเบอร์ (`#00E676`) และฟ้านีออน (`#00E5FF`) เน้นการวิเคราะห์สัญญาณชีพจรการก้าวเดิน สรีรวิทยาการเผาผลาญพลังงาน และ Deep Neural Network บนอุปกรณ์
   - **`SciRBRU Move+AI` (`scirbru_move_ai`)**: โทนสีทองราชภัฏ (`#FFD54F`) ฟ้าคราม (`#38BDF8`) และชมพูราชภัฏ (`#F43F5E`) เน้นการขับเคลื่อนภารกิจก้าวสะสมรวมของบุคลากรคณะวิทยาศาสตร์และเทคโนโลยี มรภ.รำไพพรรณี
2. **ระบบนับก้าวอัตโนมัติตามเวลาที่กำหนด และทำงานเบื้องหลังตลอด 24 ชั่วโมง (`StepForegroundService.kt`)**:
   - บริการ Native Android Foreground Service (`START_STICKY`) ที่เชื่อมต่อกับชิป `TYPE_STEP_COUNTER` และ `TYPE_ACCELEROMETER` โดยตรง และเขียนข้อมูลลง `FlutterSharedPreferences` ทันทีแม้แอปพลิเคชันจะถูกปัดปิดหรือล็อกหน้าจอ
   - ผู้ใช้งานสามารถตั้งเวลาเริ่มนับและหยุดนับก้าวอัตโนมัติได้เอง (เช่น `06:00` – `22:00` น.) หรือเลือกโหมดทำงานต่อเนื่อง 24 ชั่วโมงผ่านการ์ด `AutoScheduleControlCard` ร่วมกับ `AutoStepBroadcastReceiver` (`AlarmManager`)
3. **ระบบฐานข้อมูลกลางและแดชบอร์ด OKR Key Result 3.2 (เป้าหมาย 10,000,000 ก้าว ปีงบประมาณ 2570)**:
   - รองรับบุคลากรสายวิชาการและสายสนับสนุนมากกว่า **64 คน ครบทั้ง 9 สาขาวิชา/หน่วยงาน** ของคณะวิทยาศาสตร์และเทคโนโลยี มหาวิทยาลัยราชภัฏรำไพพรรณี
   - ป้องกันข้อมูลซ้ำซ้อนด้วย `UNIQUE(staff_id, record_date)` แบบ Idempotent Upsert พร้อมจัดอันดับ 9 สาขาวิชา ทำเนียบผู้นำก้าวเดิน (Leaderboard) และปุ่มส่งออกไฟล์รายงาน **CSV (UTF-8 BOM)** สำหรับงานแผนและประกันคุณภาพการศึกษา
4. **ระบบนำทาง 4 แท็บไร้ปัญหาหน้าจอล้น (4-Tab Modern Responsive Navigation)**:
   - **แท็บ 1 วันนี้**: วงแหวนก้าวเดิน, โหมดกิจกรรมด่วน (เดิน / วิ่ง / ปั่นจักรยาน), การ์ดตั้งเวลานับก้าวอัตโนมัติ 24 ชม., การ์ดสรีรวิทยา Bento Grid และการ์ดเตือนเนือยนิ่ง 30 นาทีพร้อมเสียงพูดภาษาไทย *"ลุกคะ ลุกค่ะ"*
   - **แท็บ 2 แผนที่ดาวเทียม**: แผนที่เส้นทางจริงแบบเวกเตอร์และภาพถ่ายดาวเทียม ESRI World Imagery Satellite
   - **แท็บ 3 สถิติ 7 วัน & AI**: กราฟเปรียบเทียบก้าวเดินย้อนหลัง 7 วัน (`WeeklyHistoryCard`), แดชบอร์ดฐานข้อมูลกลาง OKR 3.2 (`OkrFacultyDashboardCard`), และโครงข่ายประสาทเทียมเชิงลึก (`DeepAiAnalyticsCard`)
   - **แท็บ 4 โปรไฟล์**: ข้อมูลสรีรวิทยาส่วนบุคคล (BMI / BMR), ทดสอบเสียงแจ้งเตือนภาษาไทย และซิงก์ข้อมูลคลาวด์

---

## 📁 โครงสร้างโปรเจกต์ (Project Structure)

```text
smart_health_tracker/ (และ scirbru_move_ai/)
├── android/app/src/main/kotlin/.../
│   ├── MainActivity.kt                         # MethodChannel เชื่อมต่อ Native Background Service
│   ├── StepForegroundService.kt                # บริการเบื้องหลังนับก้าวต่อเนื่อง 24 ชม. แม้ปิดแอป
│   └── AutoStepBroadcastReceiver.kt            # ตัวรับสัญญาณ AlarmManager & Boot Completed
├── lib/
│   ├── main.dart                               # Entrypoint & การตั้งค่า MultiProvider
│   ├── models/
│   │   ├── app_brand_config.dart               # โมเดลสลับอัตลักษณ์ ChewaPulse xAI / SciRBRU Move+AI
│   │   ├── okr_faculty_model.dart              # โมเดลฐานข้อมูลบุคลากร 64 คน 9 สาขาวิชา สำหรับ OKR 3.2
│   │   ├── activity_type.dart                  # ประเภทการเคลื่อนไหว (เดิน, วิ่ง, ปั่นจักรยาน) และค่า MET
│   │   └── daily_health_metric.dart            # โมเดลข้อมูลก้าว, แคลอรี, ระยะทาง, สถิติรายชั่วโมง
│   ├── services/
│   │   ├── movement_sensor_service.dart        # ตรวจจับความเร่ง 50Hz, ตั้งเวลาอัตโนมัติ 24 ชม., นับก้าวไฮบริด
│   │   ├── okr_sync_service.dart               # ซิงโครไนซ์ก้าวเดินเข้าสู่ฐานข้อมูลกลาง OKR 3.2 อัตโนมัติ
│   │   ├── gps_tracking_service.dart           # ติดตามพิกัดดาวเทียม 3 โหมดกิจกรรม (เดิน/วิ่ง/ปั่นจักรยาน)
│   │   ├── voice_alert_service.dart            # ระบบเสียงสังเคราะห์ภาษาไทย "ลุกคะ ลุกค่ะ" ทุก 30 นาที
│   │   └── health_storage_service.dart         # บันทึกประวัติก้าวรายวันและย้อนหลัง 7 วันลง SharedPreferences
│   └── ui/
│       ├── screens/
│       │   └── home_tracker_screen.dart        # หน้าหลักระบบนำทาง 4 แท็บ (Today, Map, 7-Day & OKR, Profile)
│       └── widgets/
│           ├── auto_schedule_control_card.dart # การ์ดตั้งเวลาเริ่ม-หยุดนับก้าวอัตโนมัติ & บริการ 24 ชม.
│           ├── okr_faculty_dashboard_card.dart # การ์ดฐานข้อมูลกลาง OKR 3.2 เป้าหมาย 10 ล้านก้าว
│           ├── weekly_history_card.dart        # กราฟแนวโน้มสุขภาพย้อนหลัง 7 วัน
│           ├── gps_route_map_card.dart         # แผนที่เส้นทางเดิน-วิ่ง-ปั่นจักรยานแบบเวกเตอร์
│           └── deep_ai_analytics_card.dart     # การ์ดวิเคราะห์ความล้าด้วยโครงข่ายประสาทเทียมเชิงลึก
├── api.php                                     # REST API & SQLite3 (scirbru_staff, scirbru_daily_steps, CSV Export)
├── index.html                                  # เว็บแดชบอร์ดแผนที่ภาพถ่ายดาวเทียม & ระบบรายงานผล OKR 3.2
└── latex_manual/
    └── main.pdf                                # ตำราและคู่มือปฏิบัติการฉบับสมบูรณ์ (54 หน้า)
```

---

## 🚀 วิธีการทดสอบและรันแอปพลิเคชัน

```bash
# 1. รันแอป ChewaPulse xAI
cd /Applications/XAMPP/xamppfiles/htdocs/smart_health_tracker
flutter pub get
flutter test
flutter run

# 2. รันแอป SciRBRU Move+AI
cd /Applications/XAMPP/xamppfiles/htdocs/scirbru_move_ai
flutter pub get
flutter test
flutter run
```
