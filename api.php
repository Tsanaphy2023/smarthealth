<?php
/**
 * ChewaPulse xAI & SciRBRU Move+AI - REST API Backend (PHP + SQLite3)
 * รองรับ:
 * 1. ระบบซิงค์ก้าวเดินรายวันและรายชั่วโมง (24 ชั่วโมง)
 * 2. ระบบฐานข้อมูลกลาง OKR Key Result 3.2 คณะวิทยาศาสตร์และเทคโนโลยี มรภ.รำไพพรรณี
 *    (เป้าหมายก้าวสะสมรวมของบุคลากรในคณะ > 10,000,000 ก้าว ในปีงบประมาณ 2570 • บุคลากร > 60 คน)
 */

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$action = $_GET['action'] ?? 'summary';
if ($action !== 'okr_export_csv') {
    header('Content-Type: application/json; charset=utf-8');
}

$dbPath = __DIR__ . '/health_data.db';
try {
    $db = new PDO('sqlite:' . $dbPath);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

    // 1. ตาราง Telemetry เดิม + ตารางระบบฐานข้อมูลกลาง OKR Key Result 3.2 (บุคลากร 60+ คน)
    $db->exec("
        CREATE TABLE IF NOT EXISTS daily_telemetry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_date TEXT UNIQUE,
            steps INTEGER DEFAULT 0,
            step_goal INTEGER DEFAULT 10000,
            distance_km REAL DEFAULT 0.0,
            calories_kcal REAL DEFAULT 0.0,
            active_minutes INTEGER DEFAULT 0,
            cadence_spm INTEGER DEFAULT 0,
            current_activity TEXT DEFAULT 'stationary',
            motion_intensity REAL DEFAULT 0.0,
            hourly_json TEXT DEFAULT '{}',
            last_updated TEXT
        );

        CREATE TABLE IF NOT EXISTS health_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_type TEXT,
            details TEXT,
            timestamp TEXT
        );

        CREATE TABLE IF NOT EXISTS scirbru_staff (
            staff_id TEXT PRIMARY KEY,
            full_name TEXT NOT NULL,
            department TEXT NOT NULL,
            position_title TEXT DEFAULT 'อาจารย์/บุคลากร',
            app_edition TEXT DEFAULT 'SciRBRU Move+AI',
            daily_goal INTEGER DEFAULT 10000,
            created_at TEXT,
            updated_at TEXT
        );

        CREATE TABLE IF NOT EXISTS scirbru_daily_steps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            staff_id TEXT NOT NULL,
            record_date TEXT NOT NULL,
            fiscal_year INTEGER DEFAULT 2570,
            steps INTEGER DEFAULT 0,
            distance_km REAL DEFAULT 0.0,
            calories_kcal REAL DEFAULT 0.0,
            active_minutes INTEGER DEFAULT 0,
            hourly_json TEXT DEFAULT '{}',
            last_synced_at TEXT,
            UNIQUE(staff_id, record_date)
        );
    ");

    // ตรวจสอบว่ามีข้อมูลตั้งต้นของบุคลากรคณะวิทยาศาสตร์ฯ (> 60 คน) สำหรับปีงบประมาณ 2570 หรือยัง
    $staffCount = (int)$db->query("SELECT COUNT(*) FROM scirbru_staff")->fetchColumn();
    if ($staffCount < 60) {
        seedSciRbruFacultyStaff($db);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database initialization failed: ' . $e->getMessage()]);
    exit;
}

/**
 * สร้างฐานข้อมูลบุคลากรเริ่มต้นของคณะวิทยาศาสตร์และเทคโนโลยี มรภ.รำไพพรรณี จำนวน 64 คน (9 สาขาวิชา/หน่วยงาน)
 */
