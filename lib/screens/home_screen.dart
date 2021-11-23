import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:itzbill/models/pool.dart';
import 'package:itzbill/models/rate.dart';

import 'package:itzbill/providers/auth_provider.dart';
import 'package:itzbill/services/database_service.dart';
import 'package:itzbill/screens/pool_screen.dart';

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
    try {
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
                          activeColor: Theme.of(context).primaryColor,
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
                          activeColor: Theme.of(context).primaryColor,
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
        Pool pool = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PoolScreen(
              currency: currency,
              name: name,
            ),
          ),
        );
        if (pool != null) {
          setState(() {
            pools.add(pool);
          });
        }
      }
    } on Error catch (e) {}
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

    fToast.init(context);
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

  Future<void> _deletePool(String poolId) async {
    _startLoading();
    try {
      await _databaseService.deletePool(poolId);
      _stopLoading();
      _showToast('Eliminado con exito');
      Navigator.of(context).pop(true);
    } on Error catch (e) {
      print(e.toString());
      _stopLoading();
      _showToast('Error al eliminar, intente nuevamente', true);
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
    Color color = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cartera de Letras de Cambio',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 100.0,
        width: 100.0,
        child: FittedBox(
          child: FloatingActionButton(
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(Icons.add),
            onPressed: _createPool,
          ),
        ),
      ),
      body: pools.length > 0
          ? ListView.builder(
              itemCount: pools.length,
              itemBuilder: (context, index) {
                final e = pools[index];
                return Dismissible(
                  key: Key(e.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (DismissDirection direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Eliminar cartera"),
                          content: const Text(
                              "¿Estas seguro que deseas eliminar esta cartera?"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Cancelar"),
                            ),
                            TextButton(
                                onPressed: () => _deletePool(e.id),
                                child: const Text("Eliminar")),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) async {
                    setState(() {
                      pools.removeAt(index);
                    });
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 480.0),
                    child: Icon(Icons.delete, size: 100),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.only(bottom: 32.0, left: 64.0, right: 64.0),
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
                              Divider(
                                height: 1.0,
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Column(
                                      children: [
                                        ListTile(
                                          leading: Icon(
                                            Icons.calendar_today,
                                            color: color,
                                          ),
                                          title: Text(
                                              e.rate.daysPerYear.toString()),
                                          subtitle: Text('Dias por año'),
                                        ),
                                        ListTile(
                                          leading: Text(
                                            '%',
                                            style: TextStyle(
                                              fontSize: 20.0,
                                              color: color,
                                            ),
                                          ),
                                          title: Text(
                                              '${(e.rate.value * 100).toStringAsFixed(7)} %'),
                                          subtitle: Text('Tasa ${e.rate.type}'),
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.date_range,
                                            color: color,
                                          ),
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
                                          leading: Icon(
                                            Icons.attach_money,
                                            color: color,
                                          ),
                                          title: Text(e.currency),
                                          subtitle: Text('Moneda'),
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.money,
                                            color: color,
                                          ),
                                          title: Text(e.receivedTotal
                                              .toStringAsFixed(2)),
                                          subtitle:
                                              Text('Valor Total a Recibir'),
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.today,
                                            color: color,
                                          ),
                                          title: Text(
                                              '${e.discountDate.day}/${e.discountDate.month}/${e.discountDate.year}'),
                                          subtitle: Text('Fecha de Descuento'),
                                        ),
                                        ListTile(
                                          leading: Text(
                                            "TCEA",
                                            style: TextStyle(
                                              color: color,
                                            ),
                                          ),
                                          title: Text(
                                              '${(e.tcea * 100).toStringAsFixed(7)} %'),
                                          subtitle: Text(
                                              'Tasa de Coste Efectiva Anual'),
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
                  ),
                );
              },
            )
          : Container(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/noresult.png',
                    scale: 2,
                  ),
                  SizedBox(height: 32.0),
                  Text(
                    'Cartera de Letras de Cambio vacia',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 28.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    "Crea una tocando el botón de círculo '+' de abajo.",
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCapitalizationDays(Rate rate) {
    return rate.type == "Nominal"
        ? ListTile(
            leading: Icon(
              Icons.date_range,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
                '${rateMap.keys.firstWhere((k) => rateMap[k] == rate.capitalizationDays)} (${rate.capitalizationDays} dia${rate.capitalizationDays > 1 ? 's' : ''})'),
            subtitle: Text('Periodo de Capitalizacion'),
          )
        : SizedBox(height: 0.0);
  }
}
