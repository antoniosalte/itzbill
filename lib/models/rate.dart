import 'dart:math';

class Rate {
  String type;
  double value;
  int daysPerYear;
  int termDays;
  int capitalizationDays;

  Rate({
    required this.type,
    required this.value,
    required this.daysPerYear,
    required this.termDays,
    required this.capitalizationDays,
  });

  factory Rate.toPool(
    String type,
    double value,
    int daysPerYear,
    int termDays,
    int capitalizationDays,
  ) {
    return Rate(
      type: type,
      value: value,
      daysPerYear: daysPerYear,
      termDays: termDays,
      capitalizationDays: capitalizationDays,
    );
  }

  factory Rate.toTEA(Rate rate) {
    double value = 0.0;
    if (rate.type == "Nominal") {
      int m = rate.termDays ~/ rate.capitalizationDays;
      int n = 360 ~/ rate.capitalizationDays; //  Maybe change to daysPerYear
      value = pow(1 + (rate.value / m), n) - 1;
    } else {
      value = pow(1 + rate.value, 360 / rate.termDays) - 1;
    }
    return Rate(
      type: "Efectiva",
      value: value,
      daysPerYear: rate.daysPerYear,
      termDays: 360, // Maybe change to daysPerYear
      capitalizationDays: -1,
    );
  }

  factory Rate.fromMap(Map data) {
    return Rate(
      type: data['type'],
      value: data['value'],
      termDays: data['termDays'],
      daysPerYear: data['daysPerYear'],
      capitalizationDays: data['capitalizationDays'],
    );
  }

  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'type': type,
        'value': value,
        'daysPerYear': daysPerYear,
        'termDays': termDays,
        'capitalizationDays': capitalizationDays,
      };
}
