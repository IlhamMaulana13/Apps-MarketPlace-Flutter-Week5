import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appsmarketplace/core/features/cart/presentation/providers/cart_provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String formatPrice(num price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (cart.items.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Keranjang kosong")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, i) {
                final item = cart.items[i];
                final product = item['product'];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // IMAGE
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product['image_url'],
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
