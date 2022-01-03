import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:itzbill/models/rate.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:itzbill/providers/auth_provider.dart';
import 'package:itzbill/services/database_service.dart';
import 'package:itzbill/services/decimal_service.dart';
import 'package:itzbill/models/pool.dart';
import 'package:itzbill/models/expense.dart';
import 'package:itzbill/models/bill.dart';

import 'package:itzbill/widgets/label_widget.dart';
import 'package:itzbill/widgets/loading_widget.dart';
import 'package:itzbill/widgets/toast_widget.dart';
import 'package:itzbill/widgets/button_widget.dart';

import 'dart:js' as js;

class PoolScreen extends StatefulWidget {
  PoolScreen({Key? key, required this.currency, required this.name, this.pool})
      : super(key: key);

  final String currency;
  final String name;
  Pool? pool;

  @override
  PoolScreenState createState() => PoolScreenState();
}

class PoolScreenState extends State<PoolScreen> {
  DatabaseService _databaseService = DatabaseService();
  FToast fToast = FToast();
  AuthProvider? auth;

  Pool? pool;
  List<Bill> bills = [];

  double valueReceivedTotal = 0.0;
  double tcea = 0.0;

  bool loading = false;
  bool locked = false;

  String name = "";
  String daysPerYear = "360";
  String rateTerm = "Anual";
  String rateType = "Efectiva";
  String rateCapitalization = "Diario";
  String? rateValue;
  String? nominalValue;
  String? retentionValue;

  TextEditingController rateValueController = TextEditingController();
  TextEditingController nominalValueController = TextEditingController();
  TextEditingController retentionValueController = TextEditingController();

  int rateTermDays = 360;
  int rateCapitalizationDays = 1;

  DateTime? discountDate;
  DateTime? turnDate;
  DateTime? dueDate;

  String initialReason = "Portes";
  String initialValueType = "En Efectivo";
  String? initialValue;

  String finalReason = "Portes";
  String finalValueType = "En Efectivo";
  String? finalValue;

  List<Expense> initialExpenses = [];
  List<Expense> finalExpenses = [];

  List<String> daysPerYearOptions = [
    "360",
    "365",
  ];

  List<String> rateTerms = [
    "Anual",
    "Semestral",
    "Cuatrimestral",
    "Trimestral",
    "Bimestral",
    "Mensual",
    "Quincenal",
    "Diario"
  ];

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

  List<String> rateTypes = [
    "Efectiva",
    "Nominal",
  ];

  List<String> initialReasons = [
    "Portes",
    "Fotocopias",
    "Comision de estudio",
    "Comision de desembolso",
    "Comision de intermediacion",
    "Gastos de administracion",
    "Gastos notariales",
    "Gastos registrales",
    "Seguro",
    "Otros gastos"
  ];

  List<String> finalReasons = [
    "Portes",
    "Gastos de administracion",
    "Otros gastos"
  ];

  List<String> valueTypes = ["En Efectivo", "En Porcentaje"];

  String getDateText(DateTime? date) {
    if (date == null) {
      return 'Selecciona una fecha';
    } else {
      return DateFormat('MM/dd/yyyy').format(date);
    }
  }

  Future pickDiscountDate() async {
    final initialDate = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: discountDate ?? initialDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (newDate == null) return;

    setState(() => discountDate = newDate);

    if (dueDate != null && discountDate != null) {
      if (dueDate!.compareTo(discountDate!) <= 0) {
        setState(() => dueDate = discountDate!.add(Duration(days: 1)));
      }
    }
  }

  Future pickTurnDate() async {
    final initialDate = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: turnDate ?? initialDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (newDate == null) return;

    setState(() => turnDate = newDate);
  }

  Future pickDueDate() async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(DateTime.now().year - 5);

    if (dueDate != null && discountDate != null) {
      if (dueDate!.compareTo(discountDate!) <= 0) {
        setState(() => dueDate = discountDate!.add(Duration(days: 1)));
      }
    }

    if (discountDate != null) {
      firstDate = discountDate!.add(Duration(days: 1));
      initialDate = firstDate;
    }

