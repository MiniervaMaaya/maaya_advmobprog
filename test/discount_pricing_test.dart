import 'package:flutter_test/flutter_test.dart';
import 'package:maaya_advmobile/models/cart.dart';
import 'package:maaya_advmobile/models/product.dart';

void main() {
  test('only selected catalog products receive promotional discounts', () {
    final selected = Product.fromJson({'id': 5, 'price': 100});
    final regular = Product.fromJson({
      'id': 6,
      'price': 100,
      'discountPercentage': 99,
    });

    expect(selected.discountPercentage, 15);
    expect(selected.discountedPrice, 85);
    expect(regular.discountPercentage, 0);
    expect(regular.discountedPrice, 100);
  });

  test('product calculates its discounted price', () {
    const product = Product(
      id: 1,
      title: 'Sale item',
      description: '',
      category: 'test',
      price: 100,
      discountPercentage: 20,
      rating: 5,
      stock: 1,
      brand: 'Test',
      thumbnail: '',
      images: [],
    );

    expect(product.hasDiscount, isTrue);
    expect(product.discountedPrice, 80);
  });

  test('cart preserves original total and calculates discounted total', () {
    final cart = Cart.empty(1).withProducts(const [
      CartProduct(
        id: 1,
        title: 'Sale item',
        price: 100,
        discountPercentage: 20,
        quantity: 2,
        thumbnail: '',
      ),
    ]);

    expect(cart.total, 200);
    expect(cart.discountedTotal, 160);
    expect(cart.discountSavings, 40);
    expect(cart.products.single.discountedPrice, 80);
  });
}
