import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:itzbill/providers/auth_provider.dart';
import 'package:itzbill/models/pool.dart';
import 'package:itzbill/models/expense.dart';
import 'package:itzbill/models/bill.dart';

import 'package:itzbill/widgets/subtitle_widget.dart';
import 'package:itzbill/widgets/title_widget.dart';
import 'package:itzbill/widgets/label_widget.dart';
import 'package:itzbill/widgets/header_button_widget.dart';
import 'package:itzbill/widgets/loading_widget.dart';
import 'package:itzbill/widgets/toast_widget.dart';
import 'package:itzbill/widgets/button_widget.dart';

class PoolScreen extends StatefulWidget {
  PoolScreen({Key? key, required this.currency, this.pool}) : super(key: key);

  final Currency currency;
  final Pool? pool;

  @override
  PoolScreenState createState() => PoolScreenState();
}

class PoolScreenState extends State<PoolScreen> {
  FToast fToast = FToast();
  AuthProvider? auth;

  bool loading = false;
  bool locked = false;

  String daysPerYear = "360";
  String rateTerm = "Anual";
  String rateType = "Nominal";
  String rateCapitalization = "Diario";
  String? rateValue;
  String? nominalValue;
  String? retentionValue;

  int rateTermDays = 360;
  int rateCapitalizationDays = 1;

  DateTime? discountDate;
  DateTime? billDate;
  DateTime? dueDate;

  String initialReason = "Portes";
  String initialValueType = "En Efectivo";
  String? initialValue;

  String finalReason = "Portes";
  String finalValueType = "En Efectivo";
  String? finalValue;

  double initialTotal = 0.0;
  double finalTotal = 0.0;

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

