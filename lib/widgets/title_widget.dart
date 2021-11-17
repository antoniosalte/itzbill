import 'package:flutter/material.dart';

class TitleWidget extends StatelessWidget {
  const TitleWidget({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(
        title!,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 48.0,
        ),
      ),
    );
  }
}
