import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word_generator.dart';

enum GameStatus { notStarted, playing, paused, gameOver }

class GameState {
  final GameStatus status;
  final List<GameWord> words;
  final int score;
  final int level;
  final double speed;
  final int lives;

  GameState({
    this.status = GameStatus.notStarted,
    this.words = const [],
    this.score = 0,
    this.level = 1,
    this.speed = 1.0,
    this.lives = 3,
  });

  GameState copyWith({
    GameStatus? status,
    List<GameWord>? words,
    int? score,
    int? level,
    double? speed,
    int? lives,
  }) {
    return GameState(
      status: status ?? this.status,
      words: words ?? this.words,
      score: score ?? this.score,
      level: level ?? this.level,
      speed: speed ?? this.speed,
      lives: lives ?? this.lives,
    );
  }
}

class GameWord {
  final String word;
  final double x;
  double y;
  WordStatus status;

  GameWord({
    required this.word,
    required this.x,
    required this.y,
    this.status = WordStatus.falling,
  });

  GameWord copyWith({
    String? word,
    double? x,
    double? y,
    WordStatus? status,
  }) {
    return GameWord(
      word: word ?? this.word,
      x: x ?? this.x,
      y: y ?? this.y,
      status: status ?? this.status,
    );
  }
}

enum WordStatus { falling, correct, incorrect, missed }

class GameNotifier extends StateNotifier<GameState> {
  final WordGenerator _wordGenerator = WordGenerator();
  
  GameNotifier() : super(GameState());

  void startGame() {
    state = GameState(
      status: GameStatus.playing,
      words: [],
      score: 0,
      level: 1,
      speed: 1.0,
      lives: 3,
    );
    _addNewWord();
  }

  void pauseGame() {
    state = state.copyWith(status: GameStatus.paused);
  }

  void resumeGame() {
    state = state.copyWith(status: GameStatus.playing);
  }

  void gameOver() {
    state = state.copyWith(status: GameStatus.gameOver);
  }

  void _addNewWord() {
    if (state.status != GameStatus.playing) return;
    
    final word = _wordGenerator.getNextWord();
    final x = 0.1 + 0.8 * (DateTime.now().millisecondsSinceEpoch % 100) / 100;
    
    final newWords = [...state.words];
    newWords.add(GameWord(word: word, x: x, y: 0.0));
    
    state = state.copyWith(words: newWords);
  }

  void updateWordPositions(double delta) {
    if (state.status != GameStatus.playing) return;
    
    final updatedWords = <GameWord>[];
    var lives = state.lives;
    
    for (final word in state.words) {
      if (word.status == WordStatus.falling) {
        final newY = word.y + delta * state.speed;
        
        if (newY > 1.0) {
          // Word has fallen off the screen
          lives--;
          updatedWords.add(word.copyWith(status: WordStatus.missed));
        } else {
          updatedWords.add(word.copyWith(y: newY));
        }
      } else {
        // Keep words with correct/incorrect status for animation
        updatedWords.add(word);
      }
    }
    
    // Remove words that have completed their animations
    final filteredWords = updatedWords.where((word) => 
      word.status == WordStatus.falling || 
      (word.status != WordStatus.falling && word.y < 1.2)
    ).toList();
    
    // Check if we need to add a new word
    if (filteredWords.every((word) => word.y > 0.3)) {
      _addNewWord();
    }
    
    // Update state
    state = state.copyWith(
      words: filteredWords,
      lives: lives,
    );
    
    // Check if game over
    if (lives <= 0) {
      gameOver();
    }
  }

  void checkPronunciation(String spokenWord) {
    if (state.status != GameStatus.playing) return;
    
    final updatedWords = <GameWord>[];
    var score = state.score;
    var level = state.level;
    var speed = state.speed;
    
    bool foundMatch = false;
    
    for (final word in state.words) {
      if (!foundMatch && 
          word.status == WordStatus.falling && 
          word.word.toLowerCase() == spokenWord.toLowerCase()) {
        // Correct pronunciation
        updatedWords.add(word.copyWith(status: WordStatus.correct));
        score += 10;
        foundMatch = true;
      } else {
        updatedWords.add(word);
      }
    }
    
    // Increase level and speed every 100 points
    if (score > 0 && score % 100 == 0) {
      level = (score / 100).floor() + 1;
      speed = 1.0 + (level - 1) * 0.2; // Increase speed by 20% per level
    }
    
    state = state.copyWith(
      words: updatedWords,
      score: score,
      level: level,
      speed: speed,
    );
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});