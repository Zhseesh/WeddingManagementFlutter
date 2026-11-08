package com.zsheesh.weddingmanagementf

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver

/**
 * Dipanggil setelah delay 120 detik pasca boot. Memanggil langsung
 * logic reschedule milik plugin (yang membaca SharedPreferences-nya
 * dan mendaftarkan ulang alarm ke AlarmManager). Pada titik ini
 * jam sistem sudah tersinkron NTP, jadi notifikasi terjadwal tepat.
 */
class RescheduleTriggerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        Thread {
            try {
                val pluginBoot = ScheduledNotificationBootReceiver()
                val fakeBootIntent = Intent(Intent.ACTION_BOOT_COMPLETED)
                pluginBoot.onReceive(context, fakeBootIntent)
            } catch (_: Throwable) {
                // Abaikan - notifikasi bukan fitur kritis
            } finally {
                pending.finish()
            }
        }.start()
    }
}