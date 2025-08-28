import 'package:english_words/english_words.dart';

class WordGenerator {
  final Set<String> _usedWords = {};
  final int _minWordLength;
  final int _maxWordLength;

  WordGenerator({int minWordLength = 3, int maxWordLength = 8})
      : _minWordLength = minWordLength,
        _maxWordLength = maxWordLength;

  String getNextWord() {
    String word;
    do {
      word = WordPair.random().first.toLowerCase();
    } while (_usedWords.contains(word) || 
             word.length < _minWordLength || 
             word.length > _maxWordLength);
    
    _usedWords.add(word);
    return word;
  }

  List<String> getMultipleWords(int count) {
    return List.generate(count, (_) => getNextWord());
  }

  void resetUsedWords() {
    _usedWords.clear();
  }
}