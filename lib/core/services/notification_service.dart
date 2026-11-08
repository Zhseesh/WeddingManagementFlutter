import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'wedding_reminders';
  static const String _channelName = 'Pengingat Pernikahan';
  static const String _channelDesc =
      'Pengingat persiapan dan pembayaran pernikahan';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> rescheduleAllPending() async {
    // Implementasi: baca semua reminder dengan isEnabled=true dan isCompleted=false
    // yang reminderDate-nya di masa depan, lalu panggil schedule()
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final tzName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzName));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: androidSettings),
      );

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      _initialized = true;
    } catch (_) {
      // Notifikasi bukan fitur kritis
    }
  }

  Future<bool> ensurePermission() async {
    if (!_initialized) await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return false;
      final notifOk = (await android.requestNotificationsPermission()) ?? false;
      final exactOk = (await android.requestExactAlarmsPermission()) ?? false;
      return notifOk && exactOk;
    } catch (_) {
      return false;
    }
  }

  /// Tes instan: tampilkan notifikasi SEKARANG (bukan scheduled).
  /// Kalau method ini berhasil tapi `schedule` tidak, masalahnya di
  /// penjadwalan (izin exact alarm / OEM background restriction).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_initialized) await init();
    if (when.isBefore(DateTime.now())) return;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    // Cek apakah exact alarm diizinkan. Ini pengganti
    // resolveAndroidScheduleMode yang tidak tersedia di versi 17.x.
    final canScheduleExact =
        (await android.canScheduleExactNotifications()) ?? false;
    final mode = canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    // FIX: NotificationDetails sekarang const
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: mode,
      );
    } on PlatformException catch (e) {
      // Fallback jika exact ditolak sistem (meski canScheduleExact=true,
      // race condition bisa terjadi)
      if (e.code == 'exact_alarms_not_permitted') {
        try {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(when, tz.local),
            notificationDetails,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (_) {}
      }
    }
  }

  Future<void> cancel(int id) async {
    if (!_initialized) await init();
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }
}