import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'l10n.dart';

/// Local "agent finished" notifications, only while the app is backgrounded.
class Notify with WidgetsBindingObserver {
  Notify._();
  static final Notify i = Notify._();

  final _p = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool background = false;

  /// Row id of the session whose notification was tapped; the home screen opens it.
  final ValueNotifier<String?> tapped = ValueNotifier(null);

  // Channel copy is localized at first creation; Android keeps those names after
  // that, so switching the app language does not rename existing channels.
  static final _done = AndroidNotificationDetails(
    'agent_done',
    L.t('notify.doneChannel'),
    channelDescription: L.t('notify.doneChannelDesc'),
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFFD97757),
    enableVibration: true,
    styleInformation: BigTextStyleInformation(''),
  );
  static final _ask = AndroidNotificationDetails(
    'agent_ask',
    L.t('notify.approvalChannel'),
    channelDescription: L.t('notify.approvalChannelDesc'),
    importance: Importance.max,
    priority: Priority.max,
    color: Color(0xFFD97757),
    enableVibration: true,
  );

  Future<void> init() async {
    if (_ready) return;
    WidgetsBinding.instance.addObserver(this);
    await _p.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('ic_notification')),
      onDidReceiveNotificationResponse: (r) => tapped.value = r.payload,
    );
    final launch = await _p.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) tapped.value = launch!.notificationResponse?.payload;
    await _p
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    background = state != AppLifecycleState.resumed;
    // Do not cancelAll: it also removes the native foreground-service entry.
    // Completion notifications auto-cancel when tapped.
  }

  Future<void> done({required String title, required String body, String? session, bool failed = false}) async {
    if (!_ready || !background) return;
    final text = body.replaceAll(RegExp(r'MEDIA:\S+'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
    final short = text.length > 180 ? '${text.substring(0, 180)}...' : text;
    await _p.show(
      (session ?? 'x').hashCode & 0x7fffffff,
      failed ? L.t('notify.stopped', {'title': title}) : L.t('notify.finished', {'title': title}),
      short.isEmpty ? L.t('notify.taskComplete') : short,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _done.channelId,
          _done.channelName,
          channelDescription: _done.channelDescription,
          importance: _done.importance,
          priority: _done.priority,
          color: _done.color,
          styleInformation: BigTextStyleInformation(short.isEmpty ? L.t('notify.taskComplete') : short),
        ),
      ),
      payload: session,
    );
  }

  Future<void> ask({required String title, required String body, String? session}) async {
    if (!_ready || !background) return;
    await _p.show(
      ((session ?? 'x').hashCode + 1) & 0x7fffffff,
      L.t('notify.waiting', {'title': title}),
      body,
      NotificationDetails(android: _ask),
      payload: session,
    );
  }
}
