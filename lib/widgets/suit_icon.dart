import 'package:flutter/material.dart';

class SuitIcon extends StatelessWidget {
  final String suit;

  const SuitIcon(this.suit, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      suit,
      style: TextStyle(
        fontSize: 24,
        color: Colors.grey.withOpacity(0.5),
      ),
    );
  }
}
