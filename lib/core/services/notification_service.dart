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

  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final tzName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzName));
      } catch (_) {
        // Fallback WIB
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
          importance: Importance.high,
        ),
      );

      _initialized = true;
    } catch (_) {
      // Abaikan: notifikasi bukan fitur kritis
    }
  }

  /// Request izin POST_NOTIFICATIONS (idempoten, aman dipanggil berkali-kali).
  Future<bool> ensurePermission() async {
    if (!_initialized) await init();
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) return false;
      final result = await androidPlugin.requestNotificationsPermission();
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_initialized) await init();
    if (when.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        // FIX: parameter wajib di flutter_local_notifications 17.x
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Abaikan: notifikasi bukan fitur kritis
    }
  }

  Future<void> cancel(int id) async {
    if (!_initialized) await init();
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }
}