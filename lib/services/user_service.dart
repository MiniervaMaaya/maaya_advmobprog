import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

/// Handles remote authentication, current-user persistence, and user cart reads.
class UserService extends ChangeNotifier {
  static const String _baseUrl = AppEnvironment.apiBaseUrl;
  static const String _demoUsername = 'cham maaya';
  static const String _demoPassword = 'cham 12345';
  static const String _userKey = 'lab4_user';
  static const String _tokenKey = 'lab4_access_token';
  static const String _authenticatedKey = 'lab4_is_authenticated';

  final http.Client _client;
  final firebase_auth.FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;
  late SharedPreferences _preferences;
  User? _currentUser;

  UserService({
    http.Client? client,
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : this._(client ?? http.Client(), firebaseAuth, firestore);

  UserService._(this._client, this._firebaseAuth, this._firestore);

  User? get currentUser => _currentUser;
  bool get firebaseAvailable => _firebaseAuth != null && _firestore != null;

  bool get isAuthenticated =>
      _preferences.getBool(_authenticatedKey) == true && _currentUser != null;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();

    final firebaseUser = _firebaseAuth?.currentUser;
    if (firebaseUser != null && _firestore != null) {
      final user = await _readFirebaseUser(firebaseUser);
      await _saveSession(user, await firebaseUser.getIdToken() ?? '');
      return;
    }

    final savedUser = _preferences.getString(_userKey);
    if (savedUser != null) {
      try {
        _currentUser = User.fromJson(
          jsonDecode(savedUser) as Map<String, dynamic>,
        );
      } on FormatException {
        await signOut();
      }
    }
  }

  // Enhancement 2: authenticate through the API and persist only the returned session data.
  Future<User> signIn({
    required String username,
    required String password,
  }) async {
    if (username.trim().toLowerCase() == _demoUsername &&
        password.trim() == _demoPassword) {
      const user = User(
        id: 1,
        loginType: LoginType.localDemo,
        username: _demoUsername,
        email: 'cham.maaya@example.com',
        firstName: 'Cham',
        lastName: 'Maaya',
      );
      await _saveSession(user, 'local-demo-session');
      return user;
    }

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UserServiceException(
        payload['message'] as String? ??
            'Unable to sign in. Check your details.',
      );
    }

    final user = User.fromJson(
      payload,
    ).copyWith(loginType: LoginType.dummyJson);
    final token = payload['accessToken'] as String? ?? '';
    await _saveSession(user, token);
    return user;
  }

