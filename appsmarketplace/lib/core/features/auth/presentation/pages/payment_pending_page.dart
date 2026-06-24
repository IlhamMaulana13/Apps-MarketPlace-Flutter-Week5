import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// PENTING: Pastikan path import ini sesuai dengan letak file service Anda
// Jika nama folderned berbeda, silakan disesuaikan
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
    // Daftarkan observer agar aplikasi tahu saat user kembali dari background
    WidgetsBinding.instance.addObserver(this);

    // Otomatis buka aplikasi e-money sesaat setelah halaman dirender
    if (widget.paymentMethod == 'global_institute_pay') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _launchGlobalInstitutePay());
    }

    // Tangani callback jika aplikasi Toko Jersey sempat tertutup (Cold Start)
    final pending = GlobalInstitutePayService().consumePendingCallback();
    if (pending != null && pending.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onPaymentSuccess());
    }

    // Dengarkan balasan (callback) dari e-money saat aplikasi berjalan
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

    // Coba buka aplikasi E-Money (dompetkampus://)
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _payLaunched = true);
    } catch (e) {
      // Jika error atau aplikasi E-Money belum terinstall
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka E-Money. Pastikan aplikasi Dompet Kampus sudah terinstall.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi yang dipanggil saat pembayaran di E-Money sukses dan kembali ke Toko
  void _onPaymentSuccess() {
    // Anda bisa mengganti ini dengan navigasi ke halaman "Pesanan Berhasil"
    // Contoh: Navigator.pushReplacementNamed(context, '/order-success');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hore! Pembayaran Berhasil! 🎉'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Kembali ke beranda setelah sukses
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}