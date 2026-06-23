import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Nhắc học hằng ngày bằng local notification (E9-4). Chịu lỗi: nếu nền tảng
/// không hỗ trợ / chưa cấp quyền thì im lặng, không crash.
class NotificationService {
  static const _reminderId = 1001;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // không lấy được timezone -> dùng mặc định (UTC), vẫn lặp đúng theo time.
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      _inited = true;
    } catch (_) {}
  }

  /// Xin quyền (Android 13+/iOS). Trả về true nếu được cấp.
  Future<bool> requestPermissions() async {
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return (await android.requestNotificationsPermission()) ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return (await ios.requestPermissions(alert: true, badge: true, sound: true)) ??
            false;
      }
    } catch (_) {}
    return false;
  }

  /// Đặt nhắc học lặp hằng ngày vào [hour]:[minute]. Hủy lịch cũ trước.
  Future<void> scheduleDaily(int hour, int minute) async {
    await init();
    await cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder',
        'Nhắc học',
        channelDescription: 'Nhắc học tiếng Trung hằng ngày',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        _reminderId,
        'Học tiếng Trung 🀄',
        'Tới giờ học rồi! Giữ chuỗi streak nhé.',
        _nextInstance(hour, minute),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // lặp hằng ngày
      );
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    await init();
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }
}
