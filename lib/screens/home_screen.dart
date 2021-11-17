import 'package:flutter/material.dart';
import 'package:itzbill/models/pool.dart';
import 'package:itzbill/models/rate.dart';
import 'package:itzbill/screens/pool_screen.dart';
import 'package:itzbill/widgets/button_widget.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:itzbill/providers/auth_provider.dart';
import 'package:itzbill/widgets/header_button_widget.dart';
import 'package:itzbill/widgets/toast_widget.dart';
import 'package:itzbill/widgets/loading_widget.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FToast fToast = FToast();
  AuthProvider? auth;

  bool loading = false;

  Currency _currency = Currency.Soles;

  Future<void> _createPool() async {
    bool create = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              content: Container(
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ListTile(
                      title: const Text('Soles'),
                      leading: Radio<Currency>(
                        value: Currency.Soles,
                        groupValue: _currency,
                        onChanged: (Currency? value) {
                          setState(() {
                            _currency = value!;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Dolares'),
                      leading: Radio<Currency>(
                        value: Currency.Dollars,
                        groupValue: _currency,
                        onChanged: (Currency? value) {
                          setState(() {
                            _currency = value!;
                          });
                        },
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text("Crear"),
                ),
              ],
            );
          },
        );
      },
    );

    if (create) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PoolScreen(currency: _currency)),
      );
    }
  }

  _startLoading() {
    loading = true;
    fToast.removeQueuedCustomToasts();
    Widget toast = LoadingWidget();
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 60),
    );
  }

  _stopLoading() {
    fToast.removeQueuedCustomToasts();
    loading = false;
  }

  _showToast(String message, [bool error = false]) {
    Widget toast = ToastWidget(message: message, error: error);
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 2),
    );
  }

  Future<void> _logout() async {
    if (loading) return;

    _startLoading();

    try {
      AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.signOut();
      _stopLoading();
      _showToast("Logout successful");
    } on FirebaseAuthException catch (e) {
      _stopLoading();
      _showToast(e.message.toString(), true);
    } on Error catch (e) {
      _stopLoading();
      _showToast(e.toString(), true);
    }
  }

  @override
  void initState() {
    super.initState();
    loading = false;
    auth = Provider.of<AuthProvider>(context, listen: false);
    fToast.init(context);
  }

  @override
  void dispose() {
    super.dispose();
    loading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.0,
        //title: LogoWidget(fontSize: 48, alternative: true),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          HeaderButton(
            title: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(64.0),
        child: Column(
          children: [
            InkWell(
              onTap: () {},
              child: Card(
                child: Container(
                  height: 100,
                  width: double.infinity,
                  child: Column(
                    children: [],
                  ),
                ),
              ),
            ),
            ButtonWidget(text: 'Crear nueva cartera', onPressed: _createPool),
          ],
        ),
      ),
    );
  }
}
