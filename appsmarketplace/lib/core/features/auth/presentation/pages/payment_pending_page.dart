import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appsmarketplace/core/services/global_institute_pay_service.dart';

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
    // Daftarkan observer agar aplikasi tahu saat user kembali dari background
    WidgetsBinding.instance.addObserver(this);

    // Otomatis buka aplikasi e-money sesaat setelah halaman dirender
    if (widget.paymentMethod == 'global_institute_pay') {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _launchGlobalInstitutePay(),
      );
    }

    // Tangani callback jika aplikasi Toko Jersey sempat tertutup (Cold Start)
    final pending = GlobalInstitutePayService().consumePendingCallback();
    if (pending != null && pending.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onPaymentSuccess(pending));
    }

    // Dengarkan balasan (callback) dari e-money saat aplikasi berjalan
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
    // Wajib: Bersihkan listener agar tidak terjadi memory leak
    _callbackSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Fungsi untuk merangkai URL dan meluncurkan aplikasi E-Money
  Future<void> _launchGlobalInstitutePay() async {
    final deeplinkUrl = GlobalInstitutePayService.buildDeeplinkUrl(
      orderId: widget.orderId,
      amount: widget.totalAmount,
      description: "Pembelian Jersey",
    );

    final uri = Uri.parse(deeplinkUrl);

    // Langsung coba buka — dialog baru tampil kalau benar-benar gagal
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  void _onPaymentSuccess(PaymentCallbackData data) {
    if (!mounted) return;

    final amountText = data.amount != null
        ? 'Rp ${data.amount!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'
        : 'Rp ${widget.totalAmount.toInt()}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pembayaran $amountText berhasil! 🎉'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    });
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
