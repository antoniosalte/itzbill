import 'package:flutter/material.dart';
import 'package:itzbill/models/pool.dart';
import 'package:itzbill/screens/pool_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'config/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp();

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'itzbill',
        theme: MainTheme().theme,
        home: FutureBuilder(
          future: _initialization,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SomethingWentWrong();
            }
            if (snapshot.connectionState == ConnectionState.done) {
              return AuthManager(title: 'itzbill');
            }
            return Loading();
          },
        ),
      ),
    );
  }
}

class AuthManager extends StatelessWidget {
  AuthManager({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider =
        Provider.of<AuthProvider>(context, listen: true);

    if (authProvider.isAuthenticated) {
      //return PoolScreen(currency: "Soles");
      return HomeScreen();
    } else {
      return AuthScreen();
    }
  }
}

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class SomethingWentWrong extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Text('Error'),
    ));
  }
}
