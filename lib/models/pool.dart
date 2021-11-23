import 'expense.dart';
import 'rate.dart';

class Pool {
  String id;
  String userId;
  String name;
  DateTime createdAt;
  DateTime discountDate;
  Rate rate;
  Rate tea;
  double tcea;
  double receivedTotal;
  String currency;
  List<Expense> initialExpenses;
  List<Expense> finalExpenses;

  Pool({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.discountDate,
    required this.rate,
    required this.tea,
    required this.tcea,
    required this.receivedTotal,
    required this.currency,
    required this.initialExpenses,
    required this.finalExpenses,
  });

  factory Pool.createToFirestore(
    String id,
    String userId,
    String name,
    DateTime discountDate,
    Rate rate,
    String currency,
    List<Expense> initialExpenses,
    List<Expense> finalExpenses,
  ) {
    Rate tea = Rate.toTEA(rate);

    return Pool(
      id: id,
      userId: userId,
      name: name,
      createdAt: DateTime.now(),
      discountDate: discountDate,
      rate: rate,
      tea: tea,
      tcea: 0.0,
      receivedTotal: 0.0,
      currency: currency,
      initialExpenses: initialExpenses,
      finalExpenses: finalExpenses,
    );
  }

  factory Pool.fromFirestore(
    String id,
    String userId,
    String name,
    DateTime createdAt,
    DateTime discountDate,
    Rate rate,
    Rate tea,
    double tcea,
    double receivedTotal,
    String currency,
    List<Expense> initialExpenses,
    List<Expense> finalExpenses,
  ) {
    return Pool(
      id: id,
      userId: userId,
      name: name,
      createdAt: createdAt,
      discountDate: discountDate,
      rate: rate,
      tea: tea,
      tcea: tcea,
      receivedTotal: receivedTotal,
      currency: currency,
      initialExpenses: initialExpenses,
      finalExpenses: finalExpenses,
    );
  }

  Map<String, dynamic> toFirestore() {
    List<Map> initialExpensesMap = [];
    List<Map> finalExpensesMap = [];

    for (Expense expense in initialExpenses) {
      initialExpensesMap.add(expense.toFirestore());
    }

    for (Expense expense in finalExpenses) {
      finalExpensesMap.add(expense.toFirestore());
    }
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'name': name,
      'createdAt': createdAt,
      'discountDate': discountDate,
      'rate': rate.toFirestore(),
      'tea': tea.toFirestore(),
      'tcea': tcea,
      'currency': currency,
      'initialExpenses': initialExpensesMap,
      'finalExpenses': finalExpensesMap,
    };
  }
}
