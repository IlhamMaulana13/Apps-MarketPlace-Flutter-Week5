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

class _PaymentPendingPageState extends State<PaymentPendingPage> with WidgetsBindingObserver {
  bool _payLaunched = false;
  StreamSubscription<PaymentCallbackData>? _callbackSub; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Otomatis buka e-money saat halaman dirender
    if (widget.paymentMethod == 'global_institute_pay') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _launchGlobalInstitutePay());
    }

    // Tangani callback jika app sempat tertutup
    final pending = GlobalInstitutePayService().consumePendingCallback();
    if (pending != null && pending.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onPaymentSuccess());
    }

    // Dengarkan balasan (callback) dari e-money
    _callbackSub = GlobalInstitutePayService().onCallback.listen((data) {
      if (!mounted) return;
      if (data.isSuccess) {
        _onPaymentSuccess(); 
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
    // Pakai widget.orderId dan widget.totalAmount di sini
    final deeplinkUrl = GlobalInstitutePayService.buildDeeplinkUrl(
      orderId: widget.orderId,
      amount: widget.totalAmount, 
      description: "Pembelian Jersey",
    );
    
    final uri = Uri.parse(deeplinkUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _payLaunched = true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aplikasi E-Money tidak ditemukan di perangkat ini.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onPaymentSuccess() {
    // Sementara kita tampilkan notifikasi jika sukses
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hore! Pembayaran Berhasil! 🎉'),
        backgroundColor: Colors.green,
      ),
    );
    // Nanti di sini bisa ditambahkan logika untuk navigasi balik ke Beranda
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menunggu Pembayaran')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _payLaunched 
                ? 'Selesaikan pembayaran di Aplikasi E-Money...' 
                : 'Membuka E-Money...',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _launchGlobalInstitutePay,
              child: const Text('Buka Ulang Aplikasi E-Money'),
            )
          ],
        ),
      ),
    );
  }
}