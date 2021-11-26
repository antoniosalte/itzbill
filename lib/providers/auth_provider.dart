import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  User? user;
  StreamSubscription? userSubscription;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? _displayName;

  bool _isRegister = false;

  AuthProvider() {
    userSubscription = _firebaseAuth.authStateChanges().listen((User? newUser) {
      print('[AuthProvider][FirebaseAuth] authStateChanges $newUser');
      user = newUser;
      notifyListeners();
    }, onError: (error) {
      print('[AuthProvider][FirebaseAuth] authStateChanges $error');
    });
  }

  @override
  void dispose() {
    if (userSubscription != null) {
      userSubscription?.cancel();
      userSubscription = null;
    }
    super.dispose();
  }

  bool get isAuthenticated {
    return user != null;
  }

  bool get isRegister {
    return _isRegister;
  }

  String get uid {
    return user!.uid;
  }

  String get displayName {
    return user!.displayName ?? _displayName!;
  }

  Future<void> registerUser(
      String email, String password, String ruc, String name) async {
    _isRegister = true;
    _displayName = '$ruc/$name';
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> updateDisplayName() async {
    await user!.updateDisplayName(_displayName);
    _isRegister = false;
  }

  Future<void> login(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
