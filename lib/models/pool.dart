import 'expense.dart';
import 'rate.dart';

class Pool {
  String id;
  String userId;
  DateTime discountDate;
  Rate rate;
  Rate tea;
  Rate tcea;
  String currency;
  List<Expense> initialExpenses;
  List<Expense> finalExpenses;

  Pool({
    required this.id,
    required this.userId,
    required this.discountDate,
    required this.rate,
    required this.tea,
    required this.tcea,
    required this.currency,
    required this.initialExpenses,
    required this.finalExpenses,
  });

  factory Pool.createToMenu(
    DateTime discountDate,
    Rate rate,
    String currency,
    List<Expense> initialExpenses,
    List<Expense> finalExpenses,
  ) {
    return Pool(
      id: "",
      userId: "",
      discountDate: discountDate,
      rate: rate,
      tea: rate,
      tcea: rate,
      currency: currency,
      initialExpenses: initialExpenses,
      finalExpenses: finalExpenses,
    );
  }

  factory Pool.createToFirestore(
    String id,
    String userId,
    DateTime discountDate,
    Rate rate,
    String currency,
    List<Expense> initialExpenses,
    List<Expense> finalExpenses,
  ) {
    Rate tea = Rate.toTEA(rate);
    Rate tcea = tea; // TODO: Change this

    return Pool(
      id: id,
      userId: userId,
      discountDate: discountDate,
      rate: rate,
      tea: tea,
      tcea: tcea,
      currency: currency,
      initialExpenses: initialExpenses,
      finalExpenses: finalExpenses,
    );
  }

  factory Pool.fromFirestore(
    String id,
    String userId,
    DateTime discountDate,
    Rate rate,
    Rate tea,
    Rate tcea,
    String currency,
    List<Expense> initialExpenses,
    List<Expense> finalExpenses,
  ) {
    return Pool(
      id: id,
      userId: userId,
      discountDate: discountDate,
      rate: rate,
      tea: tea,
      tcea: tcea,
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
      'discountDate': discountDate,
      'rate': rate.toFirestore(),
      'tea': tea.toFirestore(),
      'tcea': tcea.toFirestore(),
      'currency': currency,
      'initialExpenses': initialExpensesMap,
      'finalExpenses': finalExpensesMap,
    };
  }
}
