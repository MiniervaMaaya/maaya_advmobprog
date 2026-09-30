import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maaya_advmobile/models/product.dart';
import 'package:maaya_advmobile/screens/detail_screen.dart';
import 'package:maaya_advmobile/screens/home_screen.dart';
import 'package:maaya_advmobile/services/cart_service.dart';
import 'package:maaya_advmobile/services/chat_service.dart';
import 'package:maaya_advmobile/services/product_service.dart';
import 'package:maaya_advmobile/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const product = Product(
    id: 88,
    title: 'Test mug',
    description: 'A test product',
    category: 'home',
    price: 12.5,
    discountPercentage: 0,
    rating: 4.5,
    stock: 5,
    brand: 'Test',
    thumbnail: '',
    images: [],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'overlapping initial load and add cannot overwrite the new item',
    () async {
      final responseCompleter = Completer<http.Response>();
      final requestStarted = Completer<void>();
      var cartRequests = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/carts/user/1') {
          cartRequests++;
          if (!requestStarted.isCompleted) requestStarted.complete();
          return responseCompleter.future;
        }
        return http.Response('{}', 404);
      });
      final cartService = CartService(client: client);

      final screenLoad = cartService.getCartForUser(1);
      await requestStarted.future;
      final pendingAdd = cartService.addProduct(1, product);
      responseCompleter.complete(
        http.Response(
          jsonEncode({
            'carts': [
              {
                'userId': 1,
                'products': [],
                'total': 0,
                'discountedTotal': 0,
                'totalProducts': 0,
                'totalQuantity': 0,
              },
            ],
          }),
          200,
        ),
      );

      await screenLoad;
      final updatedCart = await pendingAdd;
      final cartAfterNavigation = await cartService.getCartForUser(1);

      expect(cartRequests, 1);
      expect(updatedCart.products.single.title, product.title);
      expect(cartAfterNavigation.products.single.id, product.id);
      expect(cartAfterNavigation.totalQuantity, 1);
      cartService.dispose();
    },
  );

  test('first add is immediate and does not wait for the cart API', () async {
    var cartRequests = 0;
    final cartService = CartService(
      client: MockClient((_) async {
        cartRequests++;
        await Future<void>.delayed(const Duration(seconds: 2));
        throw const SocketException('offline');
      }),
    );

    var cartNotifications = 0;
    cartService.addListener(() => cartNotifications++);

    final cart = await cartService
        .addProduct(1, product)
        .timeout(const Duration(milliseconds: 500));

    expect(cartRequests, 0);
    expect(cart.products.single.title, product.title);
    expect(cart.totalQuantity, 1);
    expect(cartService.cartForUser(1)?.totalQuantity, 1);
    expect(cartNotifications, greaterThan(0));
    final incremented = await cartService.changeQuantity(1, product.id, 1);
    expect(incremented.products.single.quantity, 2);
    final decremented = await cartService.changeQuantity(1, product.id, -1);
    expect(decremented.products.single.quantity, 1);
    final removed = await cartService.changeQuantity(1, product.id, -1);
    expect(removed.products, isEmpty);
    expect(removed.totalProducts, 0);
    expect(removed.totalQuantity, 0);
    expect(removed.total, 0);
    final persistedCart = await cartService.getCartForUser(1);
    expect(persistedCart.products, isEmpty);
    await cartService.addProduct(1, product);
    final checkedOutCart = await cartService.clearCart(1);
    expect(checkedOutCart.products, isEmpty);
    expect(checkedOutCart.discountedTotal, 0);
    cartService.dispose();
  });

  testWidgets('detail add action opens a cart containing the product', (
    tester,
  ) async {
    final userService = UserService(
      client: MockClient((_) async => http.Response('{}', 500)),
    );
    await userService.init();
    await userService.signIn(username: 'cham maaya', password: 'cham 12345');

    final cartService = CartService(
      client: MockClient(
        (_) async => http.Response(jsonEncode({'carts': []}), 200),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserService>.value(value: userService),
          ChangeNotifierProvider<CartService>.value(value: cartService),
        ],
        child: const MaterialApp(home: DetailScreen(product: product)),
      ),
    );

    final addToCartButton = find.text('Add to cart');
    await tester.scrollUntilVisible(
      addToCartButton,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(addToCartButton);
    await tester.pumpAndSettle();
    await tester.tap(addToCartButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('VIEW CART'));
    await tester.pumpAndSettle();

    expect(find.text('Test mug'), findsOneWidget);
    expect(find.text('\$12.50 each'), findsOneWidget);
    expect(find.text('\$12.50'), findsNWidgets(3));
    expect(find.text('Checkout • \$12.50'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase Test mug quantity'));
    await tester.pumpAndSettle();
    expect((await cartService.getCartForUser(1)).products.single.quantity, 2);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('\$25.00'), findsNWidgets(3));

    await tester.tap(find.byTooltip('Decrease Test mug quantity'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('\$12.50'), findsNWidgets(3));

    await tester.tap(find.byTooltip('Decrease Test mug quantity'));
    await tester.pumpAndSettle();
    expect(find.text('This cart is empty.'), findsOneWidget);
    expect((await cartService.getCartForUser(1)).products, isEmpty);

    userService.dispose();
    cartService.dispose();
  });

  testWidgets('floating chat button opens Firebase messages', (tester) async {
    final productService = ProductService(
      client: MockClient((request) async {
        if (request.url.path == '/products/category-list') {
          return http.Response(jsonEncode([]), 200);
        }
        return http.Response(jsonEncode({'products': []}), 200);
      }),
    );

    final userService = UserService(
      client: MockClient((_) async => http.Response('{}', 500)),
    );
    await userService.init();
    final chatService = ChatService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ProductService>.value(value: productService),
          ChangeNotifierProvider<UserService>.value(value: userService),
          Provider<ChatService>.value(value: chatService),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open messages'));
    await tester.pumpAndSettle();
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Sign in with Firebase to use chat.'), findsOneWidget);
    productService.dispose();
    userService.dispose();
  });
}
