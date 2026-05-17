import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/database/database.dart';
import '../../core/database/providers.dart';

// ── Data classes ─────────────────────────────────────────────────────────────

class VocabStepData {
  const VocabStepData({
    required this.itemId,
    required this.target,
    required this.native,
    required this.partOfSpeech,
    this.suggestedExerciseType,
  });
  final String itemId;

  /// Wort in der Zielsprache (z.B. italienisch).
  final String target;

  /// Übersetzung in der Muttersprache des Nutzers.
  final String native;
  final String? partOfSpeech;

  /// Welcher Übungstyp für dieses Item generiert werden soll ('mc', 'pair', ...).
  /// Nur für Vokabeln aus einer Lektion gesetzt; `null` z. B. im Distractor-Pool.
  final String? suggestedExerciseType;
}

class SentenceBuilderData {
  const SentenceBuilderData({
    required this.exerciseId,
    required this.nativePrompt,
    required this.targetWords,
  });
  final String exerciseId;
  final String nativePrompt;
  final List<String> targetWords;
}

class LessonData {
  const LessonData({
    required this.lessonId,
    required this.title,
    required this.steps,
    required this.sentences,
    required this.allVocab,
  });
  final String lessonId;
  final String title;
  final List<VocabStepData> steps;
  final List<SentenceBuilderData> sentences;
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
        ..where((t) =>
            t.lessonId.equals(lessonId) & t.lang.equals(AppConstants.activeLang)))
      .getSingleOrNull();

  // Alle Steps in dieser Lektion (Order beibehalten für Konsistenz)
  final steps = await (db.select(db.lessonSteps)
        ..where((s) => s.lessonId.equals(lessonId))
        ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
      .get();

  final vocabLessonSteps = steps.where((s) => s.itemId != null).toList();
  final exerciseIds = steps.map((s) => s.exerciseId).whereType<String>().toList();

  // Vokabeln
  final stepData = await _loadVocabStepData(db, vocabLessonSteps);

  // Sentence-Builder-Übungen
  final sentences = await _loadSentenceBuilders(db, exerciseIds);

  // Alle Vokabeln für MC-Distractors
  final allVocab = await _loadAllVocab(db);

  return LessonData(
    lessonId: lessonId,
    title: lt?.title ?? lessonId,
    steps: stepData,
    sentences: sentences,
    allVocab: allVocab,
  );
}

Future<List<VocabStepData>> _loadVocabStepData(
    AppDatabase db, List<LessonStep> vocabLessonSteps) async {
  if (vocabLessonSteps.isEmpty) return const [];

  final itemIds = vocabLessonSteps.map((s) => s.itemId!).toList();

  final vocabItems = await (db.select(db.vocabItems)
        ..where((v) => v.itemId.isIn(itemIds)))
      .get();
  final vocabMap = {for (final v in vocabItems) v.itemId: v};

  final translations = await (db.select(db.itemTranslations)
        ..where(
            (t) => t.itemId.isIn(itemIds) & t.lang.equals(AppConstants.activeLang)))
      .get();
  final transMap = {for (final t in translations) t.itemId: t.translation};

  return vocabLessonSteps.map((s) {
    final id = s.itemId!;
    final v = vocabMap[id];
    return VocabStepData(
      itemId: id,
      target: v?.front ?? id,
      native: transMap[id] ?? '',
      partOfSpeech: v?.partOfSpeech,
      suggestedExerciseType: s.suggestedExerciseType,
    );
  }).toList();
}

Future<List<SentenceBuilderData>> _loadSentenceBuilders(
    AppDatabase db, List<String> exerciseIds) async {
  if (exerciseIds.isEmpty) return const [];

  final exercises = await (db.select(db.exercises)
        ..where((e) =>
            e.id.isIn(exerciseIds) & e.type.equals('sentence_builder')))
      .get();

  final translations = await (db.select(db.exerciseTranslations)
        ..where((t) =>
            t.exerciseId.isIn(exerciseIds) &
            t.lang.equals(AppConstants.activeLang)))
      .get();
  final promptMap = {for (final t in translations) t.exerciseId: t.prompt};

  return exercises.map((e) {
    final payload = jsonDecode(e.payload ?? '{}') as Map<String, dynamic>;
    final words = (payload['words'] as List).cast<String>();
    return SentenceBuilderData(
      exerciseId: e.id,
      nativePrompt: promptMap[e.id] ?? '',
      targetWords: words,
    );
  }).toList();
}

Future<List<VocabStepData>> _loadAllVocab(AppDatabase db) async {
  final all = await db.select(db.vocabItems).get();
  final allTrans = await (db.select(db.itemTranslations)
        ..where((t) => t.lang.equals(AppConstants.activeLang)))
      .get();
  final transMap = {for (final t in allTrans) t.itemId: t.translation};
  return all
      .map((v) => VocabStepData(
            itemId: v.itemId,
            target: v.front,
            native: transMap[v.itemId] ?? '',
            partOfSpeech: v.partOfSpeech,
          ))
      .toList();
}
