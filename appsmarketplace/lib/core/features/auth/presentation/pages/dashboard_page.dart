import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:appsmarketplace/core/features/cart/presentation/pages/cart_page.dart';
import 'package:appsmarketplace/core/features/cart/presentation/providers/cart_provider.dart';
import 'package:appsmarketplace/core/services/auth_provider.dart';
import 'package:appsmarketplace/core/providers/theme_provider.dart';
import '../../../dashboard/presentation/providers/product_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  static const _gradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
  );
  static const _gradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1B3E), Color(0xFF163A6B)],
  );

  String _formatPrice(num price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  String _firstName(AuthProvider auth) {
    final name = auth.firebaseUser?.displayName ?? 'Sobat';
    return name.split(' ').first;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ProductProvider>().fetchProducts();
      context.read<CartProvider>().fetchCart();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<ProductProvider>().searchProducts(value);
    });
  }

  Future<void> _openCart() async {
    final cartProvider = context.read<CartProvider>();
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
    if (mounted) cartProvider.fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final product = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;

    final gradient = isDark ? _gradientDark : _gradientLight;
    final bodyBg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF2F4F8);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: bodyBg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 72,
            flexibleSpace: Container(
              decoration: BoxDecoration(gradient: gradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Madura's Jerseys",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Halo, ${_firstName(auth)} 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _AppBarBtn(
                        icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        onTap: () => context.read<ThemeProvider>().toggle(),
                        small: true,
                      ),
                      const SizedBox(width: 8),
                      _CartBtn(count: cart.items.length, onTap: _openCart, small: true),
                      const SizedBox(width: 8),
                      _AppBarBtn(
                        icon: Icons.logout_rounded,
                        onTap: () async => auth.logout(),
                        small: true,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Search Bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) {
                    setState(() {});
                    _onSearch(v);
                  },
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1A2E), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cari jersey impianmu...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1565C0), size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.grey.shade400, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              context.read<ProductProvider>().fetchProducts();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            // ── Banner ─────────────────────────────────────────────────
            if (_searchController.text.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image.network(
                        'https://media2.giphy.com/media/x3gY8SCquNZoCIdKfc/giphy.gif',
                        height: 165,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 165,
                          color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                          child: const Center(
                            child: Icon(Icons.sports_soccer, size: 48, color: Color(0xFF1565C0)),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              stops: [0.0, 0.6],
                              colors: [Colors.black87, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 14,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔥 Koleksi Jersey Terbaru',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Temukan jersey favoritmu di sini!',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Section Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _searchController.text.isEmpty ? 'Produk Pilihan' : 'Hasil Pencarian',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  if (!product.isLoading && !product.hasError)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${product.products.length} item',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Product Grid / States ───────────────────────────────────
            if (product.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF1565C0))),
              )
            else if (product.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 52, color: Colors.grey.shade400),
                      const SizedBox(height: 14),
                      Text(
                        product.error ?? 'Gagal memuat produk',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.read<ProductProvider>().fetchProducts(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (product.products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade400),
                      const SizedBox(height: 14),
                      Text(
                        'Produk tidak ditemukan',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: product.products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.60,
                  ),
                  itemBuilder: (context, index) {
                    final p = product.products[index];
                    return _ProductCard(
                      name: p.name,
                      imageUrl: p.imageUrl,
                      price: _formatPrice(p.price),
                      isDark: isDark,
                      onTap: () async {
                        final cartProvider = context.read<CartProvider>();
                        final messenger = ScaffoldMessenger.of(context);
                        await cartProvider.addToCart(p.id);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Expanded(child: Text('Berhasil ditambahkan ke keranjang')),
                              ],
                            ),
                            backgroundColor: const Color(0xFF1565C0),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(12),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable AppBar Icon Button ──────────────────────────────────────────────

class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool small;

  const _AppBarBtn({required this.icon, required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 34.0 : 40.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: small ? 18 : 20),
      ),
    );
  }
}

// ── Cart Button with Badge ───────────────────────────────────────────────────

class _CartBtn extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final bool small;

  const _CartBtn({required this.count, required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 34.0 : 40.0;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart_outlined, color: Colors.white, size: small ? 18 : 20),
          ),
          if (count > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String price;
  final bool isDark;
  final VoidCallback onTap;

  const _ProductCard({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 1.05,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFEEF2F8),
                  child: const Center(
                    child: Icon(Icons.checkroom_outlined, size: 44, color: Color(0xFFB0BEC5)),
                  ),
                ),
              ),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Rp $price',
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                      label: const Text('Beli', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
