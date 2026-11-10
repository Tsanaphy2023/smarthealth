<?php
/**
 * Smart Health Tracker - REST API Backend (PHP + SQLite3)
 * Provides real-time synchronization, telemetry ingest, and health statistics.
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$dbPath = __DIR__ . '/health_data.db';
try {
    $db = new PDO('sqlite:' . $dbPath);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

    // Initialise tables if not exists
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
    ");
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database initialization failed: ' . $e->getMessage()]);
    exit;
}

$action = $_GET['action'] ?? 'summary';
$today = date('Y-m-d');

switch ($action) {
    case 'summary':
        $stmt = $db->prepare("SELECT * FROM daily_telemetry WHERE record_date = :date");
        $stmt->execute([':date' => $today]);
        $record = $stmt->fetch();

        if (!$record) {
            // Default empty day
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
