import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:itzbill/models/pool.dart';
import 'package:itzbill/models/rate.dart';

import 'package:itzbill/providers/auth_provider.dart';
import 'package:itzbill/services/database_service.dart';
import 'package:itzbill/screens/pool_screen.dart';

import 'package:itzbill/widgets/header_button_widget.dart';
import 'package:itzbill/widgets/toast_widget.dart';
import 'package:itzbill/widgets/loading_widget.dart';
import 'package:itzbill/widgets/button_widget.dart';

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
  String name = "";

  Map<String, int> rateMap = {
    "Anual": 360,
    "Semestral": 180,
    "Cuatrimestral": 120,
    "Trimestral": 90,
    "Bimestral": 60,
    "Mensual": 30,
    "Quincenal": 15,
    "Diario": 1
  };

  List<Pool> pools = [];

  void _loadPool(Pool pool) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PoolScreen(
          currency: pool.currency,
          name: pool.name,
          pool: pool,
        ),
      ),
    );
  }

  Future<void> _createPool() async {
    name = "";

    bool create = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Crear nueva cartera'),
              content: Container(
                height: 150,
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
                    ),
                    TextField(
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Nombre de la cartera',
                      ),
                      style: TextStyle(
                        fontSize: 16.0,
                        height: 1.0,
                      ),
                      onChanged: ((value) => {
                            setState(() {
                              name = value;
                            })
                          }),
                    ),
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
          builder: (context) => PoolScreen(
            currency: currency,
            name: name,
          ),
        ),
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
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 64.0),
        child: Column(
          children: [
            ...pools.map((e) {
              return Padding(
                padding: EdgeInsets.only(bottom: 32.0),
                child: InkWell(
                  onTap: () => _loadPool(e),
                  child: Card(
                    child: Container(
                      height: 325,
                      width: double.infinity,
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              e.name == "" ? "Cartera de Letra" : e.name,
                              style: TextStyle(
                                fontSize: 22.0,
                              ),
                            ),
                            // subtitle: Text('Tasa ${e.rate.type}'),
                          ),
                          Divider(height: 1.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.calendar_today),
                                      title:
                                          Text(e.rate.daysPerYear.toString()),
                                      subtitle: Text('Dias por año'),
                                    ),
                                    ListTile(
                                      leading: Text(
                                        '%',
                                        style: TextStyle(fontSize: 20.0),
                                      ),
                                      title: Text(
                                          '${(e.rate.value * 100).toStringAsFixed(7)} %'),
                                      subtitle: Text('Tasa ${e.rate.type}'),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.date_range),
                                      title: Text(
                                          '${rateMap.keys.firstWhere((k) => rateMap[k] == e.rate.termDays)} (${e.rate.termDays} dia${e.rate.termDays > 1 ? 's' : ''})'),
                                      subtitle: Text('Plazo de Tasa'),
                                    ),
                                    _buildCapitalizationDays(e.rate),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.attach_money),
                                      title: Text(e.currency),
                                      subtitle: Text('Moneda'),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.money),
                                      title: Text(
                                          e.receivedTotal.toStringAsFixed(2)),
                                      subtitle: Text('Valor Total a Recibir'),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.today),
                                      title: Text(
                                          '${e.discountDate.day}/${e.discountDate.month}/${e.discountDate.year}'),
                                      subtitle: Text('Fecha de Descuento'),
                                    ),
                                    ListTile(
                                      leading: Text("TCEA"),
                                      title: Text(
                                          '${(e.tcea * 100).toStringAsFixed(7)} %'),
                                      subtitle:
                                          Text('Tasa de Coste Efectiva Anual'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildCapitalizationDays(Rate rate) {
    return rate.type == "Nominal"
        ? ListTile(
            leading: Icon(Icons.date_range),
            title: Text(
                '${rateMap.keys.firstWhere((k) => rateMap[k] == rate.capitalizationDays)} (${rate.capitalizationDays} dia${rate.capitalizationDays > 1 ? 's' : ''})'),
            subtitle: Text('Plazo de Tasa'),
          )
        : SizedBox(height: 0.0);
  }
}
