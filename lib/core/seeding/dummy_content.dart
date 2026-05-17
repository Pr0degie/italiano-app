import 'package:drift/drift.dart';

import '../constants.dart';
import '../database/database.dart';

/// Dummy-Content für Stufe 1.
/// Stufe 2 ersetzt dies durch JSON-Assets.
class DummyContent {
  static Future<void> seed(AppDatabase db) async {
    await _seedChapters(db);
    await _seedLessons(db);
    await _seedVocab(db);
  }

  // ── Chapters ────────────────────────────────────────────────────────────────

  static Future<void> _seedChapters(AppDatabase db) async {
    final chapters = [
      ('chapter.01', 1, 'Grundlagen'),
      ('chapter.02', 2, 'Alltag'),
    ];
    for (final (id, sort, title) in chapters) {
      await db.into(db.chapters).insertOnConflictUpdate(
            ChaptersCompanion.insert(id: id, sortOrder: sort),
          );
      await db.into(db.chapterTranslations).insertOnConflictUpdate(
            ChapterTranslationsCompanion.insert(
              chapterId: id,
              lang: AppConstants.activeLang,
              title: title,
            ),
          );
    }
  }

  // ── Lessons ─────────────────────────────────────────────────────────────────

  static Future<void> _seedLessons(AppDatabase db) async {
    final lessons = [
      // (id, chapterId, sortOrder, titleDe)
      ('lesson.01-01', 'chapter.01', 1, 'Begrüßungen'),
      ('lesson.01-02', 'chapter.01', 2, 'Zahlen 1–10'),
      ('lesson.01-03', 'chapter.01', 3, 'Farben'),
      ('lesson.02-01', 'chapter.02', 1, 'Im Café'),
      ('lesson.02-02', 'chapter.02', 2, 'Einkaufen'),
      ('lesson.02-03', 'chapter.02', 3, 'Uhrzeit'),
    ];
    for (final (id, chapterId, sort, title) in lessons) {
      await db.into(db.lessons).insertOnConflictUpdate(
            LessonsCompanion.insert(
              id: id,
              chapterId: chapterId,
              sortOrder: sort,
            ),
          );
      await db.into(db.lessonTranslations).insertOnConflictUpdate(
            LessonTranslationsCompanion.insert(
              lessonId: id,
              lang: AppConstants.activeLang,
              title: title,
            ),
          );
    }
  }

  // ── Vocab + Steps ────────────────────────────────────────────────────────────

  static Future<void> _seedVocab(AppDatabase db) async {
    final vocabByLesson = <String, List<(String, String, String, String)>>{
      // lessonId → [(itemId, target, native, partOfSpeech)]
      'lesson.01-01': [
        ('vocab.ciao', 'ciao', 'hallo / tschüss', 'interj'),
        ('vocab.buongiorno', 'buongiorno', 'guten Morgen', 'interj'),
        ('vocab.buonasera', 'buonasera', 'guten Abend', 'interj'),
        ('vocab.arrivederci', 'arrivederci', 'auf Wiedersehen', 'interj'),
        ('vocab.prego', 'prego', 'bitte (Antwort auf Dankeschön)', 'interj'),
        ('vocab.grazie', 'grazie', 'danke', 'interj'),
        ('vocab.scusa', 'scusa', 'entschuldigung (informell)', 'interj'),
        ('vocab.si', 'sì', 'ja', 'adv'),
      ],
      'lesson.01-02': [
        ('vocab.uno', 'uno', 'eins', 'num'),
        ('vocab.due', 'due', 'zwei', 'num'),
        ('vocab.tre', 'tre', 'drei', 'num'),
        ('vocab.quattro', 'quattro', 'vier', 'num'),
        ('vocab.cinque', 'cinque', 'fünf', 'num'),
        ('vocab.sei', 'sei', 'sechs', 'num'),
        ('vocab.sette', 'sette', 'sieben', 'num'),
        ('vocab.otto', 'otto', 'acht', 'num'),
      ],
      'lesson.01-03': [
        ('vocab.rosso', 'rosso', 'rot', 'adj'),
        ('vocab.blu', 'blu', 'blau', 'adj'),
        ('vocab.verde', 'verde', 'grün', 'adj'),
        ('vocab.giallo', 'giallo', 'gelb', 'adj'),
        ('vocab.bianco', 'bianco', 'weiß', 'adj'),
        ('vocab.nero', 'nero', 'schwarz', 'adj'),
        ('vocab.arancione', 'arancione', 'orange', 'adj'),
        ('vocab.viola', 'viola', 'lila', 'adj'),
      ],
      'lesson.02-01': [
        ('vocab.caffe', 'caffè', 'Kaffee', 'noun'),
        ('vocab.cappuccino', 'cappuccino', 'Cappuccino', 'noun'),
        ('vocab.acqua', 'acqua', 'Wasser', 'noun'),
        ('vocab.tè', 'tè', 'Tee', 'noun'),
        ('vocab.cornetto', 'cornetto', 'Croissant', 'noun'),
        ('vocab.conto', 'conto', 'Rechnung', 'noun'),
        ('vocab.tavolo', 'tavolo', 'Tisch', 'noun'),
        ('vocab.cameriere', 'cameriere', 'Kellner', 'noun'),
      ],
      'lesson.02-02': [
        ('vocab.pane', 'pane', 'Brot', 'noun'),
        ('vocab.latte', 'latte', 'Milch', 'noun'),
        ('vocab.frutta', 'frutta', 'Obst', 'noun'),
        ('vocab.verdura', 'verdura', 'Gemüse', 'noun'),
        ('vocab.carne', 'carne', 'Fleisch', 'noun'),
        ('vocab.pesce', 'pesce', 'Fisch', 'noun'),
        ('vocab.prezzo', 'prezzo', 'Preis', 'noun'),
        ('vocab.mercato', 'mercato', 'Markt', 'noun'),
      ],
      'lesson.02-03': [
        ('vocab.ora', 'ora', 'Stunde / Uhr', 'noun'),
        ('vocab.mattina', 'mattina', 'Morgen', 'noun'),
        ('vocab.pomeriggio', 'pomeriggio', 'Nachmittag', 'noun'),
        ('vocab.sera', 'sera', 'Abend', 'noun'),
        ('vocab.notte', 'notte', 'Nacht', 'noun'),
        ('vocab.mezzogiorno', 'mezzogiorno', 'Mittag', 'noun'),
        ('vocab.mezzanotte', 'mezzanotte', 'Mitternacht', 'noun'),
        ('vocab.minuto', 'minuto', 'Minute', 'noun'),
      ],
    };

    for (final entry in vocabByLesson.entries) {
      final lessonId = entry.key;
      final items = entry.value;
      for (var i = 0; i < items.length; i++) {
        final (itemId, target, native, pos) = items[i];

        await db.into(db.items).insertOnConflictUpdate(
              ItemsCompanion.insert(id: itemId, type: 'vocab'),
            );
        await db.into(db.vocabItems).insertOnConflictUpdate(
              VocabItemsCompanion.insert(
                itemId: itemId,
                front: target,
                partOfSpeech: Value(pos),
              ),
            );
        await db.into(db.itemTranslations).insertOnConflictUpdate(
              ItemTranslationsCompanion.insert(
                itemId: itemId,
                lang: AppConstants.activeLang,
                translation: native,
              ),
            );
        await db.into(db.lessonSteps).insertOnConflictUpdate(
              LessonStepsCompanion.insert(
                lessonId: lessonId,
                sortOrder: i + 1,
                itemId: Value(itemId),
                suggestedExerciseType: const Value('flashcard'),
              ),
            );
      }
    }
  }
}
