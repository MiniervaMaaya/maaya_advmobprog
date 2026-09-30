import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

class ProductService {
  static const String _baseUrl = AppEnvironment.apiBaseUrl;

  final http.Client _client;

  ProductService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Product>> getProducts({String query = '', String? category}) async {
    final normalizedQuery = query.trim();
    final path = normalizedQuery.isNotEmpty
        ? '/products/search?q=${Uri.encodeQueryComponent(normalizedQuery)}'
        : category == null || category == 'All'
        ? '/products?limit=100'
        : '/products/category/${Uri.encodeComponent(category)}';
    final response = await _client
        .get(Uri.parse('$_baseUrl$path'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductServiceException('Unable to load products.');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return (payload['products'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  Future<List<String>> getCategories() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/products/category-list'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductServiceException('Unable to load product categories.');
    }
    return (jsonDecode(response.body) as List<dynamic>).whereType<String>().toList();
  }

  Future<Product> getProduct(int id) async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/products/$id'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductServiceException('Unable to load this product.');
    }
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void dispose() => _client.close();
}

class ProductServiceException implements Exception {
  final String message;

  const ProductServiceException(this.message);

  @override
  String toString() => message;
}