  Future<User> signInWithFirebase({
    required String email,
    required String password,
  }) async {
    _requireFirebase();
    try {
      final credential = await _firebaseAuth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const UserServiceException('Firebase did not return a user.');
      }
      final user = await _readFirebaseUser(firebaseUser);
      await _saveSession(user, await firebaseUser.getIdToken() ?? '');
      return user;
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw UserServiceException(_authErrorMessage(error));
    }
  }

  Future<User> createAccount({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
    required String email,
    required String password,
  }) async {
    _requireFirebase();
    try {
      final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const UserServiceException('Firebase did not create a user.');
      }

      await firebaseUser.updateDisplayName('$firstName $lastName'.trim());
      final user = User(
        id: _stableCartId(firebaseUser.uid),
        authUid: firebaseUser.uid,
        loginType: LoginType.firebase,
        username: username.trim(),
        email: firebaseUser.email ?? email.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        age: age,
        contactNo: contactNo.trim(),
      );
      await _firestore!
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toJson());
      await _saveSession(user, await firebaseUser.getIdToken() ?? '');
      return user;
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw UserServiceException(_authErrorMessage(error));
    } on FirebaseException catch (error) {
      throw UserServiceException(
        error.message ?? 'Unable to save the profile.',
      );
    }
  }

  Future<User?> getUserData() async {
    final current = _currentUser;
    if (current == null) return null;
    if (current.loginType != LoginType.firebase ||
        _firebaseAuth?.currentUser == null) {
      return current;
    }

    final firebaseUser = _firebaseAuth!.currentUser!;
    final user = await _readFirebaseUser(firebaseUser);
    await _saveSession(user, await firebaseUser.getIdToken() ?? '');
    return user;
  }

  Future<User> updateUsername(String username) async {
    final current = _currentUser;
    if (current == null) {
      throw const UserServiceException(
        'Sign in before updating your username.',
      );
    }
    final updatedUser = current.copyWith(username: username.trim());

    if (current.loginType == LoginType.firebase) {
      _requireFirebase();
      final firebaseUser = _firebaseAuth!.currentUser;
      if (firebaseUser == null || current.authUid == null) {
        throw const UserServiceException('Your Firebase session has expired.');
      }
      try {
        await _firestore!.collection('users').doc(current.authUid).update({
          'username': username.trim(),
        });
        await firebaseUser.updateDisplayName(
          '${current.firstName} ${current.lastName}'.trim(),
        );
        await _saveSession(updatedUser, await firebaseUser.getIdToken() ?? '');
        return updatedUser;
      } on FirebaseException catch (error) {
        throw UserServiceException(
          error.message ?? 'Unable to update username.',
        );
      }
    }

    if (current.loginType == LoginType.dummyJson) {
      final response = await _client
          .put(
            Uri.parse('$_baseUrl/users/${current.id}'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username.trim()}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const UserServiceException('Unable to update username.');
      }
    }

    await _saveSession(updatedUser, _preferences.getString(_tokenKey) ?? '');
    return updatedUser;
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final current = _currentUser;
    if (current?.loginType != LoginType.firebase || current?.authUid == null) {
      throw const UserServiceException(
        'Password changes are available for Firebase accounts.',
      );
    }
    _requireFirebase();
    final firebaseUser = _firebaseAuth!.currentUser;
    final email = firebaseUser?.email;
    if (firebaseUser == null || email == null) {
      throw const UserServiceException('Your Firebase session has expired.');
    }
    try {
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(credential);
      await firebaseUser.updatePassword(newPassword);
      await _saveSession(current!, await firebaseUser.getIdToken() ?? '');
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw UserServiceException(_authErrorMessage(error));
    }
  }

  Future<void> deleteAccount({required String currentPassword}) async {
    final current = _currentUser;
    if (current?.loginType != LoginType.firebase || current?.authUid == null) {
      throw const UserServiceException(
        'Account deletion is available for Firebase accounts.',
      );
    }
    _requireFirebase();
    final firebaseUser = _firebaseAuth!.currentUser;
    final email = firebaseUser?.email;
    if (firebaseUser == null || email == null) {
      throw const UserServiceException('Your Firebase session has expired.');
    }
    try {
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(credential);
      await _firestore!.collection('users').doc(current!.authUid).delete();
      await firebaseUser.delete();
      await _clearSavedSession();
    } on firebase_auth.FirebaseAuthException catch (error) {
      throw UserServiceException(_authErrorMessage(error));
    } on FirebaseException catch (error) {
      throw UserServiceException(error.message ?? 'Unable to delete account.');
    }
  }

  Future<String> refreshFirebaseToken() async {
    _requireFirebase();
    final token = await _firebaseAuth!.currentUser?.getIdToken(true);
    if (token == null) {
      throw const UserServiceException('Your Firebase session has expired.');
    }
    return token;
  }

  Future<User> _readFirebaseUser(firebase_auth.User firebaseUser) async {
    final uid = firebaseUser.uid;
    Map<String, dynamic> data = const {};
    try {
      final snapshot = await _firestore!.collection('users').doc(uid).get();
      data = snapshot.data() ?? const {};
    } on FirebaseException {
      // Keep Firebase Authentication usable while Firestore rules are configured.
    }
    final fallbackName = (firebaseUser.displayName ?? '').split(' ');
    return User(
      id: (data['id'] as num?)?.toInt() ?? _stableCartId(uid),
      authUid: uid,
      loginType: LoginType.firebase,
      username: data['username'] as String? ?? firebaseUser.email ?? '',
      email: firebaseUser.email ?? data['email'] as String? ?? '',
      firstName:
          data['firstName'] as String? ??
          (fallbackName.isEmpty ? '' : fallbackName.first),
      lastName:
          data['lastName'] as String? ??
          (fallbackName.length > 1 ? fallbackName.skip(1).join(' ') : ''),
      age: (data['age'] as num?)?.toInt(),
      contactNo: data['contactNo'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      image: firebaseUser.photoURL ?? data['image'] as String? ?? '',
    );
  }

  int _stableCartId(String uid) {
    var hash = 0x811c9dc5;
    for (final codeUnit in uid.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  void _requireFirebase() {
    if (!firebaseAvailable) {
      throw const UserServiceException(
        'Firebase is not configured. Run flutterfire configure and provide the Firebase options.',
      );
    }
  }

  String _authErrorMessage(firebase_auth.FirebaseAuthException error) {
    if (error.code == 'configuration-not-found' ||
        error.message?.contains('CONFIGURATION_NOT_FOUND') == true) {
      return 'Firebase Email/Password sign-in is not enabled for this project. '
          'Enable it in Firebase Console under Authentication > Sign-in method.';
    }

    return switch (error.code) {
      'email-already-in-use' => 'An account already exists for this email.',
      'invalid-email' => 'Enter a valid email address.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'The email or password is incorrect.',
      'weak-password' => 'Choose a stronger password.',
      'requires-recent-login' => 'Sign in again before completing this action.',
      'network-request-failed' => 'Check your internet connection and retry.',
      _ => error.message ?? 'Firebase authentication failed.',
    };
  }

  Future<void> _saveSession(User user, String token) async {
    await _preferences.setString(_userKey, jsonEncode(user.toJson()));
    if (user.loginType == LoginType.firebase) {
      await _preferences.remove(_tokenKey);
    } else {
      await _preferences.setString(_tokenKey, token);
    }
    await _preferences.setBool(_authenticatedKey, true);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      if (_currentUser?.loginType == LoginType.firebase) {
        final uid = _currentUser?.authUid;
        if (uid != null && _firestore != null) {
          try {
            await _firestore.collection('users').doc(uid).set({
              'isOnline': false,
              'lastSeen': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } on FirebaseException {
            // Signing out must still succeed if presence cannot be updated.
          }
        }
        await _firebaseAuth?.signOut();
      }
    } finally {
      await _clearSavedSession();
    }
  }

  Future<void> _clearSavedSession() async {
    await _preferences.remove(_userKey);
    await _preferences.remove(_tokenKey);
    await _preferences.setBool(_authenticatedKey, false);
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}

class UserServiceException implements Exception {
  final String message;

  const UserServiceException(this.message);

  @override
  String toString() => message;
}
