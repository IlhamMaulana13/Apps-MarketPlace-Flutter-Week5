import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'payment_channel';
  static const _channelName = 'Pembayaran';

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Minta izin notifikasi (Android 13+ / API 33+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showPaymentSuccess({
    required double amount,
    String? reference,
    String? transactionId,
  }) async {
    final amountText =
        'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    final body = reference != null && reference.isNotEmpty
        ? '$amountText · Ref: $reference'
        : amountText;

    const details = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifikasi status pembayaran',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
    );

    await _plugin.show(
      0,
      'Pembayaran Berhasil!',
      body,
      const NotificationDetails(android: details),
    );
  }
}
