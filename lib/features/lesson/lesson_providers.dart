import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/database/providers.dart';

// ── Data classes ─────────────────────────────────────────────────────────────

class VocabStepData {
  const VocabStepData({
    required this.itemId,
    required this.italiano,
    required this.translationDe,
    required this.partOfSpeech,
  });
  final String itemId;
  final String italiano;
  final String translationDe;
  final String? partOfSpeech;
}

class LessonData {
  const LessonData({
    required this.lessonId,
    required this.title,
    required this.steps,
    required this.allVocab,
  });
  final String lessonId;
  final String title;
  final List<VocabStepData> steps;
  /// Alle Vokabeln in der DB — für MC-Distractors (Review-Phase)
  final List<VocabStepData> allVocab;
}

// ── Provider ──────────────────────────────────────────────────────────────────

final lessonDataProvider =
    FutureProvider.autoDispose.family<LessonData, String>((ref, lessonId) async {
  final db = ref.watch(appDatabaseProvider);
  return loadLesson(db, lessonId);
});

Future<LessonData> loadLesson(AppDatabase db, String lessonId) async {
  // Lesson title
  final lt = await (db.select(db.lessonTranslations)
        ..where((t) => t.lessonId.equals(lessonId) & t.lang.equals('de')))
      .getSingleOrNull();

  // Steps for this lesson (ordered by sortOrder)
  final steps = await (db.select(db.lessonSteps)
        ..where((s) => s.lessonId.equals(lessonId))
        ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
      .get();

  // Collect itemIds
  final itemIds = steps.map((s) => s.itemId).whereType<String>().toList();

  // Vocab items
  final vocabItems = await (db.select(db.vocabItems)
        ..where((v) => v.itemId.isIn(itemIds)))
      .get();
  final vocabMap = {for (final v in vocabItems) v.itemId: v};

  // Translations (DE)
  final translations = await (db.select(db.itemTranslations)
        ..where((t) => t.itemId.isIn(itemIds) & t.lang.equals('de')))
      .get();
  final transMap = {for (final t in translations) t.itemId: t.translation};

  final stepData = itemIds.map((id) {
    final v = vocabMap[id];
    return VocabStepData(
      itemId: id,
      italiano: v?.front ?? id,
      translationDe: transMap[id] ?? '',
      partOfSpeech: v?.partOfSpeech,
    );
  }).toList();

  // All vocab for distractors
  final allVocab = await _loadAllVocab(db);

  return LessonData(
    lessonId: lessonId,
    title: lt?.title ?? lessonId,
    steps: stepData,
    allVocab: allVocab,
  );
}

Future<List<VocabStepData>> _loadAllVocab(AppDatabase db) async {
  final all = await db.select(db.vocabItems).get();
  final allTrans = await (db.select(db.itemTranslations)
        ..where((t) => t.lang.equals('de')))
      .get();
  final transMap = {for (final t in allTrans) t.itemId: t.translation};
  return all
      .map((v) => VocabStepData(
            itemId: v.itemId,
            italiano: v.front,
            translationDe: transMap[v.itemId] ?? '',
            partOfSpeech: v.partOfSpeech,
          ))
      .toList();
}
