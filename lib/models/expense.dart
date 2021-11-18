class Expense {
  String type;
  String reason;
  String valueType;
  double value;

  Expense({
    required this.type,
    required this.reason,
    required this.valueType,
    required this.value,
  });

  factory Expense.fromMenu(
    String type,
    String reason,
    String valueType,
    double value,
  ) {
    return Expense(
      type: type,
      reason: reason,
      valueType: valueType,
      value: value,
    );
  }

  factory Expense.fromMap(
    Map map,
  ) {
    return Expense(
      type: map['type'],
      reason: map['reason'],
      valueType: map['valueType'],
      value: map['value'],
    );
  }

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'type': type,
        'reason': reason,
        'valueType': valueType,
        'value': value,
      };
}