    final newDate = await showDatePicker(
      context: context,
      initialDate: dueDate ?? initialDate,
      firstDate: firstDate,
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (newDate == null) return;

    setState(() => dueDate = newDate);
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

  Future<void> _loadPool() async {
    name = pool!.name;
    Rate rate = pool!.rate;
    rateType = rate.type;
    daysPerYear = rate.daysPerYear.toString();
    rateValue = (rate.value * 100).toStringAsFixed(7);
    rateValueController.text = rateValue!;
    rateTerm = rateMap.keys.firstWhere((k) => rateMap[k] == rate.termDays);
    rateTermDays = rate.termDays;
    if (rate.type == "Nominal") {
      rateCapitalization =
          rateMap.keys.firstWhere((k) => rateMap[k] == rate.capitalizationDays);
      rateCapitalizationDays = rate.capitalizationDays;
    }
    discountDate = pool!.discountDate;

    initialExpenses = pool!.initialExpenses;
    finalExpenses = pool!.finalExpenses;

    List<Bill> loadedBills = await _databaseService.loadBills(pool!.id);
    for (Bill bill in loadedBills) {
      valueReceivedTotal += bill.valueReceived;
    }
    bills = loadedBills;

    double tceaValue = _calculateXIRR();
    setState(() {
      locked = true;
      tcea = tceaValue;
    });
  }

  Future<void> _addBill() async {
    if (loading) return;

    _startLoading();

    if (rateValue == null || rateValue == '') {
      _stopLoading();
      _showToast('Agregue una "Tasa $rateType"', true);
      return;
    }

    if (discountDate == null || discountDate == '') {
      _stopLoading();
      _showToast('Seleccione una "Fecha de Descuento"', true);
      return;
    }

    if (turnDate == null || turnDate == '') {
      _stopLoading();
      _showToast('Seleccione una "Fecha de Giro"', true);
      return;
    }

    if (dueDate == null || dueDate == '') {
      _stopLoading();
      _showToast('Seleccione una "Fecha de Vencimiento"', true);
      return;
    }

    if (nominalValue == null || nominalValue == '') {
      _stopLoading();
      _showToast('Agregue un "Valor Nominal"', true);
      return;
    }

    if (!locked) {
      Rate rate = Rate.toPool(
        rateType,
        double.parse(rateValue!) / 100,
        int.parse(daysPerYear),
        rateTermDays,
        rateType == "Nominal" ? rateCapitalizationDays : -1,
      );

      try {
        pool = await _databaseService.createPool(
          auth!.uid,
          widget.name,
          discountDate!,
          rate,
          widget.currency,
          initialExpenses,
          finalExpenses,
        );

        _showToast('Cartera de Letras creada');
        setState(() {
          locked = true;
        });
      } on Error catch (e) {
        _stopLoading();
        _showToast('Error al agregar cartera de letras: $e', true);
      }
    }

    try {
      double retention = 0.0;
      if (retentionValue != null && retentionValue != '') {
        retention = double.parse(retentionValue!);
      }

      Bill bill = await _databaseService.createBill(
        pool!.id,
        pool!.userId,
        pool!.discountDate,
        turnDate!,
        dueDate!,
        double.parse(nominalValue!),
        retention,
        initialExpenses,
        finalExpenses,
        pool!.tea,
      );

      bills.add(bill);
      valueReceivedTotal += bill.valueReceived;

      double tceaValue = _calculateXIRR();
      if (tceaValue == -1) {
        await _databaseService.deletePool(pool!.id);
        bills.remove(bill);
        valueReceivedTotal -= bill.valueReceived;
        locked = false;
        pool = null;
        _stopLoading();
        _showToast('Tasa invalida', true);
      } else {
        tcea = tceaValue;
        pool!.tcea = tcea.toDouble();
        pool!.receivedTotal = valueReceivedTotal;
        await _databaseService.updatePool(pool!.id, tcea, valueReceivedTotal);

        nominalValueController.text = "";
        retentionValueController.text = "";
        turnDate = null;
        dueDate = null;

        _stopLoading();
        _showToast('Letra agregada con éxito');
      }

      setState(() {});
    } on Error catch (e) {
      _stopLoading();
      _showToast('Error al agregar: $e', true);
    }
  }

  Future<void> _deleteBill(Bill bill) async {
    if (loading) return;

    _startLoading();

    try {
      await _databaseService.deleteBill(bill.id);
      setState(() {
        valueReceivedTotal -= bill.valueReceived;
        bills.remove(bill);
      });
      double tceaValue = _calculateXIRR();
      tcea = tceaValue;
      pool!.tcea = tcea.toDouble();
      pool!.receivedTotal = valueReceivedTotal;
      await _databaseService.updatePool(pool!.id, tcea, valueReceivedTotal);

      setState(() {});

      _stopLoading();
      _showToast("Eliminado con exito");
    } on Error catch (e) {
      _stopLoading();
      _showToast('Error al eliminar: $e', true);
    }
  }

  double _calculateXIRR() {
    if (bills.length >= 1) {
      js.JsArray dates = new js.JsArray();
      js.JsArray amounts = new js.JsArray();

      double sum = 0.0;
      for (Bill bill in bills) {
        DateTime dateTime = bill.dueDate;
        String date = "${dateTime.year}/${dateTime.month}/${dateTime.day}";
        amounts.add((-bill.valueDelivered).toString());
        sum += -bill.valueDelivered;
        dates.add(date);
      }

      DateTime a = pool!.discountDate;

      amounts.add(valueReceivedTotal);
      dates.add("${a.year}/${a.month}/${a.day}");

      js.context.callMethod('alertMessage', [dates, amounts]);
      var state = js.JsObject.fromBrowserObject(js.context['state']);
      return state['xirr'];
    } else {
      return 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    loading = false;
    auth = Provider.of<AuthProvider>(context, listen: false);
    fToast.init(context);
    pool = widget.pool;
    name = widget.name;
    if (pool != null) {
      _loadPool();
    }
  }

  @override
  void dispose() {
    super.dispose();
    loading = false;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double cardWidth = (width / 8) * 3;
    TextStyle cardTitleStyle = TextStyle(
      fontSize: 24,
      color: Theme.of(context).primaryColor,
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.0,
        leadingWidth: 100,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.of(context).pop(pool);
          },
        ),
        title: Text(
          '${name} (Letra de Cambio a Tasa $rateType)',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Card(
                  child: Container(
                    width: cardWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ListTile(
                          title: Text(
                            "Tasa y Plazo",
                            style: cardTitleStyle,
                          ),
                        ),
                        Divider(height: 1.0),
                        SizedBox(height: 16.0),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    LabelWidget(label: 'Dias por año'),
                                    Flexible(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                        child: Center(
                                          child: DropdownButton<String>(
                                            value: daysPerYear,
                                            underline: Container(
                                              height: 0,
                                            ),
                                            onChanged: locked
                                                ? null
                                                : (String? newValue) {
                                                    setState(() {
                                                      daysPerYear = newValue!;
                                                    });
                                                  },
                                            items: daysPerYearOptions
                                                .map<DropdownMenuItem<String>>(
                                                    (String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    LabelWidget(label: 'Plazo de Tasa'),
                                    Flexible(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey,
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                              child: Center(
                                                child: DropdownButton<String>(
                                                  value: rateTerm,
                                                  underline: Container(
                                                    height: 0,
                                                  ),
                                                  onChanged: locked
                                                      ? null
                                                      : (String? newValue) {
                                                          setState(() {
                                                            rateTerm =
                                                                newValue!;
                                                            rateTermDays =
                                                                rateMap[
                                                                    rateTerm]!;
                                                          });
                                                        },
                                                  items: rateTerms.map<
                                                          DropdownMenuItem<
                                                              String>>(
                                                      (String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 4.0),
                                          Flexible(
                                            child: Container(
                                              width: double.infinity,
                                              height: 50.0,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey,
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "$rateTermDays dia${rateTermDays > 1 ? 's' : ''}",
                                                  style: TextStyle(
                                                    color: locked
                                                        ? Colors.grey
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Row(
                                        children: [
                                          LabelWidget(label: 'Tasa'),
                                          SizedBox(width: 8.0),
                                          Flexible(
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey,
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                              child: Center(
                                                child: DropdownButton<String>(
                                                  value: rateType,
                                                  underline: Container(
                                                    height: 0,
                                                  ),
                                                  onChanged: locked
                                                      ? null
                                                      : (String? newValue) {
                                                          setState(() {
                                                            rateType =
                                                                newValue!;
                                                          });
                                                        },
                                                  items: rateTypes.map<
                                                          DropdownMenuItem<
                                                              String>>(
                                                      (String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: TextField(
                                              enabled: !locked,
                                              controller: rateValueController,
                                              keyboardType: TextInputType
                                                  .numberWithOptions(
                                                decimal: true,
                                              ),
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                              ),
                                              inputFormatters: [
                                                DecimalTextInputFormatter(
                                                  decimalRange: 7,
                                                  activatedNegativeValues:
                                                      false,
                                                )
                                              ],
                                              style: TextStyle(
                                                fontSize: 16.0,
                                                height: 1.0,
                                                color: locked
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                              onChanged: ((value) => {
                                                    setState(() {
                                                      rateValue = value;
                                                    })
                                                  }),
                                            ),
                                          ),
                                          SizedBox(width: 8.0),
                                          Text(
                                            "%",
                                            style: TextStyle(fontSize: 24.0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildRateCapitalization(),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    LabelWidget(label: 'Fecha de Descuento'),
                                    Flexible(
                                      child: Container(
                                        width: double.infinity,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                        child: Center(
                                          child: TextButton(
                                            child: Text(
                                              getDateText(discountDate),
                                              style: TextStyle(
                                                color: locked
                                                    ? Colors.grey
                                                    : Colors.black,
                                              ),
                                            ),
                                            onPressed: locked
                                                ? null
                                                : () => pickDiscountDate(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: cardWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ListTile(
                          title: Text(
                            "Datos de la Letra",
                            style: cardTitleStyle,
                          ),
                        ),
                        Divider(height: 1.0),
                        SizedBox(height: 16.0),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              _buildCapitalizationHelper(),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    LabelWidget(label: 'Fecha de Giro'),
                                    Flexible(
                                      child: Container(
                                        width: double.infinity,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                        child: Center(
                                          child: TextButton(
                                            child: Text(
                                              getDateText(turnDate),
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                            onPressed: () => pickTurnDate(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    LabelWidget(label: 'Fecha de Vencimiento'),
                                    Flexible(
                                      child: Container(
                                        width: double.infinity,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                        child: Center(
                                          child: TextButton(
                                            child: Text(
                                              getDateText(dueDate),
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                            onPressed: () => pickDueDate(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    LabelWidget(label: 'Valor Nominal'),
                                    Flexible(
                                      child: TextField(
                                        controller: nominalValueController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                        ),
                                        inputFormatters: [
                                          DecimalTextInputFormatter(
                                            decimalRange: 2,
                                            activatedNegativeValues: false,
                                          )
                                        ],
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          height: 1.0,
                                        ),
                                        onChanged: ((value) => {
                                              setState(() {
                                                nominalValue = value;
                                              })
                                            }),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    LabelWidget(label: 'Retencion'),
                                    Flexible(
                                      child: TextField(
                                        controller: retentionValueController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                        ),
                                        inputFormatters: [
                                          DecimalTextInputFormatter(
                                            decimalRange: 2,
                                            activatedNegativeValues: false,
                                          )
                                        ],
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          height: 1.0,
                                        ),
                                        onChanged: ((value) => {
                                              setState(() {
                                                retentionValue = value;
                                              })
                                            }),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Container(
                    width: cardWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ListTile(
                          title: Text(
                            "Costes / Gastos Iniciales",
                            style: cardTitleStyle,
                          ),
                        ),
                        Divider(height: 1.0),
                        SizedBox(height: 16.0),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    LabelWidget(label: 'Motivo'),
                                    Flexible(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                        child: Center(
                                          child: DropdownButton<String>(
                                            value: initialReason,
                                            underline: Container(
                                              height: 0,
                                            ),
                                            onChanged: locked
                                                ? null
                                                : (String? newValue) {
                                                    setState(() {
                                                      initialReason = newValue!;
                                                    });
                                                  },
                                            items: initialReasons
                                                .map<DropdownMenuItem<String>>(
                                                    (String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    LabelWidget(label: 'Valor expresado en'),
                                    Flexible(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey,
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                              child: Center(
                                                child: DropdownButton<String>(
                                                  value: initialValueType,
                                                  underline: Container(
                                                    height: 0,
                                                  ),
                                                  onChanged: locked
                                                      ? null
                                                      : (String? newValue) {
                                                          setState(() {
                                                            initialValueType =
                                                                newValue!;
                                                          });
                                                        },
                                                  items: valueTypes.map<
                                                          DropdownMenuItem<
                                                              String>>(
                                                      (String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 4.0),
                                          Flexible(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: TextField(
                                                    enabled: !locked,
                                                    keyboardType: TextInputType
                                                        .numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                    decoration: InputDecoration(
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                    inputFormatters: [
                                                      DecimalTextInputFormatter(
                                                        decimalRange: 2,
                                                        activatedNegativeValues:
                                                            false,
                                                      ),
                                                    ],
                                                    style: TextStyle(
                                                      fontSize: 16.0,
                                                      height: 1.0,
                                                      color: locked
                                                          ? Colors.grey
                                                          : Colors.black,
                                                    ),
                                                    onChanged: ((value) => {
                                                          setState(() {
                                                            initialValue =
                                                                value;
                                                          })
                                                        }),
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: initialValueType ==
                                                            "En Efectivo"
                                                        ? 0.0
                                                        : 8.0),
                                                Text(
                                                  initialValueType ==
                                                          "En Efectivo"
                                                      ? ""
                                                      : "%",
                                                  style:
                                                      TextStyle(fontSize: 24.0),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8.0),
                              ButtonWidget(
                                text: "Agregar",
                                onPressed: locked
                                    ? null
                                    : () {
                                        if (initialReason != '') {
                                          setState(() {
                                            double value =
                                                double.parse(initialValue!);
                                            if (initialValueType ==
                                                "En Porcentaje") {
                                              value /= 100;
                                            }
                                            initialExpenses.add(
                                              Expense.fromMenu(
                                                "Initial",
                                                initialReason,
                                                initialValueType,
                                                value,
                                              ),
                                            );
                                            initialReasons
                                                .remove(initialReason);
                                            initialReason =
                                                initialReasons.length > 0
                                                    ? initialReasons[0]
                                                    : '';
                                          });
                                        }
                                      },
                              ),
                              Container(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    dataTextStyle: TextStyle(
                                      color:
                                          locked ? Colors.grey : Colors.black,
                                    ),
                                    columns: [
                                      DataColumn(label: Text('Index')),
                                      DataColumn(label: Text('Motivo')),
                                      DataColumn(label: Text('Tipo')),
                                      DataColumn(label: Text('Valor')),
                                      DataColumn(label: Text('Acciones')),
                                    ],
                                    rows: initialExpenses.map((e) {
                                      int index = initialExpenses.indexOf(e);
                                      String value = e.valueType ==
                                              "En Efectivo"
                                          ? "${e.value}"
                                          : "${(e.value * 100).toStringAsFixed(2)} %";
                                      return DataRow(cells: [
                                        DataCell(Text((index + 1).toString())),
                                        DataCell(Text(e.reason)),
                                        DataCell(Text(e.valueType)),
                                        DataCell(Text(value)),
                                        DataCell(
                                          IconButton(
                                            icon: Icon(Icons.delete),
                                            onPressed: locked
                                                ? null
                                                : () {
                                                    setState(() {
                                                      initialExpenses.remove(e);
                                                      initialReasons
                                                          .add(e.reason);
                                                      if (initialReason == '') {
                                                        initialReason =
                                                            initialReasons[0];
                                                      }
                                                    });
                                                  },
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: cardWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ListTile(
                          title: Text(
                            "Costes / Gastos Finales",
                            style: cardTitleStyle,
                          ),
                        ),
                        Divider(height: 1.0),
                        SizedBox(height: 16.0),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    LabelWidget(label: 'Motivo'),
                                    Flexible(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                        child: Center(
                                          child: DropdownButton<String>(
                                            value: finalReason,
                                            underline: Container(
                                              height: 0,
                                            ),
                                            onChanged: locked
                                                ? null
                                                : (String? newValue) {
                                                    setState(() {
                                                      finalReason = newValue!;
                                                    });
                                                  },
                                            items: finalReasons
                                                .map<DropdownMenuItem<String>>(
                                                    (String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    LabelWidget(label: 'Valor expresado en'),
                                    Flexible(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey,
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                              child: Center(
                                                child: DropdownButton<String>(
                                                  value: finalValueType,
                                                  underline: Container(
                                                    height: 0,
                                                  ),
                                                  onChanged: locked
                                                      ? null
                                                      : (String? newValue) {
                                                          setState(() {
                                                            finalValueType =
                                                                newValue!;
                                                          });
                                                        },
                                                  items: valueTypes.map<
                                                          DropdownMenuItem<
                                                              String>>(
                                                      (String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 4.0),
                                          Flexible(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: TextField(
                                                    enabled: !locked,
                                                    keyboardType: TextInputType
                                                        .numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                    decoration: InputDecoration(
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                    inputFormatters: [
                                                      DecimalTextInputFormatter(
                                                        decimalRange: 2,
                                                        activatedNegativeValues:
                                                            false,
                                                      )
                                                    ],
                                                    style: TextStyle(
                                                      fontSize: 16.0,
                                                      height: 1.0,
                                                      color: locked
                                                          ? Colors.grey
                                                          : Colors.black,
                                                    ),
                                                    onChanged: ((value) => {
                                                          setState(() {
                                                            finalValue = value;
                                                          })
                                                        }),
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: finalValueType ==
                                                            "En Efectivo"
                                                        ? 0.0
                                                        : 8.0),
                                                Text(
                                                  finalValueType ==
                                                          "En Efectivo"
                                                      ? ""
                                                      : "%",
                                                  style:
                                                      TextStyle(fontSize: 24.0),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8.0),
                              ButtonWidget(
                                text: "Agregar",
                                onPressed: locked
                                    ? null
                                    : () {
                                        if (finalReason != '') {
                                          setState(() {
                                            double value =
                                                double.parse(finalValue!);
                                            if (finalValueType ==
                                                "En Porcentaje") {
                                              value /= 100;
                                            }
                                            finalExpenses.add(
                                              Expense.fromMenu(
                                                  "Final",
                                                  finalReason,
                                                  finalValueType,
                                                  value),
                                            );
                                            finalReasons.remove(finalReason);
                                            finalReason =
                                                finalReasons.length > 0
                                                    ? finalReasons[0]
                                                    : '';
                                          });
                                        }
                                      },
                              ),
                              Container(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    dataTextStyle: TextStyle(
                                      color:
                                          locked ? Colors.grey : Colors.black,
                                    ),
                                    columns: [
                                      DataColumn(label: Text('Index')),
                                      DataColumn(label: Text('Motivo')),
                                      DataColumn(label: Text('Tipo')),
                                      DataColumn(label: Text('Valor')),
                                      DataColumn(label: Text('Acciones')),
                                    ],
                                    rows: finalExpenses.map((e) {
                                      int index = finalExpenses.indexOf(e);
                                      String value =
                                          e.valueType == "En Efectivo"
                                              ? "${e.value}"
                                              : "${e.value * 100} %";
                                      return DataRow(cells: [
                                        DataCell(Text((index + 1).toString())),
                                        DataCell(Text(e.reason)),
                                        DataCell(Text(e.valueType)),
                                        DataCell(Text(value)),
                                        DataCell(
                                          IconButton(
                                            icon: Icon(Icons.delete),
                                            onPressed: locked
                                                ? null
                                                : () {
                                                    setState(() {
                                                      finalExpenses.remove(e);
                                                      finalReasons
                                                          .add(e.reason);
                                                      if (finalReason == '') {
                                                        finalReason =
                                                            finalReasons[0];
                                                      }
                                                    });
                                                  },
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: Text(
                    "Valor a Recibir Total: ${valueReceivedTotal.toStringAsFixed(2)}",
                    textAlign: TextAlign.center,
                    style: cardTitleStyle,
                  ),
                ),
                Flexible(
                  child: Text(
                    "TCEA Cartera: ${(tcea * 100).toStringAsFixed(7)}%",
                    textAlign: TextAlign.center,
                    style: cardTitleStyle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.0),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: ButtonWidget(
                text: 'Agregar',
                onPressed: _addBill,
              ),
            ),
            SizedBox(height: 32.0),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('N')),
                      DataColumn(label: Text('Fecha Giro')),
                      DataColumn(label: Text('Val. Nominal')),
                      DataColumn(label: Text('Fecha Ven.')),
                      DataColumn(label: Text('Dias')),
                      DataColumn(label: Text('Retencion')),
                      DataColumn(label: Text('TEP (i`)')),
                      DataColumn(label: Text('d %')),
                      DataColumn(label: Text('Descuento')),
                      DataColumn(label: Text('Costes Ini.')),
                      DataColumn(label: Text('Costes Fin.')),
                      DataColumn(label: Text('Val. Neto')),
                      DataColumn(label: Text('Val. Rec.')),
                      DataColumn(label: Text('Val. Emt.')),
                      DataColumn(label: Text('TCEA %')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: bills.map((e) {
                      int index = bills.indexOf(e);
                      return DataRow(cells: [
                        DataCell(Text((index + 1).toString())),
                        DataCell(Text(getDateText(e.turnDate))),
                        DataCell(Text(e.nominalValue.toStringAsFixed(2))),
                        DataCell(Text(getDateText(e.dueDate))),
                        DataCell(Text(e.days.toString())),
                        DataCell(Text(e.retention.toStringAsFixed(2))),
                        DataCell(Text(
                            "${(e.interestRate * 100).toStringAsFixed(7)}%")),
                        DataCell(Text(
                            "${(e.discountRate * 100).toStringAsFixed(7)}%")),
                        DataCell(Text(e.discount.toStringAsFixed(2))),
                        DataCell(Text(e.initialTotal.toStringAsFixed(2))),
                        DataCell(Text(e.finalTotal.toStringAsFixed(2))),
                        DataCell(Text(e.netWorth.toStringAsFixed(2))),
                        DataCell(Text(e.valueReceived.toStringAsFixed(2))),
                        DataCell(Text(e.valueDelivered.toStringAsFixed(2))),
                        DataCell(Text("${(e.tcea * 100).toStringAsFixed(7)}%")),
                        DataCell(
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteBill(e),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  Widget _buildCapitalizationHelper() {
    return rateType == "Nominal"
        ? SizedBox(height: 50.0)
        : SizedBox(height: 0.0);
  }

  Widget _buildRateCapitalization() {
    return rateType == "Nominal"
        ? Container(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LabelWidget(label: 'Periodo de Capitalizacion'),
                Flexible(
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Center(
                            child: DropdownButton<String>(
                              value: rateCapitalization,
                              underline: Container(
                                height: 0,
                              ),
                              onChanged: locked
                                  ? null
                                  : (String? newValue) {
                                      setState(() {
                                        rateCapitalization = newValue!;
                                        rateCapitalizationDays =
                                            rateMap[rateCapitalization]!;
                                      });
                                    },
                              items: rateTerms.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.0),
                      Flexible(
                        child: Container(
                          width: double.infinity,
                          height: 50.0,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Center(
                            child: Text(
                              "$rateCapitalizationDays dia${rateCapitalizationDays > 1 ? 's' : ''}",
                              style: TextStyle(
                                color: locked ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : SizedBox(height: 0.0);
  }
}
