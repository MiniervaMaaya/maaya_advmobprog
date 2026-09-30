# Progress - Flutter Task Management App

A beautiful, responsive Flutter mobile application for productivity and task management following Material Design 3 principles with clean architecture.

## 📋 Project Structure

```
lib/
├── main.dart                          # App entry point with theme setup
├── screens/
│   ├── login_screen.dart             # Login screen with validation
│   ├── dashboard_screen.dart         # Main dashboard with tasks
│   └── notification_screen.dart      # Notifications display
├── widgets/
│   ├── custom_button.dart            # Reusable button widget
│   ├── custom_textfield.dart         # Reusable text field with validation
│   ├── analog_clock.dart             # Animated analog clock
│   ├── task_card.dart                # Individual task display
│   ├── notification_card.dart        # Individual notification display
│   └── widgets.dart                  # Widgets export file
├── models/
│   ├── task.dart                     # Task model with JSON serialization
│   └── notification_model.dart       # Notification model
├── services/
│   └── storage_service.dart          # SharedPreferences service for local storage
├── providers/
│   └── task_provider.dart            # Provider for task state management
├── utils/
│   ├── constants.dart                # App colors, spacing, text styles
│   └── validators.dart               # Form validation functions
└── assets/
    └── images/                       # App assets folder
```

## 🎨 Design Features

- **Color Scheme**: Soft Teal (#59A9AE) primary color with light cyan backgrounds
- **Typography**: Google Fonts - Poppins
- **Material Design 3**: Latest Flutter Material design system
- **Responsive Layout**: Adapts to different screen sizes
- **Rounded Corners**: 8-30px border radius for modern look
- **Soft Shadows**: Subtle shadows for depth
- **Null Safety**: 100% null safe code

## 🔐 Features

### 1. **Login Screen**
- Email and password validation
- Forgot password link (placeholder)
- Sign up option (placeholder)
- Loading state animation
- Form validation with error messages

### 2. **Dashboard Screen**
- Dynamic greeting based on time of day
- Analog clock widget
- User profile section
- Task management with CRUD operations:
  - ✅ Add new tasks
  - ✏️ Edit existing tasks
  - 🗑️ Delete tasks
  - ✔️ Mark tasks complete/incomplete
- Task counter (completed/total)
- Bottom navigation to Notifications
- Floating action button for quick task creation

### 3. **Notification Screen**
- Scrollable notification list
- Interactive notification cards
- Dismiss notifications
- Icon and color-coded notifications
- Empty state handling

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK (3.12.2 or higher)
- IDE: VS Code or Android Studio

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd maaya_advmobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Build for Different Platforms

**Android**
```bash
flutter build apk
```

**iOS**
```bash
flutter build ios
```

**Web**
```bash
flutter build web
```

## 📦 Dependencies

- **provider** (^6.0.0) - State management
- **shared_preferences** (^2.2.0) - Local storage
- **google_fonts** (^6.1.0) - Poppins font
- **intl** (^0.19.0) - Date/time formatting
- **uuid** (^4.0.0) - Unique ID generation

## 🔄 State Management

The app uses **Provider** for state management:
- `TaskProvider`: Manages all task-related state
  - Add/Edit/Delete tasks
  - Toggle task completion
  - Load tasks from storage
  - Task statistics

## 💾 Local Storage

**SharedPreferences** is used to persist:
- User login state
- User email and name
- Task list (JSON serialized)

### Storage Service Methods
```dart
- saveTasks(List<Task> tasks)
- getTasks() -> List<Task>
- addTask(Task task)
- updateTask(Task task)
- deleteTask(String taskId)
- clearTasks()
- setLoginState(bool isLoggedIn)
- saveUserData(String email, String userName)
- logout()
```

## 🎯 Models

### Task Model
```dart
class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate;
}
```

### Notification Model
```dart
class NotificationModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final DateTime createdAt;
  bool isRead;
}
```

## 🔧 Customization

### Change Primary Color
Edit `lib/utils/constants.dart`:
```dart
static const Color primary = Color(0xFF59A9AE); // Change this
```

### Modify Text Styles
Edit `lib/utils/constants.dart` - `AppTextStyles` class

### Add New Screens
1. Create `new_screen.dart` in `lib/screens/`
2. Add route to `main.dart`
3. Implement navigation

## 🛠️ Development Tips

### Hot Reload
Works during development for quick UI changes

### Hot Restart
Use for state management changes or new dependencies

### Debug Commands
```bash
# Check project structure
flutter analyze

# Format code
dart format lib/

# Run tests
flutter test
```

## 🚦 Form Validation

The app includes built-in validators in `lib/utils/validators.dart`:
- **Email**: Valid email format
- **Password**: Minimum 6 characters
- **Task Title**: Minimum 3 characters

## 📱 Responsive Design

The app uses:
- `MediaQuery` for responsive sizing
- `SingleChildScrollView` for overflow handling
- `Expanded` and `Flexible` for flexible layouts
- Percentage-based sizing where applicable

## 🐛 Known Limitations

- Notifications are mocked (from `notification_model.dart`)
- Sign up functionality is placeholder
- Forgot password is placeholder
- No backend integration (uses local storage only)

## 📚 Code Standards

- **Naming**: camelCase for variables/methods, PascalCase for classes
- **Comments**: Clear comments for complex logic
- **Null Safety**: All variables properly null-checked
- **Constants**: All magic numbers in constants.dart
- **Reusability**: Widgets are modular and reusable

## 🤝 Contributing

1. Follow the existing code structure
2. Add comments for complex logic
3. Test on multiple screen sizes
4. Update documentation

## 📄 License

MIT License - feel free to use this project

## 👨‍💻 Author

Created as a learning project for advanced Flutter mobile development.

---

**Happy Coding! 🚀**
