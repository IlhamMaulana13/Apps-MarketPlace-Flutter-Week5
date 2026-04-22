import 'package:flutter/material.dart';
import 'package:appsmarketplace/core/services/dio_client.dart';

class CartProvider extends ChangeNotifier {
  List items = [];
  double totalPrice = 0;
  bool isLoading = false;
