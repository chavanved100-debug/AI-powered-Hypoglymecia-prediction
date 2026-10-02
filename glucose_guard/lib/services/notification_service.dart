import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/prediction.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> notifyIfHigherRisk(PredictionResult prediction) async {
    if (prediction.riskLevel == RiskLevel.low) return;
    await init();
    if (!_ready) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'gluco_risk',
          'Glucose risk alerts',
          channelDescription: 'Alerts when meal risk is moderate or high',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      final high = prediction.riskLevel == RiskLevel.high;
      await _plugin.show(
        1001,
        high ? 'High glucose risk' : 'Elevated glucose risk',
        high
            ? 'This meal scored ${prediction.riskScore}%. Check glucose and follow your care plan.'
            : 'This meal scored ${prediction.riskScore}% (moderate). Monitor after eating.',
        details,
      );
    } catch (_) {}
  }
}
