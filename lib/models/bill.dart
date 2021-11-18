import 'dart:math';
import 'expense.dart';
import 'rate.dart';

// extension Ex on double {
//   double toPrecision(int n) => double.parse(toStringAsFixed(n));
// }

class Bill {
  String id;
  String poolId;
  String userId;
  DateTime turnDate;
  DateTime dueDate;
  int days;
  double nominalValue;
  double retention;
  double interestRate;
  double discountRate;
  double discount;
  double initialTotal;
  double finalTotal;
  double netWorth;
  double valueReceived;
  double valueDelivered;
  double tcea;

  Bill({
    required this.id,
    required this.poolId,
    required this.userId,
    required this.turnDate,
    required this.dueDate,
    required this.days,
    required this.nominalValue,
    required this.retention,
    required this.interestRate,
    required this.discountRate,
    required this.discount,
    required this.initialTotal,
    required this.finalTotal,
    required this.netWorth,
    required this.valueReceived,
    required this.valueDelivered,
    required this.tcea,
  });

  factory Bill.createToFirestore(
    String id,
    String poolId,
    String userId,
    DateTime discountDate,
    DateTime turnDate,
    DateTime dueDate,
    double nominalValue,
    double retention,
    List<Expense> initialExpenses,
    List<Expense> finalExpenses,
    Rate tea,
  ) {
    nominalValue = nominalValue; //.toPrecision(7);
    retention = retention; //.toPrecision(7);

    double initialTotal = 0.0;
    double finalTotal = 0.0;

    for (Expense expense in initialExpenses) {
      double realValue = expense.value;
      if (expense.valueType == "En Porcentaje") {
        realValue = nominalValue * expense.value;
      }
      initialTotal += realValue;
    }

    for (Expense expense in finalExpenses) {
      double realValue = expense.value;
      if (expense.valueType == "En Porcentaje") {
        realValue = nominalValue * expense.value;
      }
      finalTotal += realValue;
    }

    initialTotal; //.toPrecision(7);
    finalTotal; //.toPrecision(7);

    int days = dueDate.difference(discountDate).inDays;

    double interestRate =
        (pow(1 + tea.value, days.toDouble() / tea.daysPerYear.toDouble()) - 1)
            .toDouble();
    // .toPrecision(7);

    double discountRate =
        (interestRate / (1 + interestRate)); //.toPrecision(7);
    double discount = (nominalValue * discountRate); //.toPrecision(2);
    double netWorth = (nominalValue - discount); //.toPrecision(2);
    double valueReceived =
        (netWorth - initialTotal - retention); //.toPrecision(2);
    double valueDelivered =
        (nominalValue + finalTotal - retention); //.toPrecision(2);
    double tcea = pow(valueDelivered / valueReceived,
            tea.daysPerYear.toDouble() / days.toDouble()) -
        1;
    return Bill(
      id: id,
      poolId: poolId,
      userId: userId,
      turnDate: turnDate,
      dueDate: dueDate,
      days: days,
      nominalValue: nominalValue,
      retention: retention,
      interestRate: interestRate,
      discountRate: discountRate,
      discount: discount,
      initialTotal: initialTotal,
      finalTotal: finalTotal,
      netWorth: netWorth,
      valueReceived: valueReceived,
      valueDelivered: valueDelivered,
      tcea: tcea,
    );
  }

  factory Bill.fromMap(
    Map map,
  ) {
    return Bill(
      id: map['id'],
      poolId: map['poolId'],
      userId: map['userId'],
      turnDate: map['turnDate'].toDate(),
      dueDate: map['dueDate'].toDate(),
      days: map['days'],
      nominalValue: map['nominalValue'],
      retention: map['retention'],
      interestRate: map['interestRate'],
      discountRate: map['discountRate'],
      discount: map['discount'],
      initialTotal: map['initialTotal'],
      finalTotal: map['finalTotal'],
      netWorth: map['netWorth'],
      valueReceived: map['valueReceived'],
      valueDelivered: map['valueDelivered'],
      tcea: map['tcea'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'id': id,
      'poolId': poolId,
      'userId': userId,
      'turnDate': turnDate,
      'dueDate': dueDate,
      'days': days,
      'nominalValue': nominalValue,
      'retention': retention,
      'interestRate': interestRate,
      'discountRate': discountRate,
      'discount': discount,
      'initialTotal': initialTotal,
      'finalTotal': finalTotal,
      'netWorth': netWorth,
      'valueReceived': valueReceived,
      'valueDelivered': valueDelivered,
      'tcea': tcea,
    };
  }
}
