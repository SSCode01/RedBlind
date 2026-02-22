// lib/widgets/poker_background.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class PokerBackground extends StatelessWidget {
  final Widget child;
  final bool isGreenTable;
  final List<Color>? gradientColors;

  const PokerBackground({
    super.key,
    required this.child,
    this.isGreenTable = false,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Positioned.fill(
          child: isGreenTable ? _buildGreenTable() : _buildRedBackground(),
        ),
        // Floating suit symbols
        const Positioned.fill(child: _FloatingSuits()),
        // Content
        child,
      ],
    );
  }

  Widget _buildRedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.2,
          colors: gradientColors ??
              [
                const Color(0xFFCC0000),
                const Color(0xFF8B0000),
                const Color(0xFF3D0000),
                const Color(0xFF0A0000),
              ],
          stops: const [0.0, 0.4, 0.75, 1.0],
        ),
      ),
    );
  }

  Widget _buildGreenTable() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.3,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
            Color(0xFF0D3D11),
            Color(0xFF060F07),
          ],
          stops: [0.0, 0.4, 0.75, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _FeltTexturePainter(),
      ),
    );
  }
}

class _FeltTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle felt-like oval
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.88,
      height: size.height * 0.75,
    );
    canvas.drawOval(ovalRect, paint);

    // Inner oval
    paint.color = Colors.white.withOpacity(0.02);
    final innerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.75,
      height: size.height * 0.62,
    );
    canvas.drawOval(innerRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingSuits extends StatefulWidget {
  const _FloatingSuits();

  @override
  State<_FloatingSuits> createState() => _FloatingSuitsState();
}

class _FloatingSuitsState extends State<_FloatingSuits>
    with SingleTickerProviderStateMixin {
  static const suits = ['♠', '♥', '♦', '♣'];
  late List<_SuitData> suitPositions;
  final random = Random(42);

  @override
  void initState() {
    super.initState();
    suitPositions = List.generate(16, (i) {
      return _SuitData(
        suit: suits[i % 4],
        x: random.nextDouble(),
        yStart: random.nextDouble(),
        size: 18.0 + random.nextDouble() * 24,
        opacity: 0.04 + random.nextDouble() * 0.08,
        duration: 8 + random.nextInt(10),
        delay: random.nextInt(8),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: suitPositions.map((s) {
            return Positioned(
              left: s.x * constraints.maxWidth,
              top: s.yStart * constraints.maxHeight,
              child: _AnimatedSuit(data: s),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SuitData {
  final String suit;
  final double x;
  final double yStart;
  final double size;
  final double opacity;
  final int duration;
  final int delay;

  _SuitData({
    required this.suit,
    required this.x,
    required this.yStart,
    required this.size,
    required this.opacity,
    required this.duration,
    required this.delay,
  });
}

class _AnimatedSuit extends StatelessWidget {
  final _SuitData data;

  const _AnimatedSuit({required this.data});

  @override
  Widget build(BuildContext context) {
    final isRed = data.suit == '♥' || data.suit == '♦';
    return Text(
      data.suit,
      style: TextStyle(
        fontSize: data.size,
        color: (isRed ? AppColors.crimson : Colors.white)
            .withOpacity(data.opacity),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .moveY(
          begin: 0,
          end: -80,
          duration: Duration(seconds: data.duration),
          delay: Duration(seconds: data.delay),
          curve: Curves.easeInOut,
        )
        .fadeIn(duration: 2.seconds)
        .then()
        .fadeOut(duration: 2.seconds);
  }
}