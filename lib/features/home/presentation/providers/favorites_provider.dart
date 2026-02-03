import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _guestKey = 'guest_favorites';

  final Set<String> _favoriteIds = {};
  String? _currentUserId;
  bool _isGuest = true;
  bool _isInitialized = false;

  Set<String> get favoriteIds => _favoriteIds;

  FavoritesProvider() {
    _initGuestFavorites();
  }

  Future<void> _initGuestFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_guestKey) ?? [];
    _favoriteIds
      ..clear()
      ..addAll(saved);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> updateAuth({
    required String? userId,
    required bool isGuest,
  }) async {
    if (!_isInitialized) {
      await _initGuestFavorites();
    }
    if (_currentUserId == userId && _isGuest == isGuest) {
      return;
    }

    _currentUserId = userId;
    _isGuest = isGuest || userId == null;

    if (_isGuest) {
      await _initGuestFavorites();
      return;
    }

    await _migrateGuestFavoritesToUser(userId!);
    await _loadUserFavorites(userId);
  }

  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  Future<void> toggleFavorite(String productId) async {
    if (_isGuest) {
      await _toggleGuestFavorite(productId);
      return;
    }

    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
      await _removeUserFavorite(productId);
    } else {
      _favoriteIds.add(productId);
      await _addUserFavorite(productId);
    }
    notifyListeners();
  }

  Future<void> _toggleGuestFavorite(String productId) async {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_guestKey, _favoriteIds.toList());
    notifyListeners();
  }

  Future<void> _loadUserFavorites(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savedItems')
        .get();
    _favoriteIds
      ..clear()
      ..addAll(snapshot.docs.map((doc) => doc.id));
    notifyListeners();
  }

  Future<void> _addUserFavorite(String productId) async {
    if (_currentUserId == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('savedItems')
        .doc(productId)
        .set({
          'productId': productId,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _removeUserFavorite(String productId) async {
    if (_currentUserId == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('savedItems')
        .doc(productId)
        .delete();
  }

  Future<void> _migrateGuestFavoritesToUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final guestFavorites = prefs.getStringList(_guestKey) ?? [];
    if (guestFavorites.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savedItems');

    for (final productId in guestFavorites) {
      final docRef = collection.doc(productId);
      batch.set(docRef, {
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    await prefs.remove(_guestKey);
    _favoriteIds
      ..clear()
      ..addAll(guestFavorites);
  }
}
