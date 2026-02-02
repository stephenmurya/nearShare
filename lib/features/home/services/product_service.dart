import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:near_share/features/home/models/product.dart';

class ProductService {
  Future<List<Product>> loadProducts() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/mock_db.json',
      );
      final data = await json.decode(response);
      final List<dynamic> productsJson = data['products'];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error loading products: $e');
      return [];
    }
  }
}
