import 'package:appsmarketplace/core/features/auth/presentation/pages/payment_pending_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appsmarketplace/core/features/cart/presentation/providers/cart_provider.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String selectedPaymentMethod = 'global_institute_pay';
  bool isProcessing = false;

  String formatPrice(num price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  Future<void> _processPayment() async {
    if (!mounted) return;
    setState(() => isProcessing = true);

    if (selectedPaymentMethod == 'cod') {
      await _showCodSuccessDialog();
      if (!mounted) return;
      setState(() => isProcessing = false);
      return;
    }

    final cart = context.read<CartProvider>();
    final orderId = DateTime.now().millisecondsSinceEpoch;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPendingPage(
          orderId: orderId,
          totalAmount: cart.totalPrice.toDouble(),
          paymentMethod: selectedPaymentMethod,
        ),
      ),
    );
  }

  Future<void> _showCodSuccessDialog() async {
    final cart = context.read<CartProvider>();
    final total = formatPrice(cart.totalPrice);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pesanan Berhasil!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Rp $total',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pembayaran COD — bayar saat barang tiba.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  'Kembali ke Beranda',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Membaca data keranjang
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text("Checkout"), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- BAGIAN 1: RINGKASAN PESANAN ---
                  const Text(
                    "Ringkasan Pesanan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ],
                    ),
                    child: Column(
                      children: cart.items.map((item) {
                        final product = item['product'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${item['quantity']}x ${product['name']}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "Rp ${formatPrice(product['price'] * item['quantity'])}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- BAGIAN 2: METODE PEMBAYARAN ---
                  const Text(
                    "Metode Pembayaran",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Opsi E-Money (Global Institute Pay)
                        RadioListTile<String>(
                          title: const Text(
                            "Global Institute Pay",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            "Bayar otomatis via aplikasi E-Money",
                          ),
                          secondary: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blue,
                          ),
                          value: 'global_institute_pay',
                          groupValue: selectedPaymentMethod,
                          onChanged: (value) {
                            if (!mounted) return;
                            setState(() {
                              selectedPaymentMethod = value!;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: const Text(
                            'COD (Bayar di Tempat)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Bayar tunai saat barang tiba'),
                          secondary: const Icon(
                            Icons.delivery_dining,
                            color: Colors.green,
                          ),
                          value: 'cod',
                          groupValue: selectedPaymentMethod,
                          onChanged: (value) {
                            if (!mounted) return;
                            setState(() {
                              selectedPaymentMethod = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BAGIAN 3: TOTAL & TOMBOL BAYAR ---
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                  color: Colors.black.withOpacity(0.08),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Tagihan",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Rp ${formatPrice(cart.totalPrice)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isProcessing ? null : _processPayment,
                      child: isProcessing
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Bayar Sekarang",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
