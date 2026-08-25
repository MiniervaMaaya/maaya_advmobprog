Minimal Flutter app demonstrating ephemeral `setState` counter and an app-wide theme using `Provider`.

Run:

```bash
flutter pub get
flutter run
```

Notes:
- Counter value is local to `MyHome` and managed with `setState` (ephemeral state).
- Theme is managed by `ThemeModel` (extends `ChangeNotifier`) provided at the top-level.

## Lab Activity 2: discussion

This project separates responsibilities using Models, Services, and Screens.

- **Model** (`lib/models/product_model.dart`): defines the product data structure and parsing rules.
- **Service** (`lib/services/product_service.dart`): responsible for fetching data (mocked here). Screens call services to obtain model instances.
- **Screens** (`lib/screens/*`): UI components that call services, render model data, and handle user interaction (search, navigation to details).

Design pattern: a simple MV(S) style where Services provide Model instances and Screens render them. `Provider` is used for app-wide state (theme, counter) so multiple screens can read or mutate shared state without prop drilling.

How they interact: The `HomeScreen` uses `ProductService.getAllProducts()` to fetch a list of `Product` models. It displays them and when a card is tapped it navigates to `ProductScreen`, passing the selected `Product`. The `SettingsScreen` reads/writes the `ThemeModel` provided at app root so the UI theme changes globally.

Enhancements implemented:
- Search bar above the product list in `HomeScreen`.
- Product details page `ProductScreen` opened when product card is tapped.
- Settings page `SettingsScreen` with the dark/light mode switch moved there.

