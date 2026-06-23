import 'dart:async';
import 'package:app_links/app_links.dart';

class PaymentCallbackData {
  final String status; 
  final String? reference;
  final String? transactionId;

  const PaymentCallbackData({
    required this.status,
    this.reference,
    this.transactionId,
  });

  bool get isSuccess => status == 'success';
}

class GlobalInstitutePayService {
  // Singleton pattern: Hanya ada 1 instance service yang hidup di dalam aplikasi
  static final GlobalInstitutePayService _instance = GlobalInstitutePayService._();
  factory GlobalInstitutePayService() => _instance;
  GlobalInstitutePayService._();

  // Broadcast stream agar UI bisa 'mendengarkan' perubahan status
  final _callbackController = StreamController<PaymentCallbackData>.broadcast();
  Stream<PaymentCallbackData> get onCallback => _callbackController.stream;

  // Menangani cold start (jika app Toko Jersey sempat tertutup saat user di E-Money)
  PaymentCallbackData? _pendingCallback;

  PaymentCallbackData? consumePendingCallback() {
    final data = _pendingCallback;
    _pendingCallback = null; // Hapus setelah dikonsumsi UI
    return data;
  }

  Future<void> init() async {
    final appLinks = AppLinks();

    // Skenario 1: Aplikasi baru dibuka melalui link balasan (Cold Start)
    try {
      final uri = await appLinks.getInitialLink();
      if (uri != null) _handleUri(uri, isColdStart: true);
    } catch (_) {}

    // Skenario 2: Aplikasi sudah berjalan di background dan menerima link balasan
    appLinks.uriLinkStream.listen(_handleUri);
  }

  // 4. Memproses Link Balasan (Callback)
  void _handleUri(Uri uri, {bool isColdStart = false}) {
    // Pastikan skema dan host sesuai dengan konfigurasi Android/iOS toko Anda
    if (uri.scheme == 'appsmarketplace' && uri.host == 'payment-callback') {
      final data = PaymentCallbackData(
        status: uri.queryParameters['status'] ?? 'unknown',
        reference: uri.queryParameters['reference'],
        transactionId: uri.queryParameters['transaction_id'],
      );

      if (isColdStart) {
        _pendingCallback = data;
      }
      
      // Kirim data ke UI yang sedang mendengarkan
      _callbackController.add(data);
    }
  }

  // 5. Membuat URL Pembayaran ke E-Money
  static String buildDeeplinkUrl({
    required int orderId,
    required double amount,
    String? description,
  }) {
    final uri = Uri(
      scheme: 'e-money', // Harus sama dengan intent filter aplikasi E-Money Anda
      host: 'pay',
      queryParameters: {
        'merchant_id': 'JERSEY_STORE_01',
        'merchant_name': 'Toko Jersey AppsMarketplace',
        'amount': amount.toInt().toString(), // Pastikan angka bulat tanpa koma
        'description': (description != null && description.isNotEmpty)
            ? description
            : 'Order #$orderId',
        'reference': 'INV-$orderId',
        'callback': 'appsmarketplace://payment-callback', // Alamat balasan toko kita
      },
    );
    return uri.toString();
  }
}