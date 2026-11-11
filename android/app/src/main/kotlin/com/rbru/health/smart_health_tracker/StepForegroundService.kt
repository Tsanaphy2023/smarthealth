package com.rbru.health.smart_health_tracker

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import java.util.Calendar
import kotlin.math.abs
import kotlin.math.sqrt

class StepForegroundService : Service(), SensorEventListener {

    companion object {
        const val CHANNEL_ID = "smart_health_24h_step_channel"
        const val NOTIFICATION_ID = 2027
        const val ACTION_SYNC_CONFIG = "com.rbru.health.smart_health_tracker.ACTION_SYNC_CONFIG"
        const val ACTION_RESET_STEPS = "com.rbru.health.smart_health_tracker.ACTION_RESET_STEPS"
        private const val PREFS_NAME = "FlutterSharedPreferences"

        @Volatile
        var isRunning = false
    }

    private var sensorManager: SensorManager? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var lastHardwareSteps: Int? = null
    private var accelStepsSinceHwSync: Int = 0
    private var gravityBaseline: Float = 9.80665f
    private var lastMagnitude: Float = 0f
    private var lastStepTimeMs: Long = 0L

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createNotificationChannel()
        startForegroundSafely()
        acquireWakeLock()
        registerSensors()
        scheduleDailyAlarms()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        isRunning = true
        if (intent?.action == ACTION_RESET_STEPS) {
            lastHardwareSteps = null
            accelStepsSinceHwSync = 0
        }
        startForegroundSafely()
        scheduleDailyAlarms()
        return START_STICKY
    }

    private fun startForegroundSafely() {
        val notification = buildNotification()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            try {
                startForeground(NOTIFICATION_ID, notification)
            } catch (_: Exception) {}
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "ระบบนับก้าวอัตโนมัติ 24 ชั่วโมง",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "นับก้าวเดินและบันทึกข้อมูลสุขภาพอัตโนมัติตลอด 24 ชั่วโมงแม้ปิดแอปพลิเคชัน"
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun getFlutterPrefs(): SharedPreferences {
        return getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private fun getLongPref(prefs: SharedPreferences, key: String, defaultVal: Long): Long {
        return try {
            prefs.getLong(key, defaultVal)
        } catch (_: ClassCastException) {
            try {
                prefs.getInt(key, defaultVal.toInt()).toLong()
            } catch (_: Exception) {
                defaultVal
            }
        }
    }

    private fun todayDateKey(): String {
        val cal = Calendar.getInstance()
        val y = cal.get(Calendar.YEAR)
        val m = cal.get(Calendar.MONTH) + 1
        val d = cal.get(Calendar.DAY_OF_MONTH)
        return "${y}_${m}_${d}"
    }

    private fun currentHour(): Int {
        return Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
    }

    private fun isWithinScheduledWindow(): Boolean {
        val prefs = getFlutterPrefs()
        val autoEnabled = prefs.getBoolean("flutter.health_auto_track_enabled", true)
        if (!autoEnabled) return false

        val is24h = prefs.getBoolean("flutter.health_auto_24h_mode", true)
        if (is24h) return true

        val startH = getLongPref(prefs, "flutter.health_auto_start_hour", 6L).toInt()
        val startM = getLongPref(prefs, "flutter.health_auto_start_minute", 0L).toInt()
        val endH = getLongPref(prefs, "flutter.health_auto_end_hour", 22L).toInt()
        val endM = getLongPref(prefs, "flutter.health_auto_end_minute", 0L).toInt()

        val cal = Calendar.getInstance()
        val nowMins = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
        val startMins = startH * 60 + startM
        val endMins = endH * 60 + endM

        return if (startMins <= endMins) {
            nowMins in startMins..endMins
        } else {
            nowMins >= startMins || nowMins <= endMins
        }
    }

    private fun getTodaySteps(): Long {
        val prefs = getFlutterPrefs()
        val key = "flutter.health_steps_${todayDateKey()}"
        return getLongPref(prefs, key, 0L)
    }

    private fun recordBackgroundStep() {
        if (!isWithinScheduledWindow()) return

        val prefs = getFlutterPrefs()
        val dKey = todayDateKey()
        val h = currentHour()

        val stepKey = "flutter.health_steps_$dKey"
        val hourKey = "flutter.health_hourly_${dKey}_$h"
        val activeKey = "flutter.health_active_sec_$dKey"

        val newSteps = getLongPref(prefs, stepKey, 0L) + 1L
        val newHourSteps = getLongPref(prefs, hourKey, 0L) + 1L
        val newActiveSec = getLongPref(prefs, activeKey, 0L) + 2L

        prefs.edit()
            .putLong(stepKey, newSteps)
            .putLong(hourKey, newHourSteps)
            .putLong(activeKey, newActiveSec)
            .apply()

        if (newSteps % 5L == 0L) {
            updateNotification()
        }
    }

    private fun buildNotification(): Notification {
        val prefs = getFlutterPrefs()
        val brandIdx = getLongPref(prefs, "flutter.health_brand_edition_index", 0L).toInt()
        val appTitle = if (packageName.contains("scirbru") || brandIdx == 1) {
            "SciRBRU Move+AI"
        } else {
            "ChewaPulse xAI"
        }
        val goal = getLongPref(prefs, "flutter.health_step_goal", 10000L)
        val steps = getTodaySteps()
        val is24h = prefs.getBoolean("flutter.health_auto_24h_mode", true)
        val startH = getLongPref(prefs, "flutter.health_auto_start_hour", 6L)
        val startM = getLongPref(prefs, "flutter.health_auto_start_minute", 0L)
        val endH = getLongPref(prefs, "flutter.health_auto_end_hour", 22L)
        val endM = getLongPref(prefs, "flutter.health_auto_end_minute", 0L)

        val modeText = if (is24h) {
            "โหมดทำงานอัตโนมัติ 24 ชม."
        } else {
            String.format("ตั้งเวลาอัตโนมัติ %02d:%02d-%02d:%02d น.", startH, startM, endH, endM)
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("$appTitle • ก้าววันนี้: $steps / $goal ก้าว")
            .setContentText("$modeText • บันทึกข้อมูลต่อเนื่องแม้ปิดแอป")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun updateNotification() {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIFICATION_ID, buildNotification())
        } catch (_: Exception) {}
    }

    private fun registerSensors() {
        try {
            sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
            val sm = sensorManager ?: return

            val stepSensor = sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
            if (stepSensor != null) {
                sm.registerListener(this, stepSensor, SensorManager.SENSOR_DELAY_NORMAL)
            }

            val accelSensor = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            if (accelSensor != null) {
                sm.registerListener(this, accelSensor, SensorManager.SENSOR_DELAY_GAME)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        val ev = event ?: return
        if (!isWithinScheduledWindow()) return

        if (ev.sensor.type == Sensor.TYPE_STEP_COUNTER) {
            val totalHwSteps = ev.values[0].toInt()
            if (lastHardwareSteps == null) {
                lastHardwareSteps = totalHwSteps
                accelStepsSinceHwSync = 0
                return
            }
            val diff = totalHwSteps - (lastHardwareSteps ?: totalHwSteps)
            lastHardwareSteps = totalHwSteps
            if (diff > 0) {
                val missed = diff - accelStepsSinceHwSync
                accelStepsSinceHwSync = 0
                if (missed > 0) {
                    val countToAdd = missed.coerceAtMost(200)
                    for (i in 0 until countToAdd) {
                        recordBackgroundStep()
                    }
                }
            }
        } else if (ev.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            val x = ev.values[0]
            val y = ev.values[1]
            val z = ev.values[2]
            val rawMag = sqrt(x * x + y * y + z * z)
            gravityBaseline = (gravityBaseline * 0.92f) + (rawMag * 0.08f)
            val linearPocketAccel = abs(rawMag - gravityBaseline)

            val nowMs = System.currentTimeMillis()
            if (linearPocketAccel > 1.25f && lastMagnitude <= 1.25f) {
                if (nowMs - lastStepTimeMs > 320L) {
                    lastStepTimeMs = nowMs
                    accelStepsSinceHwSync++
                    recordBackgroundStep()
                }
            }
            lastMagnitude = linearPocketAccel
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun acquireWakeLock() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "SmartHealthTracker::Background24hStepWakeLock"
            ).apply {
                setReferenceCounted(false)
                acquire()
            }
        } catch (_: Exception) {}
    }

    private fun scheduleDailyAlarms() {
        try {
            val prefs = getFlutterPrefs()
            val startH = getLongPref(prefs, "flutter.health_auto_start_hour", 6L).toInt()
            val startM = getLongPref(prefs, "flutter.health_auto_start_minute", 0L).toInt()

            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, AutoStepBroadcastReceiver::class.java).apply {
                action = AutoStepBroadcastReceiver.ACTION_AUTO_START_STEP_TRACKING
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                101,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val cal = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, startH)
                set(Calendar.MINUTE, startM)
                set(Calendar.SECOND, 0)
                if (timeInMillis <= System.currentTimeMillis()) {
                    add(Calendar.DAY_OF_YEAR, 1)
                }
            }

            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                cal.timeInMillis,
                pendingIntent
            )
        } catch (_: Exception) {}
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // เมื่อผู้ใช้ปัดปิดแอปออกจาก Recent Apps ให้ตั้งเวลาปลุกบริการกลับมาทำงานต่อใน 1 วินาที
        try {
            val restartIntent = Intent(applicationContext, AutoStepBroadcastReceiver::class.java).apply {
                action = AutoStepBroadcastReceiver.ACTION_AUTO_START_STEP_TRACKING
            }
            val pi = PendingIntent.getBroadcast(
                applicationContext,
                102,
                restartIntent,
                PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
            )
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.set(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + 1000L,
                pi
            )
        } catch (_: Exception) {}
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        isRunning = false
        try {
            sensorManager?.unregisterListener(this)
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

