import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maaya_advmobile/models/product.dart';
import 'package:maaya_advmobile/models/user.dart';
import 'package:maaya_advmobile/services/cart_service.dart';
import 'package:maaya_advmobile/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('user serialization retains Firebase registration details', () {
    const user = User(
      id: 9271,
      authUid: 'firebase-uid',
      loginType: LoginType.firebase,
      username: 'sample-user',
      email: 'sample@example.com',
      firstName: 'Sample',
      lastName: 'User',
      age: 24,
      contactNo: '+15551234567',
    );

    final restored = User.fromJson(user.toJson());

    expect(restored.loginType, LoginType.firebase);
    expect(restored.authUid, 'firebase-uid');
    expect(restored.age, 24);
    expect(restored.contactNo, '+15551234567');
  });

  test(
    'Firebase sign-in reports missing project configuration clearly',
    () async {
      final userService = UserService(
        client: MockClient((_) async => http.Response('{}', 500)),
      );
      await userService.init();

      expect(userService.firebaseAvailable, isFalse);
      await expectLater(
        userService.signInWithFirebase(
          email: 'user@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<UserServiceException>().having(
            (error) => error.message,
            'message',
            contains('flutterfire configure'),
          ),
        ),
      );
      userService.dispose();
    },
  );

  test(
    'requested demo credentials sign in locally and persist the user',
    () async {
      final client = MockClient((_) async {
        fail('The local demo account should not make an API request.');
      });
      final userService = UserService(client: client);
      await userService.init();

      final user = await userService.signIn(
        username: 'cham maaya',
        password: 'cham 12345',
      );

      expect(userService.isAuthenticated, isTrue);
      expect(user.username, 'cham maaya');
      expect(user.displayName, 'Cham Maaya');

      final restoredService = UserService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      await restoredService.init();
      expect(restoredService.currentUser?.username, 'cham maaya');
      expect(restoredService.isAuthenticated, isTrue);

      await userService.signOut();
      userService.dispose();
      restoredService.dispose();
    },
  );

  test('sign in persists the user and cart lookup matches user ID', () async {
    final requestedPaths = <String>[];
    final client = MockClient((request) async {
      requestedPaths.add(request.url.path);
      if (request.url.path == '/auth/login') {
        return http.Response(
          jsonEncode({
            'id': 42,
            'username': 'sample-user',
            'email': 'sample@example.com',
            'firstName': 'Sample',
            'lastName': 'User',
            'image': '',
            'accessToken': 'demo-token',
          }),
          200,
        );
      }
      if (request.url.path == '/carts/user/42') {
        return http.Response(
          jsonEncode({
            'carts': [
              {'userId': 7, 'products': []},
              {
                'userId': 42,
                'products': [
                  {
                    'id': 101,
                    'title': 'Notebook',
                    'price': 5.5,
                    'quantity': 2,
                    'thumbnail': '',
                  },
                ],
                'total': 11,
                'discountedTotal': 10,
                'totalProducts': 1,
                'totalQuantity': 2,
              },
            ],
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    final userService = UserService(client: client);
    final cartService = CartService(client: client);
    await userService.init();

    final user = await userService.signIn(
      username: 'sample-user',
      password: 'not-persisted',
    );
    final cart = await cartService.getCartForUser(user.id);

    expect(userService.isAuthenticated, isTrue);
    expect(user.displayName, 'Sample User');
    expect(cart.userId, 42);
    expect(cart.products.single.title, 'Notebook');
    expect(cart.totalQuantity, 2);
    expect(requestedPaths, ['/auth/login', '/carts/user/42']);

    final cartWithAddedProduct = await cartService.addProduct(
      user.id,
      const Product(
        id: 101,
        title: 'Notebook',
        description: '',
        category: 'stationery',
        price: 5.5,
        discountPercentage: 0,
        rating: 4.5,
        stock: 20,
        brand: '',
        thumbnail: '',
        images: [],
      ),
    );
    expect(cartWithAddedProduct.products.single.quantity, 3);

    final cartAfterRemoval = await cartService.removeProduct(user.id, 101);
    expect(cartAfterRemoval.products, isEmpty);

    final restoredService = UserService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    await restoredService.init();
    expect(restoredService.isAuthenticated, isTrue);
    expect(restoredService.currentUser?.id, 42);

    await restoredService.signOut();
    expect(restoredService.isAuthenticated, isFalse);
    userService.dispose();
    cartService.dispose();
    restoredService.dispose();
  });
}
