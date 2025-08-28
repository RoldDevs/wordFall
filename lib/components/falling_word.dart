import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';

class FallingWord extends StatelessWidget {
  final GameWord word;
  final double screenHeight;
  
  const FallingWord({
    super.key,
    required this.word,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    final List<Effect> effects = [];
    
    switch (word.status) {
      case WordStatus.correct:
        textColor = Colors.green;
        effects.addAll([
          // Fix: Use begin and end parameters with Offset objects
          ScaleEffect(begin: const Offset(1.0, 1.0), end: const Offset(1.5, 1.5), delay: 300.ms),
          FadeEffect(begin: 1.0, end: 0.0, delay: 300.ms, duration: 700.ms),
        ]);
        break;
      case WordStatus.incorrect:
        textColor = Colors.red;
        effects.addAll([
          ShakeEffect(duration: 300.ms),
          FadeEffect(begin: 1.0, end: 0.0, delay: 300.ms, duration: 700.ms),
        ]);
        break;
      case WordStatus.missed:
        textColor = Colors.red.withAlpha(178);
        effects.addAll([
          FadeEffect(begin: 1.0, end: 0.0, duration: 500.ms),
        ]);
        break;
      case WordStatus.falling:
      textColor = Colors.black;
        break;
    }

    return Positioned(
      left: word.x * MediaQuery.of(context).size.width,
      top: word.y * screenHeight,
      child: Text(
        word.word,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ).animate().addEffects(effects),
    );
  }
}