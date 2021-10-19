import 'rate.dart';

class Bill {
  String id;
  String poolId;
  DateTime turnDate;
  double value;
  DateTime dueDate;
  Rate tcea;
  Rate rate;

  Bill({
    required this.id,
    required this.poolId,
    required this.turnDate,
    required this.value,
    required this.dueDate,
    required this.tcea,
    required this.rate,
  });
}