function seedSciRbruFacultyStaff(PDO $db): void {
    $now = date('c');
    $today = date('Y-m-d');
    $departments = [
        'สาขาวิชาฟิสิกส์',
        'สาขาวิชาวิทยาการคอมพิวเตอร์และเทคโนโลยีดิจิทัล',
        'สาขาวิชาเคมี',
        'สาขาวิชาชีววิทยา',
        'สาขาวิชาคณิตศาสตร์และสถิติ',
        'สาขาวิชาวิทยาศาสตร์สิ่งแวดล้อม',
        'สาขาวิชาเทคโนโลยีการเกษตร',
        'สาขาวิชาคหกรรมศาสตร์',
        'สำนักงานคณบดีคณะวิทยาศาสตร์และเทคโนโลยี'
    ];

    $staffSeed = [
        ['SCI-001', 'ผศ.ดร.ชีวะ ทัศนา', 'สาขาวิชาฟิสิกส์', 'ผู้ช่วยศาสตราจารย์', 'SciRBRU Move+AI', 124500],
        ['SCI-002', 'รศ.ดร.กิตติพงศ์ วงศ์สวัสดิ์', 'สาขาวิชาฟิสิกส์', 'รองศาสตราจารย์', 'ChewaPulse xAI', 98400],
        ['SCI-003', 'ผศ.ดร.นภัสสร ศรีสุวรรณ', 'สาขาวิชาวิทยาการคอมพิวเตอร์และเทคโนโลยีดิจิทัล', 'ผู้ช่วยศาสตราจารย์', 'SciRBRU Move+AI', 95200],
        ['SCI-004', 'ดร.ธนากร เจริญผล', 'สาขาวิชาวิทยาการคอมพิวเตอร์และเทคโนโลยีดิจิทัล', 'อาจารย์ ดร.', 'SciRBRU Move+AI', 91800],
        ['SCI-005', 'ผศ.ดร.ปิยะนุช วัฒนากูล', 'สาขาวิชาเคมี', 'ผู้ช่วยศาสตราจารย์', 'ChewaPulse xAI', 89500],
        ['SCI-006', 'ผศ.ดร.อภิชาติ รัตนโชติ', 'สาขาวิชาชีววิทยา', 'ผู้ช่วยศาสตราจารย์', 'SciRBRU Move+AI', 87600],
        ['SCI-007', 'ดร.ศิริพร ทองดี', 'สาขาวิชาคณิตศาสตร์และสถิติ', 'อาจารย์ ดร.', 'SciRBRU Move+AI', 85400],
        ['SCI-008', 'ผศ.ดร.วรพจน์ แสงจันทร์', 'สาขาวิชาเทคโนโลยีการเกษตร', 'ผู้ช่วยศาสตราจารย์', 'ChewaPulse xAI', 84100],
        ['SCI-009', 'ดร.กัญญาณัฐ บุญญฤทธิ์', 'สาขาวิชาวิทยาศาสตร์สิ่งแวดล้อม', 'อาจารย์ ดร.', 'SciRBRU Move+AI', 81900],
        ['SCI-010', 'ผศ.สุภาพร จันทร์เพ็ญ', 'สาขาวิชาคหกรรมศาสตร์', 'ผู้ช่วยศาสตราจารย์', 'SciRBRU Move+AI', 79600],
    ];

    $firstNames = [
        'กมล', 'เกรียงไกร', 'จักรกฤษณ์', 'ชุติมา', 'ณัฐวุฒิ', 'ดวงใจ', 'ถาวร', 'ทวีศักดิ์', 'ธนพล', 'นันทนา',
        'บุญส่ง', 'ประเสริฐ', 'พงศกร', 'พิชญา', 'ภัทรพล', 'มงคล', 'ยุพิน', 'รัตนา', 'ลักขณา', 'วิชัย',
        'ศุภชัย', 'สมชาย', 'สมศรี', 'สุรศักดิ์', 'อนันต์', 'อรอนงค์', 'อาคม', 'อิทธิพล', 'อุไรวรรณ', 'เอกชัย',
        'กนกวรรณ', 'ขวัญใจ', 'จินตนา', 'ชลธิชา', 'ณัฐกานต์', 'ดารณี', 'ทิพวรรณ', 'นฤมล', 'เบญจมาศ', 'ปวีณา',
        'ผกามาศ', 'พิมพ์ใจ', 'มยุรี', 'เยาวลักษณ์', 'รุ่งทิพย์', 'วรรณา', 'ศิริลักษณ์', 'สายชล', 'สุกัญญา', 'หทัยรัตน์',
        'อัจฉรา', 'อารยา', 'อินทิรา', 'เอมอร'
    ];
    $lastNames = [
        'จันทบุรีรักษ์', 'บูรพาภิรมย์', 'รำไพพัฒน์', 'ศรีเมืองจันท์', 'วัฒนธรรม', 'เจริญสุข', 'เกียรติขจร', 'พิทักษ์ผล', 'สว่างวงศ์', 'อุดมทรัพย์',
        'สายชลธาร', 'พงษ์พานิช', 'รัตนากร', 'วงศ์วิเศษ', 'สุวรรณโชติ', 'อินทร์จันทร์', 'ทองคำ', 'บุญประเสริฐ', 'ชัยมงคล', 'สุขสวัสดิ์'
    ];

    for ($i = 11; $i <= 64; $i++) {
        $code = sprintf('SCI-%03d', $i);
        $fn = $firstNames[($i - 11) % count($firstNames)];
        $ln = $lastNames[($i - 11) % count($lastNames)];
        $dept = $departments[($i - 1) % count($departments)];
        $pos = ($i % 9 === 0) ? 'นักวิทยาศาสตร์ชำนาญการ' : (($i % 8 === 0) ? 'เจ้าหน้าที่บริหารงานทั่วไป' : 'อาจารย์');
        $edition = ($i % 3 === 0) ? 'ChewaPulse xAI' : 'SciRBRU Move+AI';
        $cumSteps = 76000 - (($i - 11) * 650);
        if ($cumSteps < 38000) $cumSteps = 38500 + ($i * 120);
        $staffSeed[] = [$code, "อ.{$fn} {$ln}", $dept, $pos, $edition, $cumSteps];
    }

    $db->beginTransaction();
    $stmtStaff = $db->prepare("
        INSERT OR IGNORE INTO scirbru_staff (
            staff_id, full_name, department, position_title, app_edition, daily_goal, created_at, updated_at
        ) VALUES (
            :id, :name, :dept, :pos, :edition, 10000, :now, :now
        )
    ");

    $stmtSteps = $db->prepare("
        INSERT OR IGNORE INTO scirbru_daily_steps (
            staff_id, record_date, fiscal_year, steps, distance_km, calories_kcal, active_minutes, last_synced_at
        ) VALUES (
            :id, :rdate, 2570, :steps, :dist, :kcal, :active, :now
        )
    ");

    $baselineDate = '2026-10-15'; // ยอดสะสมต้นปีงบประมาณ 2570
    foreach ($staffSeed as $row) {
        [$id, $name, $dept, $pos, $ed, $totalSteps] = $row;
        $stmtStaff->execute([
            ':id' => $id,
            ':name' => $name,
            ':dept' => $dept,
            ':pos' => $pos,
            ':edition' => $ed,
            ':now' => $now
        ]);

        // บันทึกก้าวสะสมต้นปีงบประมาณ + ก้าววันนี้
        $todaySteps = 4200 + (crc32($id) % 5400);
        $priorSteps = max(0, $totalSteps - $todaySteps);

        $stmtSteps->execute([
            ':id' => $id,
            ':rdate' => $baselineDate,
            ':steps' => $priorSteps,
            ':dist' => round($priorSteps * 0.00072, 2),
            ':kcal' => round($priorSteps * 0.042, 1),
            ':active' => intval($priorSteps / 105),
            ':now' => $now
        ]);

        $stmtSteps->execute([
            ':id' => $id,
            ':rdate' => $today,
            ':steps' => $todaySteps,
            ':dist' => round($todaySteps * 0.00072, 2),
            ':kcal' => round($todaySteps * 0.042, 1),
            ':active' => intval($todaySteps / 105),
            ':now' => $now
        ]);
    }
    $db->commit();
}

/**
 * คำนวณสรุปข้อมูล OKR Key Result 3.2 (เป้าหมาย 10,000,000 ก้าว ปีงบประมาณ 2570)
 */
function buildOkrDashboardData(PDO $db, int $fiscalYear = 2570): array {
    $okrTarget = 10000000;
    $today = date('Y-m-d');

    $totals = $db->prepare("
        SELECT
            COALESCE(SUM(steps), 0) AS total_steps,
            COALESCE(SUM(distance_km), 0.0) AS total_distance_km,
            COALESCE(SUM(calories_kcal), 0.0) AS total_calories_kcal,
            COALESCE(SUM(active_minutes), 0) AS total_active_minutes
        FROM scirbru_daily_steps
        WHERE fiscal_year = :fy
    ");
    $totals->execute([':fy' => $fiscalYear]);
    $sumRow = $totals->fetch();

    $totalSteps = (int)($sumRow['total_steps'] ?? 0);
    $totalDist = round((float)($sumRow['total_distance_km'] ?? 0.0), 2);
    $totalKcal = round((float)($sumRow['total_calories_kcal'] ?? 0.0), 1);
    $totalActive = (int)($sumRow['total_active_minutes'] ?? 0);

    $totalStaff = (int)$db->query("SELECT COUNT(*) FROM scirbru_staff")->fetchColumn();

    $stmtTodayActive = $db->prepare("SELECT COUNT(DISTINCT staff_id) FROM scirbru_daily_steps WHERE record_date = :today AND steps > 0");
    $stmtTodayActive->execute([':today' => $today]);
    $activeTodayCount = (int)$stmtTodayActive->fetchColumn();

    // สรุปแยกตามสาขาวิชา / หน่วยงานในคณะวิทยาศาสตร์ฯ
    $stmtDepts = $db->prepare("
        SELECT
            s.department,
            COUNT(DISTINCT s.staff_id) AS staff_count,
            COALESCE(SUM(d.steps), 0) AS total_steps,
            COALESCE(SUM(d.distance_km), 0.0) AS total_distance_km,
            COALESCE(SUM(d.calories_kcal), 0.0) AS total_calories_kcal
        FROM scirbru_staff s
        LEFT JOIN scirbru_daily_steps d ON s.staff_id = d.staff_id AND d.fiscal_year = :fy
        GROUP BY s.department
        ORDER BY total_steps DESC
    ");
    $stmtDepts->execute([':fy' => $fiscalYear]);
    $deptRows = $stmtDepts->fetchAll();

    $departments = [];
    foreach ($deptRows as $r) {
        $dSteps = (int)$r['total_steps'];
        $dStaff = max(1, (int)$r['staff_count']);
        $departments[] = [
            'department' => $r['department'],
            'staff_count' => (int)$r['staff_count'],
            'total_steps' => $dSteps,
            'avg_steps_per_person' => (int)round($dSteps / $dStaff),
            'total_distance_km' => round((float)$r['total_distance_km'], 2),
            'total_calories_kcal' => round((float)$r['total_calories_kcal'], 1),
            'percent_of_faculty' => $totalSteps > 0 ? round(($dSteps / $totalSteps) * 100, 1) : 0.0
        ];
    }

    // ตารางจัดอันดับบุคลากร (Leaderboard)
    $stmtLeader = $db->prepare("
        SELECT
            s.staff_id,
            s.full_name,
            s.department,
            s.position_title,
            s.app_edition,
            s.daily_goal,
            COALESCE(SUM(d.steps), 0) AS total_steps,
            COALESCE(SUM(CASE WHEN d.record_date = :today THEN d.steps ELSE 0 END), 0) AS today_steps,
            COALESCE(SUM(d.distance_km), 0.0) AS total_distance_km,
            COALESCE(SUM(d.calories_kcal), 0.0) AS total_calories_kcal,
            MAX(d.last_synced_at) AS last_synced_at
        FROM scirbru_staff s
        LEFT JOIN scirbru_daily_steps d ON s.staff_id = d.staff_id AND d.fiscal_year = :fy
        GROUP BY s.staff_id
        ORDER BY total_steps DESC
    ");
    $stmtLeader->execute([':today' => $today, ':fy' => $fiscalYear]);
    $leaderRows = $stmtLeader->fetchAll();

    $leaderboard = [];
    $rank = 1;
    foreach ($leaderRows as $lr) {
        $leaderboard[] = [
            'rank' => $rank++,
            'staff_id' => $lr['staff_id'],
            'full_name' => $lr['full_name'],
            'department' => $lr['department'],
            'position_title' => $lr['position_title'],
            'app_edition' => $lr['app_edition'],
            'daily_goal' => (int)$lr['daily_goal'],
            'total_steps' => (int)$lr['total_steps'],
            'today_steps' => (int)$lr['today_steps'],
            'total_distance_km' => round((float)$lr['total_distance_km'], 2),
            'total_calories_kcal' => round((float)$lr['total_calories_kcal'], 1),
            'last_synced_at' => $lr['last_synced_at'] ?? date('c')
        ];
    }

    $progressPercent = round(min(100.0, ($totalSteps / $okrTarget) * 100.0), 2);
    $remainingSteps = max(0, $okrTarget - $totalSteps);

    return [
        'okr_code' => 'OKR Key Result 3.2',
        'okr_title' => 'ก้าวสะสมรวมของบุคลากรในคณะวิทยาศาสตร์และเทคโนโลยี มากกว่า 10 ล้านก้าว ในปีงบประมาณ 2570',
        'faculty_name' => 'คณะวิทยาศาสตร์และเทคโนโลยี มหาวิทยาลัยราชภัฏรำไพพรรณี',
        'fiscal_year' => $fiscalYear,
        'okr_target_steps' => $okrTarget,
        'total_faculty_steps' => $totalSteps,
        'remaining_steps' => $remainingSteps,
        'progress_percent' => $progressPercent,
        'is_okr_achieved' => $totalSteps >= $okrTarget,
        'total_staff_count' => $totalStaff,
        'active_today_count' => $activeTodayCount,
        'avg_steps_per_staff' => $totalStaff > 0 ? (int)round($totalSteps / $totalStaff) : 0,
        'total_distance_km' => $totalDist,
        'total_calories_kcal' => $totalKcal,
        'total_active_minutes' => $totalActive,
        'last_updated' => date('c'),
        'departments' => $departments,
        'leaderboard' => $leaderboard
    ];
}

$today = date('Y-m-d');

switch ($action) {
    case 'okr_dashboard':
        $fy = intval($_GET['fiscal_year'] ?? 2570);
        $data = buildOkrDashboardData($db, $fy);
        echo json_encode(['success' => true, 'data' => $data], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        break;

    case 'okr_sync':
        $raw = file_get_contents('php://input');
        $payload = json_decode($raw, true);
        if (!$payload) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Invalid JSON payload']);
            exit;
        }

        $staffId = trim(strval($payload['staff_id'] ?? 'SCI-001'));
        if ($staffId === '') $staffId = 'SCI-001';
        $fullName = trim(strval($payload['full_name'] ?? 'ผศ.ดร.ชีวะ ทัศนา'));
        $department = trim(strval($payload['department'] ?? 'สาขาวิชาฟิสิกส์'));
        $positionTitle = trim(strval($payload['position_title'] ?? 'อาจารย์/บุคลากร'));
        $appEdition = trim(strval($payload['app_edition'] ?? 'SciRBRU Move+AI'));
        $dailyGoal = intval($payload['daily_goal'] ?? 10000);
        $fiscalYear = intval($payload['fiscal_year'] ?? 2570);
        $recordDate = trim(strval($payload['record_date'] ?? $today));
        $steps = max(0, intval($payload['steps'] ?? 0));
        $distanceKm = max(0.0, floatval($payload['distance_km'] ?? round($steps * 0.00072, 2)));
        $caloriesKcal = max(0.0, floatval($payload['calories_kcal'] ?? round($steps * 0.042, 1)));
        $activeMinutes = max(0, intval($payload['active_minutes'] ?? intval($steps / 105)));
        $hourlyJson = is_array($payload['hourly'] ?? null) ? json_encode($payload['hourly']) : '{}';
        $nowStr = date('c');

        // 1. Upsert ข้อมูลบุคลากรในตาราง scirbru_staff
        $stmtUpsertStaff = $db->prepare("
            INSERT INTO scirbru_staff (
                staff_id, full_name, department, position_title, app_edition, daily_goal, created_at, updated_at
            ) VALUES (
                :id, :name, :dept, :pos, :edition, :goal, :now, :now
            )
            ON CONFLICT(staff_id) DO UPDATE SET
                full_name = :name,
                department = :dept,
                position_title = :pos,
                app_edition = :edition,
                daily_goal = :goal,
                updated_at = :now
        ");
        $stmtUpsertStaff->execute([
            ':id' => $staffId,
            ':name' => $fullName,
            ':dept' => $department,
            ':pos' => $positionTitle,
            ':edition' => $appEdition,
            ':goal' => $dailyGoal,
            ':now' => $nowStr
        ]);

        // 2. Upsert ยอดก้าวเดินของวันนี้ (ป้องกันการบวกซ้ำด้วย UNIQUE(staff_id, record_date))
        $stmtUpsertSteps = $db->prepare("
            INSERT INTO scirbru_daily_steps (
                staff_id, record_date, fiscal_year, steps, distance_km, calories_kcal, active_minutes, hourly_json, last_synced_at
            ) VALUES (
                :id, :rdate, :fy, :steps, :dist, :kcal, :active, :hourly, :now
            )
            ON CONFLICT(staff_id, record_date) DO UPDATE SET
                steps = MAX(scirbru_daily_steps.steps, :steps),
                distance_km = MAX(scirbru_daily_steps.distance_km, :dist),
                calories_kcal = MAX(scirbru_daily_steps.calories_kcal, :kcal),
                active_minutes = MAX(scirbru_daily_steps.active_minutes, :active),
                hourly_json = :hourly,
                last_synced_at = :now
        ");
        $stmtUpsertSteps->execute([
            ':id' => $staffId,
            ':rdate' => $recordDate,
            ':fy' => $fiscalYear,
            ':steps' => $steps,
            ':dist' => $distanceKm,
            ':kcal' => $caloriesKcal,
            ':active' => $activeMinutes,
            ':hourly' => $hourlyJson,
            ':now' => $nowStr
        ]);

        $dashboard = buildOkrDashboardData($db, $fiscalYear);
        echo json_encode([
            'success' => true,
            'message' => 'ซิงค์ข้อมูลก้าวเดินเข้าฐานข้อมูล OKR Key Result 3.2 สำเร็จ',
            'synced_staff_id' => $staffId,
            'synced_steps_today' => $steps,
            'data' => $dashboard
        ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        break;

    case 'okr_export_csv':
        $fy = intval($_GET['fiscal_year'] ?? 2570);
        $dashboard = buildOkrDashboardData($db, $fy);

        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="OKR_KR3_2_SciRBRU_FY' . $fy . '_Steps_Report.csv"');

        $out = fopen('php://output', 'w');
        // Write UTF-8 BOM for Microsoft Excel Thai font compatibility
        fwrite($out, "\xEF\xBB\xBF");

        fputcsv($out, ['รายงานผลการดำเนินงาน OKR Key Result 3.2 คณะวิทยาศาสตร์และเทคโนโลยี มหาวิทยาลัยราชภัฏรำไพพรรณี']);
        fputcsv($out, ['ตัวชี้วัด', $dashboard['okr_title']]);
        fputcsv($out, ['ปีงบประมาณ', $fy, 'เป้าหมายรวม (ก้าว)', number_format($dashboard['okr_target_steps']), 'ก้าวสะสมรวมปัจจุบัน', number_format($dashboard['total_faculty_steps']), 'ความก้าวหน้า (%)', $dashboard['progress_percent'] . '%']);
        fputcsv($out, ['จำนวนบุคลากรที่เข้าร่วม (คน)', $dashboard['total_staff_count'], 'วันที่ออกรายงาน', date('Y-m-d H:i:s')]);
        fputcsv($out, []);

        fputcsv($out, ['อันดับ', 'รหัสบุคลากร', 'ชื่อ-นามสกุล', 'สาขาวิชา/หน่วยงาน', 'ตำแหน่ง', 'แอปที่ใช้', 'ก้าวสะสมรวมปีงบ 2570', 'ก้าววันนี้', 'ระยะทางสะสม (กม.)', 'พลังงานสะสม (kcal)', 'เวลาซิงค์ล่าสุด']);
        foreach ($dashboard['leaderboard'] as $row) {
            fputcsv($out, [
                $row['rank'],
                $row['staff_id'],
                $row['full_name'],
                $row['department'],
                $row['position_title'],
                $row['app_edition'],
                $row['total_steps'],
                $row['today_steps'],
                $row['total_distance_km'],
                $row['total_calories_kcal'],
                $row['last_synced_at']
            ]);
        }
        fclose($out);
        exit;

    case 'summary':
        $stmt = $db->prepare("SELECT * FROM daily_telemetry WHERE record_date = :date");
        $stmt->execute([':date' => $today]);
        $record = $stmt->fetch();

        if (!$record) {
            $record = [
                'record_date' => $today,
                'steps' => 0,
                'step_goal' => 10000,
                'distance_km' => 0.0,
                'calories_kcal' => 0.0,
                'active_minutes' => 0,
                'cadence_spm' => 0,
                'current_activity' => 'stationary',
                'motion_intensity' => 0.0,
                'hourly_json' => '{}',
                'last_updated' => date('c')
            ];
        }

        $record['hourly'] = json_decode($record['hourly_json'] ?? '{}', true) ?: [];
        echo json_encode(['success' => true, 'data' => $record], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        break;

    case 'sync':
        $raw = file_get_contents('php://input');
        $payload = json_decode($raw, true);

        if (!$payload) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Invalid JSON payload']);
            exit;
        }

        $steps = intval($payload['steps'] ?? 0);
        $stepGoal = intval($payload['step_goal'] ?? 10000);
        $distanceKm = floatval($payload['distance_km'] ?? 0.0);
        $caloriesKcal = floatval($payload['calories_kcal'] ?? 0.0);
        $activeMinutes = intval($payload['active_minutes'] ?? 0);
        $cadenceSpm = intval($payload['cadence_spm'] ?? 0);
        $activity = strval($payload['current_activity'] ?? 'walking');
        $intensity = floatval($payload['motion_intensity'] ?? 0.0);
        $hourlyJson = is_array($payload['hourly'] ?? null) ? json_encode($payload['hourly']) : '{}';
        $nowStr = date('c');

        $stmt = $db->prepare("
            INSERT INTO daily_telemetry (
                record_date, steps, step_goal, distance_km, calories_kcal,
                active_minutes, cadence_spm, current_activity, motion_intensity,
                hourly_json, last_updated
            ) VALUES (
                :date, :steps, :goal, :distance, :calories,
                :active, :cadence, :activity, :intensity,
                :hourly, :updated
            )
            ON CONFLICT(record_date) DO UPDATE SET
                steps = :steps,
                step_goal = :goal,
                distance_km = :distance,
                calories_kcal = :calories,
                active_minutes = :active,
                cadence_spm = :cadence,
                current_activity = :activity,
                motion_intensity = :intensity,
                hourly_json = :hourly,
                last_updated = :updated
        ");

        $stmt->execute([
            ':date' => $today,
            ':steps' => $steps,
            ':goal' => $stepGoal,
            ':distance' => $distanceKm,
            ':calories' => $caloriesKcal,
            ':active' => $activeMinutes,
            ':cadence' => $cadenceSpm,
            ':activity' => $activity,
            ':intensity' => $intensity,
            ':hourly' => $hourlyJson,
            ':updated' => $nowStr
        ]);

        echo json_encode([
            'success' => true,
            'message' => 'Telemetry synchronized successfully',
            'record_date' => $today,
            'steps' => $steps
        ]);
        break;

    case 'history':
        $stmt = $db->query("SELECT record_date, steps, step_goal, distance_km, calories_kcal, active_minutes FROM daily_telemetry ORDER BY record_date DESC LIMIT 7");
        $history = $stmt->fetchAll();
        echo json_encode(['success' => true, 'history' => array_reverse($history)]);
        break;

    case 'reset':
        $stmt = $db->prepare("
            UPDATE daily_telemetry SET
                steps = 0,
                distance_km = 0,
                calories_kcal = 0,
                active_minutes = 0,
                cadence_spm = 0,
                current_activity = 'stationary',
                motion_intensity = 0,
                hourly_json = '{}',
                last_updated = :updated
            WHERE record_date = :date
        ");
        $stmt->execute([':date' => $today, ':updated' => date('c')]);
        echo json_encode(['success' => true, 'message' => 'Reset data for today to 0']);
        break;

    default:
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => 'Unknown action: ' . $action]);
        break;
}
