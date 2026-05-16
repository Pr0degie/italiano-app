class SM2Result {
  const SM2Result({
    required this.easiness,
    required this.interval,
    required this.repetitions,
    required this.dueDate,
  });
  final double easiness;
  final int interval;
  final int repetitions;
  final DateTime dueDate;
}

/// Standard SM-2 Algorithmus.
/// [correct] true → Qualität 4, false → Qualität 1.
class SM2 {
  /// Einstieg nach Phase-1-Mastery (3 Tage korrekt).
  /// Startet mit interval=7 statt 1 — Phase 1 hat das bereits abgedeckt.
  static SM2Result applyAfterMastery({required double easiness}) {
    return apply(
      easiness: easiness,
      interval: 7,
      repetitions: 3,
      correct: true,
    );
  }

  static SM2Result apply({
    required double easiness,
    required int interval,
    required int repetitions,
    required bool correct,
  }) {
    final quality = correct ? 4 : 1;

    var newEasiness = easiness + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (newEasiness < 1.3) newEasiness = 1.3;

    int newRepetitions;
    int newInterval;

    if (quality < 3) {
      newRepetitions = 0;
      newInterval = 1;
    } else {
      newRepetitions = repetitions + 1;
      if (newRepetitions == 1) {
        newInterval = 1;
      } else if (newRepetitions == 2) {
        newInterval = 6;
      } else {
        newInterval = (interval * newEasiness).round();
      }
    }

    return SM2Result(
      easiness: newEasiness,
      interval: newInterval,
      repetitions: newRepetitions,
      dueDate: DateTime.now().add(Duration(days: newInterval)),
    );
  }
}
