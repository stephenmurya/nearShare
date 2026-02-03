import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:near_share/features/home/models/product.dart';

class ProductService {
  Future<List<Product>> loadProducts() async {
    try {
      // Prefer reading from disk if available (useful during development)
      final file = File('assets/mock_db.json');
      String response;
      if (await file.exists()) {
        response = await file.readAsString();
      } else {
        response = await rootBundle.loadString('assets/mock_db.json');
      }
      final data = json.decode(response);
      final List<dynamic> productsJson = data['products'] ?? [];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error loading products: $e');
      return [];
    }
  }

  Future<void> saveProducts(List<Product> products) async {
    try {
      final file = File('assets/mock_db.json');
      final Map<String, dynamic> out = {
        'products': products.map((p) => p.toJson()).toList(),
      };
      await file.writeAsString(JsonEncoder.withIndent('  ').convert(out));
    } catch (e) {
      print('Error saving products: $e');
    }
  }
}
