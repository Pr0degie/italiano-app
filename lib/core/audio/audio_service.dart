import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Spielt Text in der Zielsprache vor — per Long-Press auf beliebige Wörter/Sätze.
///
/// Stufe 4 ersetzt [_NoOpAudioService] durch eine echte Implementierung
/// (flutter_tts oder Asset-Audio). Alle Widgets bleiben unverändert.
///
/// Verwendung in Widgets:
/// ```dart
/// GestureDetector(
///   onLongPress: () => ref.read(audioServiceProvider).speak(targetText),
///   child: Text(targetText),
/// )
/// ```
abstract class AudioService {
  Future<void> speak(String text);
}

class _NoOpAudioService implements AudioService {
  @override
  Future<void> speak(String text) async {}
}

final audioServiceProvider = Provider<AudioService>(
  (_) => _NoOpAudioService(),
);
