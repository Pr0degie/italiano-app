/// Satz-Bau-Übungen für den Lesson-Player.
/// Stufe 2 ersetzt dies durch JSON-Assets.
class SentenceData {
  const SentenceData({required this.german, required this.italian});
  final String german;
  final List<String> italian; // korrekte Wort-Reihenfolge
}

const Map<String, List<SentenceData>> sentencesByLesson = {
  'lesson.01-01': [
    SentenceData(
      german: 'Hallo, ich heiße Marco.',
      italian: ['Ciao,', 'mi', 'chiamo', 'Marco.'],
    ),
    SentenceData(
      german: 'Guten Morgen! Auf Wiedersehen.',
      italian: ['Buongiorno!', 'Arrivederci.'],
    ),
    SentenceData(
      german: 'Danke, bitte!',
      italian: ['Grazie,', 'prego!'],
    ),
  ],
  'lesson.01-02': [
    SentenceData(
      german: 'Ich habe drei Äpfel.',
      italian: ['Ho', 'tre', 'mele.'],
    ),
    SentenceData(
      german: 'Eins, zwei, drei, vier.',
      italian: ['Uno,', 'due,', 'tre,', 'quattro.'],
    ),
    SentenceData(
      german: 'Sie hat fünf Bücher.',
      italian: ['Ha', 'cinque', 'libri.'],
    ),
  ],
  'lesson.01-03': [
    SentenceData(
      german: 'Das Auto ist rot.',
      italian: ['La', 'macchina', 'è', 'rossa.'],
    ),
    SentenceData(
      german: 'Der Himmel ist blau.',
      italian: ['Il', 'cielo', 'è', 'blu.'],
    ),
    SentenceData(
      german: 'Das Gras ist grün.',
      italian: ["L'erba", 'è', 'verde.'],
    ),
  ],
};
