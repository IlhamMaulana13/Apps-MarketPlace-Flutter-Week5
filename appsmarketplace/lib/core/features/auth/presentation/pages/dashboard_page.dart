import 'dart:async';
import 'package:appsmarketplace/core/features/cart/presentation/pages/cart_page.dart';
import 'package:appsmarketplace/core/features/cart/presentation/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:appsmarketplace/core/services/auth_provider.dart';
import '../../../dashboard/presentation/providers/product_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _formatPrice(num price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // ✅ penting
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<ProductProvider>().searchProducts(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final product = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Madura\'s Jerseys', style: TextStyle(fontSize: 18)),
            Text(
              'Halo, ${auth.firebaseUser?.displayName ?? 'User'}!',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await auth.logout(),
          ),

          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ],
      ),

      body: Builder(
        builder: (_) {
          if (product.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (product.hasError) {
            return Center(child: Text(product.error ?? 'Error'));
          }

          if (product.products.isEmpty) {
            return const Center(child: Text('Tidak ada produk'));
          }

          return ListView(
            children: [
              // 🔍 SEARCH
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {});
                    _onSearch(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari jersey...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // 🎯 BANNER (hanya kalau search kosong)
              if (_searchController.text.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://media2.giphy.com/media/x3gY8SCquNZoCIdKfc/giphy.gif',
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(height: 150),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // 🛍️ GRID PRODUCT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: product.products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemBuilder: (context, index) {
                    final p = product.products[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 1.2,
                            child: Image.network(
                              p.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  'Rp ${_formatPrice(p.price)}',
                                  style: const TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                SizedBox(
                                  width: double.infinity,
                                  height: 30,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await context
                                          .read<CartProvider>()
                                          .addToCart(p.id);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Masuk ke keranjang"),
                                        ),
                                      );

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CartPage(),
                                        ),
                                      );
                                    },
                                    child: const Text("Beli"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
