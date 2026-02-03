import 'package:flutter/material.dart';
import 'package:near_share/features/home/models/product.dart';
import 'package:near_share/features/home/services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _service = ProductService();
  final List<Product> _products = [];

  List<Product> get products => List.unmodifiable(_products);

  Future<void> loadProducts() async {
    final loaded = await _service.loadProducts();
    _products.clear();
    _products.addAll(loaded);
    notifyListeners();
  }

  List<Product> myProducts(String? userId) {
    if (userId == null) return [];
    return _products.where((p) => p.postedBy == userId).toList();
  }

  void addProduct(Product product, String currentUserId) {
    final newProduct = Product(
      id: product.id,
      name: product.name,
      category: product.category,
      price: product.price,
      image: product.image,
      description: product.description,
      location: product.location,
      specs: product.specs,
      images: product.images,
      postedBy: currentUserId,
      userRating: product.userRating,
      userProfilePic: product.userProfilePic,
    );
    _products.insert(0, newProduct);
    _service.saveProducts(_products);
    notifyListeners();
  }

  void updateProduct(String id, Product updated) {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final existing = _products[idx];
      _products[idx] = Product(
        id: existing.id,
        name: updated.name,
        category: updated.category,
        price: updated.price,
        image: updated.image,
        description: updated.description,
        location: updated.location ?? existing.location,
        specs: updated.specs ?? existing.specs,
        images: updated.images ?? existing.images,
        postedBy: existing.postedBy,
        userRating: updated.userRating ?? existing.userRating,
        userProfilePic: updated.userProfilePic ?? existing.userProfilePic,
      );
      notifyListeners();
      _service.saveProducts(_products);
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    _service.saveProducts(_products);
    notifyListeners();
  }
}
