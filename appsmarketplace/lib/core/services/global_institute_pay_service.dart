import 'dart:async';
import 'package:app_links/app_links.dart';

class PaymentCallbackData {
  final String status;         // 'success', 'failed', 'cancelled'
  final double? amount;        // Jumlah yang dikonfirmasi e-money
  final String? reference;     // Nomor referensi / invoice
  final String? transactionId; // ID transaksi dari e-money (DKGxxx)

  const PaymentCallbackData({
    required this.status,
    this.amount,
    this.reference,
    this.transactionId,
  });

  bool get isSuccess => status == 'success';
}

class GlobalInstitutePayService {
  static final GlobalInstitutePayService _instance =
      GlobalInstitutePayService._();
  factory GlobalInstitutePayService() => _instance;
  GlobalInstitutePayService._();

  final _callbackController = StreamController<PaymentCallbackData>.broadcast();
  Stream<PaymentCallbackData> get onCallback => _callbackController.stream;

  PaymentCallbackData? _pendingCallback;

  PaymentCallbackData? consumePendingCallback() {
    final data = _pendingCallback;
    _pendingCallback = null;
    return data;
  }

  // Panggil di main.dart sebelum runApp()
  Future<void> init() async {
    final appLinks = AppLinks();

    // Skenario cold start: app dibuka langsung dari link balasan e-money
    try {
      final uri = await appLinks.getInitialLink();
      if (uri != null) _handleUri(uri, isColdStart: true);
    } catch (_) {}

    // Skenario warm start: app sudah berjalan di background
    appLinks.uriLinkStream.listen(_handleUri);
  }

  // Proses link balasan dari e-money:
  // appsmarketplace://payment-result?status=success&amount=150000
  void _handleUri(Uri uri, {bool isColdStart = false}) {
    if (uri.scheme == 'appsmarketplace' && uri.host == 'payment-result') {
      final amountStr = uri.queryParameters['amount'];
      final data = PaymentCallbackData(
        status: uri.queryParameters['status'] ?? 'unknown',
        amount: amountStr != null ? double.tryParse(amountStr) : null,
        reference: uri.queryParameters['reference'],
        transactionId: uri.queryParameters['transaction_id'],
      );

      if (isColdStart) {
        _pendingCallback = data;
      }

      _callbackController.add(data);
    }
  }

  // Bangun deeplink ke e-money:
  // dompetkampus://pay?merchant_id=X&merchant_name=Y&amount=Z
  //   &description=D&reference=R&callback=appsmarketplace://payment-result
  static String buildDeeplinkUrl({
    required int orderId,
    required double amount,
    String? description,
  }) {
    final uri = Uri(
      scheme: 'dompetkampus',
      host: 'pay',
      queryParameters: {
        'merchant_id': 'JERSEY_STORE_01',
        'merchant_name': 'Toko Jersey AppsMarketplace',
        'amount': amount.toInt().toString(),
        'description': (description != null && description.isNotEmpty)
            ? description
            : 'Order #$orderId',
        'reference': 'INV-$orderId',
        'callback': 'appsmarketplace://payment-result',
      },
    );
    return uri.toString();
  }
}
