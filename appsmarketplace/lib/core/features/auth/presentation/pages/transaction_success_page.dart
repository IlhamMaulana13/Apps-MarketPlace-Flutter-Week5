import 'package:flutter/material.dart';
import 'package:appsmarketplace/core/routes/app_router.dart';

class TransactionSuccessPage extends StatelessWidget {
  final double amount;
  final String? reference;
  final String? transactionId;
  final String paymentMethod;

  const TransactionSuccessPage({
    super.key,
    required this.amount,
    this.reference,
    this.transactionId,
    this.paymentMethod = 'Global Institute Pay',
  });

  String _formatRupiah(double val) {
    return 'Rp ${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  void _goHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.dashboard,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        // Tombol "Kembali" di-pin di bawah, konten bisa di-scroll di atas
        body: SafeArea(
          child: Column(
            children: [
              // Konten yang bisa di-scroll (tidak overflow)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Animasi ikon centang
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        builder: (_, v, child) =>
                            Transform.scale(scale: v, child: child),
                        child: Container(
                          width: 108,
                          height: 108,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F8EE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 64,
                            color: Color(0xFF2DA44E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Pembayaran Berhasil!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pesanan Anda telah dikonfirmasi.\nTerima kasih sudah berbelanja!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 28),

                      // Kartu detail transaksi
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Total Pembayaran',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRupiah(amount),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFE5E7EB)),
                            const SizedBox(height: 10),

                            _DetailRow(
                              label: 'Status',
                              value: 'Berhasil',
                              valueColor: const Color(0xFF2DA44E),
                              valueBold: true,
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(
                              label: 'Metode',
                              value: paymentMethod,
                            ),
                            if (reference != null &&
                                reference!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _DetailRow(
                                label: 'No. Referensi',
                                value: reference!,
                              ),
                            ],
                            if (transactionId != null &&
                                transactionId!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _DetailRow(
                                label: 'ID Transaksi',
                                value: transactionId!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tombol di-pin di bagian bawah, tidak ikut scroll
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _goHome(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DA44E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }
}
