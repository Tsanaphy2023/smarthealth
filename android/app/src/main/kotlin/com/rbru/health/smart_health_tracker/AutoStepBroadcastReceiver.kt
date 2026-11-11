package com.rbru.health.smart_health_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AutoStepBroadcastReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_AUTO_START_STEP_TRACKING =
            "com.rbru.health.smart_health_tracker.ACTION_AUTO_START_STEP_TRACKING"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        try {
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE
            )
            val autoEnabled = prefs.getBoolean("flutter.health_auto_track_enabled", true)
            if (!autoEnabled) return

            val serviceIntent = Intent(context, StepForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

