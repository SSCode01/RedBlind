import 'package:flutter/material.dart';
import 'suit_icon.dart';

class VerticalMarquee extends StatefulWidget {
  final int duration;

  const VerticalMarquee({super.key, required this.duration});

  @override
  State<VerticalMarquee> createState() => _VerticalMarqueeState();
}

class _VerticalMarqueeState extends State<VerticalMarquee>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {

          // Move from bottom to top smoothly
          final offsetY =
              screenHeight - (_controller.value * (screenHeight * 2));

          return Transform.translate(
            offset: Offset(0, offsetY),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SuitIcon("♠"),
                SizedBox(height: 80),
                SuitIcon("♥"),
                SizedBox(height: 80),
                SuitIcon("♦"),
                SizedBox(height: 80),
                SuitIcon("♣"),
                SizedBox(height: 80),
                SuitIcon("♠"),
                SizedBox(height: 80),
                SuitIcon("♥"),
                SizedBox(height: 80),
                SuitIcon("♦"),
                SizedBox(height: 80),
                SuitIcon("♣"),
              ],
            ),
          );
        },
      ),
    );
  }
}
