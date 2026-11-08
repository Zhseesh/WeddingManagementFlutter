package com.zsheesh.weddingmanagementf

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock

/**
 * Menerima BOOT_COMPLETED lalu menunda eksekusi selama 120 detik.
 * Delay ini memberi waktu NTP sync selesai agar jam sistem
 * akurat saat reschedule. Tanpa delay, plugin menghitung
 * jadwal dengan jam RTC hardware yang bisa meleset beberapa menit.
 */
class DelayedBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val trigger = Intent(context, RescheduleTriggerReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            context,
            424242,
            trigger,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        try {
            am.setExactAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + 120_000L,
                pi
            )
        } catch (_: SecurityException) {
            // Fallback: alarm inexact kalau exact ditolak (jarang terjadi untuk ELAPSED_REALTIME)
            am.set(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + 120_000L,
                pi
            )
        }
    }
}