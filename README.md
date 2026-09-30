# maaya_advmobile

A Flutter storefront with persistent sign-in, product browsing, a user-specific cart, and account settings.

## Project Structure

```text
assets/
	images/
lib/
	models/       cart.dart, product.dart, user.dart
	providers/    task_provider.dart, theme_provider.dart
	screens/      cart, detail, home, product, profile, settings, sign-in, splash
	services/     cart_service.dart, product_service.dart, user_service.dart
	widgets/      reusable controls and custom_text.dart
	constants.dart
	main.dart
test/
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## LabActivity4: Discussion

### User model, service, and screens

`User` maps the authentication API response into the user ID, username, email, gender, display name, and profile image used by the UI. `UserService` handles sign-in and persistent session data. `ProductService` loads and searches the catalog. `CartService` loads the authenticated user's cart by ID and persists cart edits locally. The splash screen checks the saved session and routes to the storefront or sign-in screen.

The sign-in screen validates input and calls `UserService`; it does not store the password. The profile screen reads the restored `User` from the service and displays its fields. The Shop tab loads products, opens a product detail screen, and can add the selected product to that user's cart. The Cart tab loads `/carts/user/{userId}` through `CartService`, then persists additions/removals under that user ID.

### Updated design pattern

The implementation follows the attached separation pattern: data objects live in `models/`, API and persistence logic in `services/`, app-wide appearance state in `providers/`, and screen composition in `screens/`. Reusable typography and shared design tokens live in `widgets/` and `constants.dart`. The persistent bottom navigation exposes Shop, Chat, Cart, and Account.

### Rendering cart data by user ID

The signed-in user's saved ID selects the cart shown on the Cart tab. `CartScreen` requests the matching `/carts/user/{userId}` response, shows loading and retry states, and renders product quantities and totals. Added and removed products are persisted locally by that same ID. The app uses DummyJSON as the activity's demonstration API; replace the base URL in `lib/constants.dart` with the class API endpoint when one is supplied.

### Sign-in

The sign-in screen uses Firebase Authentication email/password accounts. New users can create an account from the sign-in screen. The app requires an internet connection for authentication and remote cart requests. `SharedPreferences` persistence is suitable for this classroom demo; production apps should store access tokens with platform-backed secure storage.

## LabActivity5: Firebase Authentication

Lab 5 adds a Firebase sign-in mode alongside DummyJSON. Firebase accounts use Firebase Authentication email/password; registration stores first name, last name, age, contact number, username, and email in the Firestore `users/{uid}` document. `UserService.getUserData()` returns the current profile according to its login type. Firebase's SDK manages ID-token refresh; the app can also force-refresh a token through `refreshFirebaseToken()`.

### Firebase setup

1. Create a Firebase project and register the Android, iOS, and/or Web apps.
2. Enable **Authentication > Sign-in method > Email/Password**.
3. Create a Firestore database and publish the root `firestore.rules`. Each account can access only `users/{its-own-uid}`.
4. Install and run FlutterFire CLI from the project root: `dart pub global activate flutterfire_cli`, then `flutterfire configure`. This generates/replaces `lib/firebase_options.dart` and registers platform apps.
5. Run `flutter pub get` and restart the app. Until Firebase is configured, DummyJSON sign-in remains available and Firebase mode shows a setup message.

### Auth workflow and discussion

The sign-in screen uses the Firebase Auth SDK, while additional registration fields are stored in Firestore under the authenticated UID. `UserService` restores the authenticated account and clears the session on logout. Username edits update the profile document; password changes and account deletion reauthenticate with the current password. Firebase Authentication plus owner-only Firestore rules provides managed credentials, ID-token refresh, and per-user data access.

## LabActivity6: Firebase Chat

The second bottom-navigation tab and the Shop screen's floating Chat button open the Firebase chat experience. The Cart remains available as a separate navigation tab. Chat streams registered users from Firestore, excludes the signed-in account, and filters the list by display name or email. Selecting a user opens a real-time conversation with animated sender/receiver bubbles, timestamps, an optimistic sending state, and delivered/seen indicators.

Conversations use deterministic IDs derived from their two Firebase UIDs. Messages are stored under `conversations/{conversationId}/messages`, and Firestore rules restrict conversations and messages to their participants. Unlike the activity handout's open-rule example, the deployed rules do not grant public read or write access.
