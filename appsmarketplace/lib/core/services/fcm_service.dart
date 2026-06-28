import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';
import 'dio_client.dart';
import 'secure_storage.dart';

/// Handler pesan background — harus top-level function (bukan method class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Android menampilkan notifikasi secara otomatis saat app di background/terminated.
  // Tidak perlu inisialisasi ulang Firebase karena sudah di-handle oleh sistem.
}

class FcmService {
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;
  FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Minta izin notifikasi (iOS & Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handler saat app di foreground
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handler saat notifikasi di-tap dan app di background (tidak terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Handler saat notifikasi di-tap dan app terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }
  }

  /// Kirim FCM token ke backend setelah login berhasil.
  Future<void> uploadToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final backendToken = await SecureStorage.getToken();
      if (backendToken == null) return;

      await DioClient.instance.post(
        '/auth/fcm-token',
        data: {'fcm_token': token},
      );
    } catch (_) {
      // Gagal upload token tidak boleh crash app
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    await NotificationService().showNotification(
      title: n.title ?? 'Notifikasi',
      body: n.body ?? '',
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    // Navigasi ke halaman transaksi berdasarkan data pesan
    // Route handling bisa ditambahkan di sini menggunakan Navigator atau router
  }
}
