import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appsmarketplace/core/features/cart/presentation/providers/cart_provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Map<int, String> selectedSizes = {};

  bool isCheckingOut = false;

  String formatPrice(num price) {
    return price.toStringAsFixed(0).replaceAllMapped(
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

  Future<void> _simulateCheckout() async {
    setState(() {
      isCheckingOut = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    final cart = context.read<CartProvider>();

    cart.items.clear();
    cart.totalPrice = 0;
    cart.notifyListeners();

    setState(() {
      isCheckingOut = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Checkout berhasil 🎉"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    // LOADING
    if (cart.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // EMPTY CART
    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Keranjang"),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 90,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                "Keranjang kosong",
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        title: const Text("Keranjang"),
        centerTitle: true,
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              itemCount: cart.items.length,
              itemBuilder: (context, i) {
                final item = cart.items[i];
                final product = item['product'];

                final sizeFromApi = item['size'] ?? "M";

                selectedSizes.putIfAbsent(
                  item['ID'],
                  () => sizeFromApi,
                );

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IMAGE
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product['image_url'],
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // CONTENT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Rp ${formatPrice(product['price'])}",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // SIZE
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: selectedSizes[item['ID']],
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: ["S", "M", "L", "XL"]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) async {
                                  if (val == null) return;

                                  setState(() {
                                    selectedSizes[item['ID']] = val;
                                  });

                                  await context
                                      .read<CartProvider>()
                                      .updateItem(
                                        item['ID'],
                                        item['quantity'],
                                        val,
                                      );
                                },
                              ),
                            ),

                            const SizedBox(height: 10),

                            // QTY
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade200,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: () {
                                      final qty =
                                          item['quantity'] - 1;

                                      // SESUAI MODUL
                                      if (qty <= 0) {
                                        context
                                            .read<CartProvider>()
                                            .removeItem(item['ID']);
                                      } else {
                                        context
                                            .read<CartProvider>()
                                            .updateItem(
                                              item['ID'],
                                              qty,
                                              selectedSizes[item['ID']],
                                            );
                                      }
                                    },
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    "${item['quantity']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),

                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade200,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () {
                                      context
                                          .read<CartProvider>()
                                          .updateItem(
                                            item['ID'],
                                            item['quantity'] + 1,
                                            selectedSizes[item['ID']],
                                          );
                                    },
                                  ),
                                ),

                                const Spacer(),

                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    context
                                        .read<CartProvider>()
                                        .removeItem(item['ID']);
                                  },
                                ),
                              ],
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

          // TOTAL SECTION
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
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total",
                        style: TextStyle(
                          fontSize: 16,
                        ),
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
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),

                      onPressed:
                          isCheckingOut ? null : _simulateCheckout,

                      child: isCheckingOut
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Checkout",
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