package com.rbru.health.smart_health_tracker

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.speech.tts.TextToSpeech
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private var wakeLock: PowerManager.WakeLock? = null
    private var locationManager: LocationManager? = null
    private var gpsEventSink: EventChannel.EventSink? = null
    private var tts: TextToSpeech? = null
    private var isTtsReady = false

    private val locationListener = object : LocationListener {
        override fun onLocationChanged(location: Location) {
            sendLocationToFlutter(location)
        }
        override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
        override fun onProviderEnabled(provider: String) {}
        override fun onProviderDisabled(provider: String) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.rbru.health.smart_health_tracker/gps_stream"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                gpsEventSink = events
                startHardwareGpsUpdates()
            }

            override fun onCancel(arguments: Any?) {
                gpsEventSink = null
            }
        })

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.rbru.health.smart_health_tracker/tts_voice"
        ).setMethodCallHandler { call, result ->
            if (call.method == "speakThai") {
                val text = call.argument<String>("text")
                    ?: "ลุกคะ ลุกค่ะ คุณหยุดนิ่งนานเกิน 30 นาทีแล้ว ได้เวลาลุกขึ้นขยับร่างกายแล้วค่ะ"
                speakThaiPhrase(text)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.rbru.health.smart_health_tracker/background_service"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "configureAndSyncBackgroundService" -> {
                    startBackgroundStepService(StepForegroundService.ACTION_SYNC_CONFIG)
                    val todaySteps = readTodayStepsFromPrefs()
                    result.success(
                        mapOf(
                            "serviceRunning" to true,
                            "todaySteps" to todaySteps
                        )
                    )
                }
                "resetBackgroundSteps" -> {
                    startBackgroundStepService(StepForegroundService.ACTION_RESET_STEPS)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        tts = TextToSpeech(this, this)
        requestStepAndLocationPermissions()
        acquirePocketWakeLock()
        startBackgroundStepService(StepForegroundService.ACTION_SYNC_CONFIG)
    }

    private fun startBackgroundStepService(actionStr: String) {
        try {
            val serviceIntent = Intent(this, StepForegroundService::class.java).apply {
                action = actionStr
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun readTodayStepsFromPrefs(): Long {
        return try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val cal = Calendar.getInstance()
            val y = cal.get(Calendar.YEAR)
            val m = cal.get(Calendar.MONTH) + 1
            val d = cal.get(Calendar.DAY_OF_MONTH)
            val key = "flutter.health_steps_${y}_${m}_${d}"
            try {
                prefs.getLong(key, 0L)
            } catch (_: ClassCastException) {
                prefs.getInt(key, 0).toLong()
            }
        } catch (_: Exception) {
            0L
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val thaiLocale = Locale("th", "TH")
            val res = tts?.setLanguage(thaiLocale)
            if (res == TextToSpeech.LANG_MISSING_DATA || res == TextToSpeech.LANG_NOT_SUPPORTED) {
                tts?.setLanguage(Locale.forLanguageTag("th"))
            }
            tts?.setPitch(1.06f)
            tts?.setSpeechRate(1.0f)
            isTtsReady = true
        }
    }

    private fun speakThaiPhrase(text: String) {
        try {
            val toneGen = ToneGenerator(AudioManager.STREAM_ALARM, 90)
            toneGen.startTone(ToneGenerator.TONE_PROP_ACK, 300)
        } catch (e: Exception) {
            e.printStackTrace()
        }
        try {
            if (isTtsReady && tts != null) {
                val params = Bundle()
                params.putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
                tts?.speak(text, TextToSpeech.QUEUE_FLUSH, params, "smart_health_voice_alert")
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun requestStepAndLocationPermissions() {
        val permissionsToRequest = mutableListOf<String>()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED
        ) {
            permissionsToRequest.add(Manifest.permission.ACCESS_FINE_LOCATION)
            permissionsToRequest.add(Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACTIVITY_RECOGNITION)
                != PackageManager.PERMISSION_GRANTED
            ) {
                permissionsToRequest.add(Manifest.permission.ACTIVITY_RECOGNITION)
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED
            ) {
                permissionsToRequest.add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissionsToRequest.toTypedArray(), 1001)
        } else {
            startHardwareGpsUpdates()
            startBackgroundStepService(StepForegroundService.ACTION_SYNC_CONFIG)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1001) {
            startHardwareGpsUpdates()
            startBackgroundStepService(StepForegroundService.ACTION_SYNC_CONFIG)
        }
    }

    @SuppressLint("MissingPermission")
    private fun startHardwareGpsUpdates() {
        try {
            val hasFine = ContextCompat.checkSelfPermission(
                this, Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
            val hasCoarse = ContextCompat.checkSelfPermission(
                this, Manifest.permission.ACCESS_COARSE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
            if (!hasFine && !hasCoarse) return

            if (locationManager == null) {
                locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
            }
            val lm = locationManager ?: return

            val lastGps = lm.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                ?: lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            if (lastGps != null) {
                sendLocationToFlutter(lastGps)
            }

            if (lm.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                lm.requestLocationUpdates(LocationManager.GPS_PROVIDER, 1500L, 1.0f, locationListener)
            }
            if (lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                lm.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 2500L, 1.5f, locationListener)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun sendLocationToFlutter(location: Location) {
        val sink = gpsEventSink ?: return
        val map = mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "altitude" to location.altitude,
            "accuracy" to location.accuracy.toDouble(),
            "speedKmh" to (location.speed * 3.6),
            "heading" to location.bearing.toDouble(),
            "timestamp" to location.time
        )
        runOnUiThread {
            sink.success(map)
        }
    }

    private fun acquirePocketWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "SmartHealthTracker::PocketStepWakeLock"
            ).apply {
                setReferenceCounted(false)
                acquire()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        try {
            tts?.stop()
            tts?.shutdown()
            locationManager?.removeUpdates(locationListener)
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        super.onDestroy()
    }
}
