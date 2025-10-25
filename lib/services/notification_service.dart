import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Time 헬퍼 클래스
class Time {
  final int hour;
  final int minute;
  final int second;

  const Time(this.hour, [this.minute = 0, this.second = 0])
      : assert(hour >= 0 && hour < 24),
        assert(minute >= 0 && minute < 60),
        assert(second >= 0 && second < 60);
}

/// iOS 전용 Local Notification Service
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// 초기화: iOS 전용
  Future<void> initialize() async {
    if (_isInitialized) {
      print('✅ 알림 서비스 이미 초기화됨');
      return;
    }

    print('🔧 iOS 알림 서비스 초기화 시작');
    
    // Timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    print('📍 타임존 설정: Asia/Seoul');

    // iOS 초기화 설정
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // 포그라운드 표시를 위해 delegate 경로에서 옵션 허용
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory('default_category'),
      ],
    );

    const initSettings = InitializationSettings(iOS: iosInit);
    print('⚙️ iOS 알림 초기화 설정 완료');

    final result = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print('📱 알림 초기화 결과: $result');

    // 포그라운드에서도 배너/사운드 보이게 하는 플래그는 per-notification에서 설정함
    _isInitialized = true;
    print('✅ 알림 서비스 초기화 완료');
  }

  /// 권한 요청(iOS)
  Future<bool> requestPermissions() async {
    print('🔐 권한 요청 시작');
    
    if (!_isInitialized) {
      print('⏳ 초기화되지 않음. 초기화 중...');
      await initialize();
    }

    final iosImplementation = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosImplementation == null) {
      print('❌ iOS 플러그인을 찾을 수 없음');
      return false;
    }
    
    print('🔍 iOS 알림 플러그인 발견됨');
    
    final granted = await iosImplementation.requestPermissions(
      alert: true, 
      badge: true, 
      sound: true
    );

    print('🔐 권한 요청 결과: $granted');

    return granted ?? false;
  }

  /// 10초 후 테스트 알림
  Future<void> scheduleTestIn10s() async {
    if (!_isInitialized) await initialize();

    print('🔔 10초 후 알림 예약 시작');
    
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'default_category',
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    final when = now.add(const Duration(seconds: 10));
    
    print('📅 현재 시간: $now');
    print('📅 예약 시간: $when');

    try {
      await _notifications.zonedSchedule(
        1001,
        '테스트 알림',
        '이 알림은 10초 후 표시됩니다.',
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // iOS에서 무시됨
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('✅ 10초 후 알림 예약 성공! 알림 ID: 1001');
      print('📱 10초 후 알림이 표시됩니다.');
    } catch (e) {
      print('❌ 10초 후 알림 예약 실패: $e');
      rethrow;
    }
  }

  /// 지정 시각(오늘/내일) 일회성 알림
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_isInitialized) await initialize();

    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'default_category',
      ),
    );

    final when = tz.TZDateTime.from(scheduledDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    final target = when.isBefore(now) ? when.add(const Duration(days: 1)) : when;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      target,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 매일 특정 시간 반복
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    int second = 0,
  }) async {
    if (!_isInitialized) await initialize();

    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'default_category',
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute, second);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // 탭 처리 필요 시 여기에 라우팅 추가
    // print('Tapped: ${response.id} | payload: ${response.payload}');
  }

  /// 선택: 즉시 표시(스케줄 없이)
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'default_category',
      ),
    );

    await _notifications.show(id, title, body, details);
  }

  Future<void> cancel(int id) => _notifications.cancel(id);
  Future<void> cancelAll() => _notifications.cancelAll();
  
  // 루틴 생성 화면에서 사용하는 메서드들
  Future<void> cancelNotification(int id) => _notifications.cancel(id);
  
  Future<void> cancelAllNotifications() => _notifications.cancelAll();

  /// 반복 알림 예약 (매일 특정 시간)
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required Time time,
  }) async {
    if (!_isInitialized) await initialize();

    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'default_category',
      ),
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute, time.second);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
    );
  }
}
