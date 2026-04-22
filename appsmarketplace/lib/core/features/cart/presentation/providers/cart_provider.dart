import 'package:flutter/material.dart';
import 'package:appsmarketplace/core/services/dio_client.dart';

class CartProvider extends ChangeNotifier {
  Future<void> addToCart(int productId, {String? size}) async {
    await DioClient.instance.post(
      '/cart',
      data: {
        "product_id": productId,
        "quantity": 1,
        "size": size ?? "M",
      },
    );
  }
}