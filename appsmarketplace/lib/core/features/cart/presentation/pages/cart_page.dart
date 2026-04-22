import 'package:flutter/material.dart';
import 'package:appsmarketplace/core/services/dio_client.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Map<int, String> selectedSizes = {};

  String formatPrice(num price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  Future<void> updateQty(int id, int qty) async {
    if (qty < 1) return;

    await DioClient.instance.put('/cart/$id', data: {"quantity": qty});

    setState(() {});
  }

  Future<void> deleteItem(int id) async {
    await DioClient.instance.delete('/cart/$id');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keranjang")),
      body: FutureBuilder(
        future: DioClient.instance.get('/cart'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data['data'];
          final items = data['items'] ?? [];

          if (items.isEmpty) {
            return const Center(child: Text("Keranjang kosong"));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final product = item['product'];

                    // ✅ INIT SIZE DEFAULT BIAR GAK ERROR
                    selectedSizes.putIfAbsent(item['ID'], () => "M");

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

                          const SizedBox(width: 12),

                          // DETAIL
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
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  "Rp ${formatPrice(product['price'])}",
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // ✅ SIZE DROPDOWN FIX
                                DropdownButton<String>(
                                  value: selectedSizes[item['ID']],
                                  isExpanded: true,
                                  items: ["S", "M", "L", "XL"]
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedSizes[item['ID']] = val!;
                                    });
                                  },
                                ),

                                const SizedBox(height: 6),

                                // QTY + DELETE
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () => updateQty(
                                        item['ID'],
                                        item['quantity'] - 1,
                                      ),
                                    ),
                                    Text("${item['quantity']}"),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () => updateQty(
                                        item['ID'],
                                        item['quantity'] + 1,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => deleteItem(item['ID']),
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

              // TOTAL + CHECKOUT
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total"),
                        Text(
                          "Rp ${formatPrice(data['total_price'])}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await DioClient.instance.post(
                            '/orders/checkout',
                            data: {
                              "shipping_address": "Alamat rumah",
                              "notes": "Cepat ya",
                            },
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Checkout berhasil")),
                          );

                          setState(() {});
                        },
                        child: const Text("Checkout"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
