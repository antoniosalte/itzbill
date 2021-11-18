import 'package:flutter/material.dart';
import 'package:itzbill/models/pool.dart';
import 'package:itzbill/models/rate.dart';
import 'package:itzbill/screens/pool_screen.dart';
import 'package:itzbill/widgets/button_widget.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:itzbill/providers/auth_provider.dart';
import 'package:itzbill/services/database_service.dart';

import 'package:itzbill/widgets/header_button_widget.dart';
import 'package:itzbill/widgets/toast_widget.dart';
import 'package:itzbill/widgets/loading_widget.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DatabaseService _databaseService = DatabaseService();
  FToast fToast = FToast();
  AuthProvider? auth;

  bool loading = false;

  String currency = "Soles";

  List<Pool> pools = [];

  void _loadPool(Pool pool) async {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PoolScreen(currency: currency, pool: pool)),
    );
  }

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
                      leading: Radio<String>(
                        value: "Soles",
                        groupValue: currency,
                        onChanged: (String? value) {
                          setState(() {
                            currency = value!;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Dolares'),
                      leading: Radio<String>(
                        value: "Dolares",
                        groupValue: currency,
                        onChanged: (String? value) {
                          setState(() {
                            currency = value!;
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
        MaterialPageRoute(builder: (context) => PoolScreen(currency: currency)),
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

  Future<void> loadPools() async {
    try {
      List<Pool> loadedPools = await _databaseService.loadPools(auth!.uid);
      _stopLoading();
      setState(() {
        pools = loadedPools;
      });
      _showToast('Cargado con exito');
    } on Error catch (e) {
      print(e.toString());
      _stopLoading();
      _showToast('Error al cargar, actualice la pagina', true);
    }
  }

  @override
  void initState() {
    super.initState();
    loading = true;
    auth = Provider.of<AuthProvider>(context, listen: false);
    fToast.init(context);
    loadPools();
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
            ...pools.map((e) {
              return InkWell(
                onTap: () => _loadPool(e),
                child: Card(
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    child: Column(
                      children: [
                        Text(e.id),
                        Text(e.currency),
                        Text(e.rate.type),
                        Text(e.rate.value.toString()),
                        Text(e.tcea.toString()),
                        Text(e.receivedTotal.toString()),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            ButtonWidget(text: 'Crear nueva cartera', onPressed: _createPool),
          ],
        ),
      ),
    );
  }
}
