import 'package:flutter/material.dart';

class ToastWidget extends StatelessWidget {
  const ToastWidget({Key? key, required this.message, required this.error})
      : super(key: key);

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: error
            ? Theme.of(context).colorScheme.onError
            : Theme.of(context).colorScheme.primary,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            error ? Icons.error : Icons.check,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          SizedBox(
            width: 12.0,
          ),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ],
      ),
    );
  }
}
