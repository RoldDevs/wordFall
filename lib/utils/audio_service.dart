import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // You'll need to add these audio files to your assets folder
  static const String correctSoundPath = 'assets/audio/correct.mp3';
  static const String incorrectSoundPath = 'assets/audio/incorrect.mp3';
  
  Future<void> playCorrectSound() async {
    await _audioPlayer.play(AssetSource(correctSoundPath));
  }
  
  Future<void> playIncorrectSound() async {
    await _audioPlayer.play(AssetSource(incorrectSoundPath));
  }
  
  void dispose() {
    _audioPlayer.dispose();
  }
}