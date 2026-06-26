import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appsmarketplace/core/services/global_institute_pay_service.dart';
import 'package:appsmarketplace/core/services/notification_service.dart';
import 'package:appsmarketplace/core/features/cart/presentation/providers/cart_provider.dart';
import 'transaction_success_page.dart';

class PaymentPendingPage extends StatefulWidget {
  final int orderId;
  final double totalAmount;
  final String paymentMethod;

  const PaymentPendingPage({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.paymentMethod,
  });

  @override
  State<PaymentPendingPage> createState() => _PaymentPendingPageState();
}

class _PaymentPendingPageState extends State<PaymentPendingPage>
    with WidgetsBindingObserver {
  bool _payLaunched = false;
  StreamSubscription<PaymentCallbackData>? _callbackSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.paymentMethod == 'global_institute_pay') {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _launchGlobalInstitutePay(),
      );
    }

    // Cold start: app dibuka dari callback E-Money saat tertutup
    final pending = GlobalInstitutePayService().consumePendingCallback();
    if (pending != null && pending.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onPaymentSuccess(pending),
      );
    }

    // Warm start: app di background, E-Money kirim callback
    _callbackSub = GlobalInstitutePayService().onCallback.listen((data) {
      if (!mounted) return;
      if (data.isSuccess) {
        _onPaymentSuccess(data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembayaran gagal (status: ${data.status})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _callbackSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _launchGlobalInstitutePay() async {
    // Bangun deskripsi dari nama produk nyata di keranjang
    final cart = context.read<CartProvider>();
    final description = cart.items.isNotEmpty
        ? cart.items
            .map((i) => '${i['quantity']}x ${i['product']['name']}')
            .join(', ')
        : 'Pembelian Jersey';

    final deeplinkUrl = GlobalInstitutePayService.buildDeeplinkUrl(
      orderId: widget.orderId,
      amount: widget.totalAmount,
      description: description,
    );

    final uri = Uri.parse(deeplinkUrl);

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (launched) {
        setState(() => _payLaunched = true);
      } else {
        _showAppNotFoundDialog();
      }
    } catch (_) {
      if (!mounted) return;
      _showAppNotFoundDialog();
    }
  }

  void _showAppNotFoundDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aplikasi E-Money tidak ditemukan'),
        content: const Text(
          'Aplikasi Dompet Kampus belum terinstall di perangkat Anda. '
          'Silakan install terlebih dahulu untuk melanjutkan pembayaran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _onPaymentSuccess(PaymentCallbackData data) async {
    if (!mounted) return;

    final confirmedAmount = data.amount ?? widget.totalAmount;

    // 1. Kosongkan keranjang belanja
    context.read<CartProvider>().clearLocal();

    // 2. Tampilkan notifikasi push
    await NotificationService().showPaymentSuccess(
      amount: confirmedAmount,
      reference: data.reference,
      transactionId: data.transactionId,
    );

    if (!mounted) return;

    // 3. Navigasi ke halaman status transaksi
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionSuccessPage(
          amount: confirmedAmount,
          reference: data.reference,
          transactionId: data.transactionId,
          paymentMethod: 'Global Institute Pay',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menunggu Pembayaran'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 32),
              Text(
                _payLaunched
                    ? 'Selesaikan pembayaran di\nAplikasi E-Money Anda...'
                    : 'Membuka E-Money...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Jangan tutup halaman ini. Kami sedang menunggu konfirmasi pembayaran secara otomatis.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: _launchGlobalInstitutePay,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Buka Ulang Aplikasi E-Money'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
