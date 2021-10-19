import 'bill.dart';
import 'expense.dart';
import 'rate.dart';

class Pool {
  String id;
  String userId;
  DateTime discountDate;
  int daysPerYear;
  Rate tea;
  Rate tcea;
  String currency;
  List<Expense> initialExpenses;
  List<Expense> finalExpenses;
  Rate rate;

  Pool({
    required this.id,
    required this.userId,
    required this.discountDate,
    required this.daysPerYear,
    required this.tea,
    required this.tcea,
    required this.currency,
    required this.initialExpenses,
    required this.finalExpenses,
    required this.rate,
  });
}
