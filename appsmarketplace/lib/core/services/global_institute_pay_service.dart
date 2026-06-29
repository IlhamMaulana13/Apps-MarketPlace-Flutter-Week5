import 'dart:async';
import 'package:app_links/app_links.dart';

class PaymentCallbackData {
  final String status;
  final double? amount;
  final String? reference;
  final String? transactionId;

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

  Future<void> init() async {
    final appLinks = AppLinks();

    try {
      final uri = await appLinks.getInitialLink();
      if (uri != null) _handleUri(uri, isColdStart: true);
    } catch (_) {}

    appLinks.uriLinkStream.listen(_handleUri);
  }

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

  // Bangun deeplink ke Dompet Syari'ah dengan detail item pesanan.
  // Format items: "qty|nama|ukuran|harga" per item, dipisah "~"
  // Contoh: "2|Jersey Manchester United|M|150000~1|Jersey Real Madrid|L|200000"
  static String buildDeeplinkUrl({
    required int orderId,
    required double amount,
    String? description,
    List<Map<String, dynamic>>? cartItems,
  }) {
    // Encode setiap item sebagai "qty|nama|ukuran|harga"
    final itemsStr = cartItems != null && cartItems.isNotEmpty
        ? cartItems.map((i) {
            final qty = (i['quantity'] as num).toInt();
            final name = (i['product']['name'] as String)
                .replaceAll('|', '-')
                .replaceAll('~', '-');
            final size = (i['size'] ?? '-').toString();
            final price = (i['product']['price'] as num).toInt();
            return '$qty|$name|$size|$price';
          }).join('~')
        : '';

    // Deskripsi ringkas tetap dikirim sebagai fallback
    final descFallback = cartItems != null && cartItems.isNotEmpty
        ? cartItems
            .map((i) => '${(i['quantity'] as num).toInt()}x ${i['product']['name']}')
            .join(', ')
        : (description ?? 'Order #$orderId');

    final uri = Uri(
      scheme: 'dompetsyariah',
      host: 'pay',
      queryParameters: {
        'merchant_id': 'JERSEY_STORE_01',
        'merchant_name': 'Toko Jersey AppsMarketplace',
        'amount': amount.toInt().toString(),
        'description': descFallback,
        'items': itemsStr,
        'reference': 'INV-$orderId',
        'callback': 'appsmarketplace://payment-result',
      },
    );
    return uri.toString();
  }
}
