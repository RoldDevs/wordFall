import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('Speech recognition error: $error'),
      onStatus: (status) => debugPrint('Speech recognition status: $status'),
    );
    
    return _isInitialized;
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_speech.isAvailable && !_isListening) {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            final recognizedWords = result.recognizedWords;
            if (recognizedWords.isNotEmpty) {
              onResult(recognizedWords);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
      );
    }
  }

  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized && _speech.isAvailable;
}