  final _amountValidator = RegExp('^\$|^(0|([1-9][0-9]{0,}))(\\.[0-9]{0,})?\$');

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
      if (dueDate!.compareTo(discountDate!) < 0) {
        setState(() => dueDate = discountDate);
      }
    }
  }

  Future pickBillDate() async {
    final initialDate = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: billDate ?? initialDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (newDate == null) return;

    setState(() => billDate = newDate);
  }

  Future pickDueDate() async {
    if (dueDate != null && discountDate != null) {
      if (dueDate!.compareTo(discountDate!) < 0) {
        setState(() => dueDate = discountDate);
      }
    }

    final initialDate = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: dueDate ?? initialDate,
      firstDate: discountDate ?? DateTime(DateTime.now().year - 5),
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

  Future<void> addBill() async {
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

    if (billDate == null || billDate == '') {
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

    setState(() {
      locked = true;
    });

    double realNominalValue = double.parse(nominalValue!);

    for (Expense expense in initialExpenses) {
      double realValue = expense.value;
      if (expense.valueType == "En Porcentaje") {
        realValue = realNominalValue * expense.value / 100;
      }
      initialTotal += realValue;
    }

    for (Expense expense in finalExpenses) {
      double realValue = expense.value;
      if (expense.valueType == "En Porcentaje") {
        realValue = realNominalValue * expense.value / 100;
      }
      finalTotal += realValue;
    }

    // try {
    //   Bill bill = await _databaseService.createBill(
    //     auth!.uid,
    //     discountDate!,
    //     dueDate!,
    //     billDate!,
    //     double.parse(nominalValue!),
    //     initialTotal,
    //     finalTotal,
    //     initialExpenses,
    //     finalExpenses,
    //     settings.rateType,
    //     rateTerm,
    //     double.parse(rateValue!) / 100,
    //     rateDays,
    //     int.parse(daysPerYear),
    //   );

    //   _stopLoading();
    //   setState(() {
    //     bills.add(bill);
    //     valueToReceiveTotal += bill.valueToReceive;
    //     _showToast('Agregado con exito');
    //   });
    //   calculateXIRR();
    // } on Error catch (e) {
    //   _stopLoading();
    //   _showToast('Error al agregar: $e', true);
    // }
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
    double width = MediaQuery.of(context).size.width;
    double cardWidth = (width / 8) * 3;
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
      body: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 24.0),
          TitleWidget(title: 'Letra Descontada a Tasa $rateType'),
          SizedBox(height: 24.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Card(
                child: Container(
                  width: cardWidth,
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SubtitleWidget(title: "Tasa y Plazo"),
                      SizedBox(height: 16.0),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  borderRadius: BorderRadius.circular(4.0),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                    rateTerm = newValue!;
                                                    rateTermDays =
                                                        rateMap[rateTerm]!;
                                                  });
                                                },
                                          items: rateTerms
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                    rateType = newValue!;
                                                  });
                                                },
                                          items: rateTypes
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
                            Flexible(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: TextField(
                                      enabled: !locked,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: false,
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            _amountValidator),
                                      ],
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        height: 1.0,
                                        color:
                                            locked ? Colors.grey : Colors.black,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Center(
                                  child: TextButton(
                                    child: Text(
                                      getDateText(discountDate),
                                      style: TextStyle(
                                        color:
                                            locked ? Colors.grey : Colors.black,
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
              ),
              Card(
                child: Container(
                  width: cardWidth,
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SubtitleWidget(title: "Datos de la Letra"),
                      SizedBox(height: 16.0),
                      _buildCapitalizationHelper(),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Center(
                                  child: TextButton(
                                    child: Text(
                                      getDateText(billDate),
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    onPressed: () => pickBillDate(),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Center(
                                  child: TextButton(
                                    child: Text(
                                      getDateText(dueDate),
                                      style: TextStyle(color: Colors.black),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            LabelWidget(label: 'Valor Nominal'),
                            Flexible(
                              child: TextField(
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: false,
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      _amountValidator),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            LabelWidget(label: 'Retencion'),
                            Flexible(
                              child: TextField(
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: false,
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      _amountValidator),
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
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SubtitleWidget(title: "Costes / Gastos Iniciales"),
                      SizedBox(height: 16.0),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  borderRadius: BorderRadius.circular(4.0),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          items: valueTypes
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
                                  SizedBox(width: 4.0),
                                  Flexible(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: TextField(
                                            enabled: !locked,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                              decimal: true,
                                              signed: false,
                                            ),
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  _amountValidator),
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
                                                    initialValue = value;
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
                                          initialValueType == "En Efectivo"
                                              ? ""
                                              : "%",
                                          style: TextStyle(fontSize: 24.0),
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
                                    double value = double.parse(initialValue!);
                                    initialExpenses.add(
                                      Expense.fromMenu(
                                        "Initial",
                                        initialReason,
                                        initialValueType,
                                        value,
                                      ),
                                    );
                                    initialReasons.remove(initialReason);
                                    initialReason = initialReasons.length > 0
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
                              color: locked ? Colors.grey : Colors.black,
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
                              String value = e.valueType == "En Efectivo"
                                  ? "${e.value}"
                                  : "${e.value} %";
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
                                              initialReasons.add(e.reason);
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
              ),
              Card(
                child: Container(
                  width: cardWidth,
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SubtitleWidget(title: "Costes / Gastos Finales"),
                      SizedBox(height: 16.0),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  borderRadius: BorderRadius.circular(4.0),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                    finalValueType = newValue!;
                                                  });
                                                },
                                          items: valueTypes
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
                                  SizedBox(width: 4.0),
                                  Flexible(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: TextField(
                                            enabled: !locked,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                              decimal: true,
                                              signed: false,
                                            ),
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  _amountValidator),
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
                                            width:
                                                finalValueType == "En Efectivo"
                                                    ? 0.0
                                                    : 8.0),
                                        Text(
                                          finalValueType == "En Efectivo"
                                              ? ""
                                              : "%",
                                          style: TextStyle(fontSize: 24.0),
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
                                    double value = double.parse(finalValue!);
                                    finalExpenses.add(
                                      Expense.fromMenu(
                                        "Final",
                                        finalReason,
                                        finalValueType,
                                        value,
                                      ),
                                    );
                                    finalReasons.remove(finalReason);
                                    finalReason = finalReasons.length > 0
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
                              color: locked ? Colors.grey : Colors.black,
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
                              String value = e.valueType == "En Efectivo"
                                  ? "${e.value}"
                                  : "${e.value} %";
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
                                              finalReasons.add(e.reason);
                                              if (finalReason == '') {
                                                finalReason = finalReasons[0];
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
              ),
            ],
          ),
          SizedBox(height: 32.0),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              child: Column(
                children: [
                  SizedBox(height: 32.0),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: ButtonWidget(
                      text: 'Agregar',
                      onPressed: addBill,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      )),
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