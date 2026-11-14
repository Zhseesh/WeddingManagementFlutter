import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:weddingmanagementf/app/router.dart';
import 'package:weddingmanagementf/core/database/database_helper.dart';
import 'package:weddingmanagementf/core/providers/navigation_providers.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'wedding_reminders';
  static const String _channelName = 'Pengingat Pernikahan';
  static const String _channelDesc =
      'Pengingat persiapan dan pembayaran pernikahan';

  /// Payload default untuk notifikasi pengingat — deep link ke
  /// sub-tab Pengingat pada tab Persiapan.
  static const String reminderPayload = '/preparation/reminder';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  ProviderContainer? _container;
  String? _pendingPayload;

  /// Inject ProviderContainer supaya callback notifikasi bisa mengakses
  /// state provider (mainTabProvider, prepTabProvider, routerProvider).
  void attachContainer(ProviderContainer container) {
    _container = container;
  }

  /// Ambil payload cold-start (kalau ada) dan reset.
  /// Dipanggil oleh SplashScreen setelah frame siap.
  String? consumePendingPayload() {
    final p = _pendingPayload;
    _pendingPayload = null;
    return p;
  }

  /// Handle payload — dipakai untuk cold start (dipanggil manual dari
  /// SplashScreen) maupun untuk tap notifikasi saat app sudah hidup.
  void handlePayload(String payload) {
    if (payload == reminderPayload) {
      _navigateToReminder();
    }
  }

  void _navigateToReminder() {
    final container = _container;
    if (container == null) return;

    // Set state dulu — MainShell & PreparationScreen listen ke provider ini,
    // jadi PageView & TabBar akan otomatis animasi ke tab yang benar.
    container.read(mainTabProvider.notifier).state = 1; // Persiapan
    container.read(prepTabProvider.notifier).state = 4; // Pengingat

    // Kalau user sedang di pushed route (mis. VendorDetailScreen),
    // pop dulu ke root supaya MainShell terlihat.
    final router = container.read(routerProvider);
    router.go('/app');
  }

  Future<void> rescheduleAllPending() async {
    if (!_initialized) await init();
    try {
      final db = await DatabaseHelper().database;
      final now = DateTime.now().toIso8601String();
      final rows = await db.query(
        'reminders',
        where: 'is_enabled = 1 AND is_completed = 0 AND reminder_date > ?',
        whereArgs: [now],
        orderBy: 'reminder_date ASC',
      );
      for (final row in rows) {
        final id = row['id'] as int?;
        final title = row['title'] as String?;
        final description = row['description'] as String?;
        final rawDate = row['reminder_date'] as String?;
        if (id == null || title == null || rawDate == null) continue;
        final when = DateTime.tryParse(rawDate);
        if (when == null) continue;
        await schedule(
          id: id,
          title: title,
          body: description ?? 'Pengingat pernikahan',
          when: when,
          payload: reminderPayload,
        );
      }
    } catch (_) {
      // Notifikasi bukan fitur kritis
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final tzInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      }

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: androidSettings),
        onDidReceiveNotificationResponse: _onNotificationTap,
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

      // Cold start: apakah app dibuka karena tap notifikasi?
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails!.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          _pendingPayload = payload;
        }
      }

      _initialized = true;
    } catch (_) {
      // Notifikasi bukan fitur kritis
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    handlePayload(payload);
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

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
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
        payload: payload ?? reminderPayload,
      );
    } catch (_) {}
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    if (!_initialized) await init();
    if (when.isBefore(DateTime.now())) return;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final canScheduleExact =
        (await android.canScheduleExactNotifications()) ?? false;
    final mode = canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

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

    final effectivePayload = payload ?? reminderPayload;

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
        payload: effectivePayload,
      );
    } on PlatformException catch (e) {
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
            payload: effectivePayload,
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