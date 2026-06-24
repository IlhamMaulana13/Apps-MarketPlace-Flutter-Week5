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
  // Set default metode pembayaran ke E-Money (Global Institute Pay)
  String selectedPaymentMethod = 'global_institute_pay';
  bool isProcessing = false;

  // Fungsi untuk memformat angka menjadi format Rupiah
  String formatPrice(num price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  // Fungsi yang dipanggil saat tombol "Bayar Sekarang" ditekan
  void _processPayment() {
    setState(() {
      isProcessing = true;
    });

    final cart = context.read<CartProvider>();
    
    // Kita buat dummy Order ID menggunakan waktu saat ini
    // Di aplikasi nyata yang sudah utuh, ini biasanya didapat dari respon API Backend
    final orderId = DateTime.now().millisecondsSinceEpoch;

    // Langsung arahkan ke halaman Payment Pending yang akan membuka aplikasi E-Money
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

  @override
  Widget build(BuildContext context) {
    // Membaca data keranjang
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Checkout"),
        centerTitle: true,
      ),
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
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
                          subtitle: const Text("Bayar otomatis via aplikasi E-Money"),
                          secondary: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                          value: 'global_institute_pay',
                          groupValue: selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              selectedPaymentMethod = value!;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        // Opsi Tambahan (Bisa dihiraukan jika hanya fokus ke E-Money)
                        RadioListTile<String>(
                          title: const Text("Transfer Bank (Manual)"),
                          secondary: const Icon(Icons.account_balance),
                          value: 'bank_transfer',
                          groupValue: selectedPaymentMethod,
                          onChanged: (value) {
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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