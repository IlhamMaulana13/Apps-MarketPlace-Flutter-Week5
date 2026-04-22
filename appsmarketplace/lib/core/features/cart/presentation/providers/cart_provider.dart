import 'package:flutter/material.dart';
import 'package:appsmarketplace/core/services/dio_client.dart';

class CartProvider extends ChangeNotifier {
  List items = [];
  double totalPrice = 0;
  bool isLoading = false;

Future<void> fetchCart() async {
    isLoading = true;
    notifyListeners();

    final res = await DioClient.instance.get('/cart');

    items = res.data['data']['items'] ?? [];
    totalPrice =
        (res.data['data']['total_price'] as num?)?.toDouble() ?? 0;

    isLoading = false;
    notifyListeners();
  }