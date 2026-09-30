import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maaya_advmobile/services/product_service.dart';

void main() {
  test('loads product data and categories from their API endpoints', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path == '/products/category-list') {
        return http.Response(jsonEncode(['beauty', 'fragrances']), 200);
      }
      if (request.url.path == '/products/category/beauty') {
        return http.Response(
          jsonEncode({
            'products': [
              {
                'id': 8,
                'title': 'Test lotion',
                'description': 'A sample product',
                'category': 'beauty',
                'price': 12.5,
                'discountPercentage': 5,
                'rating': 4.7,
                'stock': 14,
                'brand': 'Example',
                'thumbnail': 'https://example.com/item.jpg',
                'images': ['https://example.com/item.jpg'],
              },
            ],
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });
    final service = ProductService(client: client);

    final categories = await service.getCategories();
    final products = await service.getProducts(category: 'beauty');

    expect(categories, ['beauty', 'fragrances']);
    expect(products.single.title, 'Test lotion');
    expect(products.single.price, 12.5);
    expect(products.single.images, ['https://example.com/item.jpg']);
    expect(paths, ['/products/category-list', '/products/category/beauty']);
    service.dispose();
  });
}
