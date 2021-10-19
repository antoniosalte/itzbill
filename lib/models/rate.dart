class Rate {
  String type;
  String term;
  double value;
  int days;
  int daysPerYear;

  Rate({
    required this.type,
    required this.term,
    required this.value,
    required this.days,
    required this.daysPerYear,
  });
}
