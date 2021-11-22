import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({Key? key, required this.text, required this.onPressed})
      : super(key: key);

  final String text;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SizedBox(
        width: double.infinity, // match_parent
        height: 50,
        child: ElevatedButton(
          child: Text(this.text, style: TextStyle(fontSize: 20.0)),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
