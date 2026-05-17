/// Satz-Bau-Übungen für den Lesson-Player.
/// Stufe 2 ersetzt dies durch JSON-Assets.
class SentenceData {
  const SentenceData({required this.nativePrompt, required this.targetWords});

  /// Satz in der Muttersprache (Frage).
  final String nativePrompt;

  /// Korrekte Wort-Reihenfolge in der Zielsprache.
  final List<String> targetWords;
}

const Map<String, List<SentenceData>> sentencesByLesson = {
  'lesson.01-01': [
    SentenceData(
      nativePrompt: 'Hallo, ich heiße Marco.',
      targetWords: ['Ciao,', 'mi', 'chiamo', 'Marco.'],
    ),
    SentenceData(
      nativePrompt: 'Guten Morgen! Auf Wiedersehen.',
      targetWords: ['Buongiorno!', 'Arrivederci.'],
    ),
    SentenceData(
      nativePrompt: 'Danke, bitte!',
      targetWords: ['Grazie,', 'prego!'],
    ),
  ],
  'lesson.01-02': [
    SentenceData(
      nativePrompt: 'Ich habe drei Äpfel.',
      targetWords: ['Ho', 'tre', 'mele.'],
    ),
    SentenceData(
      nativePrompt: 'Eins, zwei, drei, vier.',
      targetWords: ['Uno,', 'due,', 'tre,', 'quattro.'],
    ),
    SentenceData(
      nativePrompt: 'Sie hat fünf Bücher.',
      targetWords: ['Ha', 'cinque', 'libri.'],
    ),
  ],
  'lesson.01-03': [
    SentenceData(
      nativePrompt: 'Das Auto ist rot.',
      targetWords: ['La', 'macchina', 'è', 'rossa.'],
    ),
    SentenceData(
      nativePrompt: 'Der Himmel ist blau.',
      targetWords: ['Il', 'cielo', 'è', 'blu.'],
    ),
    SentenceData(
      nativePrompt: 'Das Gras ist grün.',
      targetWords: ["L'erba", 'è', 'verde.'],
    ),
  ],
};
