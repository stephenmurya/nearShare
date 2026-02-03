import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:near_share/features/home/models/product.dart';
import 'package:path/path.dart' as path;

class ProductFirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProductFirestoreService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  Stream<List<Product>> streamUserProducts(String userId) {
    return _products
        .where('postedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(Product.fromFirestore).toList();
    });
  }

  Stream<List<Product>> streamAllProducts() {
    return _products.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) {
        return snapshot.docs.map(Product.fromFirestore).toList();
      },
    );
  }

  Future<String> addProduct(Product product) async {
    final data = product.toFirestoreMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    final docRef = await _products.add(data);
    return docRef.id;
  }

  Future<void> updateProduct(String id, Product product) async {
    final data = product.toFirestoreMap();
    await _products.doc(id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  Future<String> uploadProductImage({
    required String userId,
    required XFile file,
  }) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final fileName = path.basename(file.name);
      final storageRef = _storage
          .ref()
          .child('products')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
      final task = await storageRef.putData(bytes);
      return await task.ref.getDownloadURL();
    }

    final localFile = File(file.path);
    final fileName = path.basename(localFile.path);
    final storageRef = _storage
        .ref()
        .child('products')
        .child(userId)
        .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
    final task = await storageRef.putFile(localFile);
    return await task.ref.getDownloadURL();
  }
}
