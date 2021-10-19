import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  User? user;
  StreamSubscription? userSubscription;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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

  String get uid {
    return user!.uid;
  }

  Future<void> registerUser(String email, String password) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> login(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
