import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService extends ChangeNotifier {
  static const String _baseUrl = AppEnvironment.apiBaseUrl;
  final http.Client _client;
  final Map<int, Future<Cart>> _initialLoads = {};
  final Map<int, Future<void>> _mutationQueues = {};
  final Map<int, Cart> _carts = {};

  CartService({http.Client? client}) : _client = client ?? http.Client();

  Cart? cartForUser(int userId) => _carts[userId];

  Future<Cart> getCartForUser(int userId) async {
    final liveCart = _carts[userId];
    if (liveCart != null) return liveCart;

    final cachedCart = await _getCachedCart(userId);
    if (cachedCart != null) {
      _carts[userId] = cachedCart;
      return cachedCart;
    }

    final pendingLoad = _initialLoads[userId];
    if (pendingLoad != null) return pendingLoad;

    final initialLoad = _loadInitialCart(userId);
    _initialLoads[userId] = initialLoad;
    try {
      return await initialLoad;
    } finally {
      if (identical(_initialLoads[userId], initialLoad)) {
        _initialLoads.remove(userId);
      }
    }
  }

  Future<Cart> addProduct(int userId, Product product) async {
    return _mutateCart(userId, (cart) {
      final products = [...cart.products];
      final existingIndex = products.indexWhere(
        (item) => item.id == product.id,
      );
      if (existingIndex == -1) {
        products.add(
          CartProduct(
            id: product.id,
            title: product.title,
            price: product.price,
            discountPercentage: product.discountPercentage,
            quantity: 1,
            thumbnail: product.thumbnail,
          ),
        );
      } else {
        final existing = products[existingIndex];
        products[existingIndex] = CartProduct(
          id: existing.id,
          title: existing.title,
          price: existing.price,
          discountPercentage: existing.discountPercentage,
          quantity: existing.quantity + 1,
          thumbnail: existing.thumbnail,
        );
      }
      return cart.withProducts(products);
    }, useEmptyCartIfMissing: true);
  }

  Future<Cart> removeProduct(int userId, int productId) async {
    return _mutateCart(
      userId,
      (cart) => cart.withProducts(
        cart.products.where((product) => product.id != productId).toList(),
      ),
    );
  }

  Future<Cart> clearCart(int userId) {
    return _mutateCart(
      userId,
      (cart) => cart.withProducts(const []),
      useEmptyCartIfMissing: true,
    );
  }

  Future<Cart> changeQuantity(int userId, int productId, int change) {
    if (change == 0) return getCartForUser(userId);

    return _mutateCart(userId, (cart) {
      final index = cart.products.indexWhere((item) => item.id == productId);
      if (index == -1) return cart;

      final products = [...cart.products];
      final current = products[index];
      final quantity = current.quantity + change;
      if (quantity < 1) {
        products.removeAt(index);
        return cart.withProducts(products);
      }

      products[index] = CartProduct(
        id: current.id,
        title: current.title,
        price: current.price,
        discountPercentage: current.discountPercentage,
        quantity: quantity,
        thumbnail: current.thumbnail,
      );
      return cart.withProducts(products);
    });
  }

  Future<Cart> _loadInitialCart(int userId) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/carts/user/$userId'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CartServiceException('Unable to load this user\'s cart.');
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final carts = (payload['carts'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Cart.fromJson)
          .where((cart) => cart.userId == userId)
          .toList();
      final cart = carts.isEmpty ? Cart.empty(userId) : carts.first;
      await _saveCart(cart);
      return cart;
    } on Exception {
      final cart = Cart.empty(userId);
      await _saveCart(cart);
      return cart;
    }
  }

  Future<Cart> _mutateCart(
    int userId,
    Cart Function(Cart) update, {
    bool useEmptyCartIfMissing = false,
  }) async {
    final previousMutation = _mutationQueues[userId] ?? Future<void>.value();
    final completer = Completer<void>();
    final currentMutation = completer.future;
    _mutationQueues[userId] = currentMutation;

    await previousMutation;
    try {
      final cart = await _cartForMutation(
        userId,
        useEmptyCartIfMissing: useEmptyCartIfMissing,
      );
      final updatedCart = update(cart);
      await _saveCart(updatedCart);
      return updatedCart;
    } finally {
      completer.complete();
      if (identical(_mutationQueues[userId], currentMutation)) {
        _mutationQueues.remove(userId);
      }
    }
  }

  Future<Cart> _cartForMutation(
    int userId, {
    required bool useEmptyCartIfMissing,
  }) async {
    // If a load already started, preserve its server items before mutating.
    final pendingLoad = _initialLoads[userId];
    if (pendingLoad != null) return pendingLoad;

    final cachedCart = await _getCachedCart(userId);
    if (cachedCart != null) return cachedCart;

    // Adding a product should never wait for an optional demonstration API.
    if (useEmptyCartIfMissing) return Cart.empty(userId);
    return getCartForUser(userId);
  }

  Future<Cart?> _getCachedCart(int userId) async {
    final preferences = await SharedPreferences.getInstance();
    final cachedCart = preferences.getString(_cartKey(userId));
    if (cachedCart == null) return null;
    try {
      return Cart.fromJson(jsonDecode(cachedCart) as Map<String, dynamic>);
    } on FormatException {
      await preferences.remove(_cartKey(userId));
      return null;
    }
  }

  Future<void> _saveCart(Cart cart) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _cartKey(cart.userId),
      jsonEncode(cart.toJson()),
    );
    _carts[cart.userId] = cart;
    notifyListeners();
  }

  String _cartKey(int userId) => 'lab4_cart_$userId';

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}

class CartServiceException implements Exception {
  final String message;

  const CartServiceException(this.message);

  @override
  String toString() => message;
}
