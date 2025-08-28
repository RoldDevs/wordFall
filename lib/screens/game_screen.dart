import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/falling_word.dart';
import '../providers/game_provider.dart';
import '../utils/speech_recognition_service.dart';
import '../utils/audio_service.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final AudioService _audioService = AudioService();
  Timer? _gameTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    await _speechService.initialize();
  }

  void _startGame() {
    ref.read(gameProvider.notifier).startGame();
    _startGameLoop();
    _startListening();
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final gameState = ref.read(gameProvider);
      if (gameState.status == GameStatus.playing) {
        ref.read(gameProvider.notifier).updateWordPositions(0.002);
      } else if (gameState.status == GameStatus.gameOver) {
        timer.cancel();
        _speechService.stopListening();
      }
    });
  }

  void _startListening() async {
    await _speechService.startListening((spokenWord) {
      final gameState = ref.read(gameProvider);
      if (gameState.status == GameStatus.playing) {
        final previousWords = [...gameState.words];
        
        ref.read(gameProvider.notifier).checkPronunciation(spokenWord);
        
        // Check if any word was correctly pronounced
        final currentWords = ref.read(gameProvider).words;
        for (int i = 0; i < currentWords.length; i++) {
          if (i < previousWords.length && 
              previousWords[i].status != WordStatus.correct && 
              currentWords[i].status == WordStatus.correct) {
            _audioService.playCorrectSound();
            break;
          }
        }
        
        // Continue listening
        _startListening();
      }
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _speechService.stopListening();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Game status bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white.withOpacity(0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Score: ${gameState.score}', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Level: ${gameState.level}', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(
                        gameState.lives,
                        (index) => const Icon(Icons.favorite, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Falling words
            ...gameState.words.map((word) => 
              FallingWord(word: word, screenHeight: screenHeight),
            ),
            
            // Game controls
            if (gameState.status == GameStatus.notStarted)
              Center(
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Start Game', style: TextStyle(fontSize: 20)),
                ),
              ),
              
            if (gameState.status == GameStatus.gameOver)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Game Over', 
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text('Final Score: ${gameState.score}', 
                      style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Play Again', style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
              ),
              
            // Microphone status indicator
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _speechService.isListening ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}