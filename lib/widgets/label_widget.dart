import 'package:flutter/material.dart';

class LabelWidget extends StatelessWidget {
  const LabelWidget({Key? key, required this.label}) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        label,
        textAlign: TextAlign.start,
        style: TextStyle(fontSize: 20.0),
      ),
    );
  }
}
