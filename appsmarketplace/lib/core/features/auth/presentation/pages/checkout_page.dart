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

  // Hitung total dari items secara lokal agar subtotal = total
  double _calcTotal(List items) {
    return items.fold(0.0, (sum, item) {
      final price = (item['product']['price'] as num).toDouble();
      final qty = (item['quantity'] as num).toInt();
      return sum + price * qty;
    });
  }

  Future<void> _processPayment() async {
    if (!mounted) return;
    setState(() => isProcessing = true);

    final cart = context.read<CartProvider>();

    if (selectedPaymentMethod == 'cod') {
      await _showCodSuccessDialog(_calcTotal(cart.items));
      if (!mounted) return;
      setState(() => isProcessing = false);
      return;
    }

    final orderId = DateTime.now().millisecondsSinceEpoch;
    final total = _calcTotal(cart.items);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPendingPage(
          orderId: orderId,
          totalAmount: total,
          paymentMethod: selectedPaymentMethod,
        ),
      ),
    );
  }

  Future<void> _showCodSuccessDialog(double total) async {
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
              'Rp ${formatPrice(total)}',
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
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (route) => false,
                  );
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
    final cart = context.watch<CartProvider>();
    final subtotal = _calcTotal(cart.items);

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
                  // --- DETAIL PESANAN ---
                  const Text(
                    "Detail Pesanan",
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
                      children: cart.items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final product = item['product'];
                        final price = (product['price'] as num).toDouble();
                        final qty = (item['quantity'] as num).toInt();
                        final size = item['size'] ?? 'M';
                        final imageUrl = product['image_url'] as String? ?? '';
                        final isLast = i == cart.items.length - 1;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _imagePlaceholder(),
                                          )
                                        : _imagePlaceholder(),
                                  ),
                                  const SizedBox(width: 12),

                                  // Info produk
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'] as String,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ukuran: $size  ·  Qty: $qty',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Harga
                                  Text(
                                    'Rp ${formatPrice(price * qty)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              const Divider(height: 1, indent: 12, endIndent: 12),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- METODE PEMBAYARAN ---
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
                        RadioListTile<String>(
                          title: const Text(
                            "Global Institute Pay",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                              "Bayar otomatis via aplikasi E-Money"),
                          secondary: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blue,
                          ),
                          value: 'global_institute_pay',
                          groupValue: selectedPaymentMethod,
                          onChanged: (value) {
                            if (!mounted) return;
                            setState(() => selectedPaymentMethod = value!);
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
                            setState(() => selectedPaymentMethod = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- RINGKASAN HARGA & TOMBOL BAYAR ---
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
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
                  // Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Subtotal (${cart.items.length} produk)",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        "Rp ${formatPrice(subtotal)}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(),
                  const SizedBox(height: 6),
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Tagihan",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Rp ${formatPrice(subtotal)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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

  Widget _imagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey.shade100,
      child: Icon(Icons.checkroom_outlined,
          size: 30, color: Colors.grey.shade400),
    );
  }
}
