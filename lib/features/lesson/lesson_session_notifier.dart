import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/database/providers.dart';
import '../../core/seeding/sentence_exercises.dart';
import '../../core/sm2/sm2.dart';
import '../home/home_providers.dart';
import 'lesson_providers.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum LessonPhase { loading, intro, exercise, done }

sealed class AnyExerciseStep {}

@immutable
class MCExerciseStep extends AnyExerciseStep {
  MCExerciseStep({required this.vocab, required this.options});
  final VocabStepData vocab;
  final List<String> options; // 4 shuffled German translations, one correct
}

@immutable
class SentenceBuilderStep extends AnyExerciseStep {
  SentenceBuilderStep({required this.german, required this.italianWords});
  final String german;
  final List<String> italianWords; // korrekte Reihenfolge
}

// Backwards-compat alias so bestehende call-sites (falls vorhanden) nicht brechen
typedef ExerciseStep = MCExerciseStep;

@immutable
class LessonSessionState {
  const LessonSessionState({
    required this.phase,
    required this.steps,
    required this.currentIndex,
    required this.exerciseSteps,
    required this.results,
    this.error,
  });

  factory LessonSessionState.loading() => const LessonSessionState(
        phase: LessonPhase.loading,
        steps: [],
        currentIndex: 0,
        exerciseSteps: [],
        results: {},
      );

  final LessonPhase phase;
  final List<VocabStepData> steps;
  final int currentIndex;
  final List<AnyExerciseStep> exerciseSteps;
  final Map<int, bool> results;
  final String? error;

  LessonSessionState copyWith({
    LessonPhase? phase,
    List<VocabStepData>? steps,
    int? currentIndex,
    List<AnyExerciseStep>? exerciseSteps,
    Map<int, bool>? results,
    String? error,
  }) =>
      LessonSessionState(
        phase: phase ?? this.phase,
        steps: steps ?? this.steps,
        currentIndex: currentIndex ?? this.currentIndex,
        exerciseSteps: exerciseSteps ?? this.exerciseSteps,
        results: results ?? this.results,
        error: error ?? this.error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class LessonSessionNotifier extends Notifier<LessonSessionState> {
  LessonSessionNotifier(this._lessonId);
  final _rng = Random();
  final String _lessonId;

  @override
  LessonSessionState build() {
    Future.microtask(_init);
    return LessonSessionState.loading();
  }

  Future<void> _init() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final data = await loadLesson(db, _lessonId);
      final shuffledSteps = data.steps.toList()..shuffle(_rng);
      state = state.copyWith(
        phase: LessonPhase.intro,
        steps: shuffledSteps,
        currentIndex: 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void nextIntroStep() {
    final next = state.currentIndex + 1;
    if (next >= state.steps.length) {
      _buildExercisePhase();
    } else {
      state = state.copyWith(currentIndex: next);
    }
  }

  void _buildExercisePhase() {
    final allTranslations = state.steps.map((s) => s.translationDe).toList();

    // MC-Übungen aus Vokabeln
    final mcSteps = state.steps.map((v) {
      final correct = v.translationDe;
      final distractors =
          (allTranslations.where((t) => t != correct).toList()..shuffle(_rng));
      final options = ([correct, ...distractors.take(3)]..shuffle(_rng));
      return MCExerciseStep(vocab: v, options: options);
    }).toList();

    // Satz-Übungen für diese Lektion
    final sentences = sentencesByLesson[_lessonId] ?? [];
    final sentenceSteps = sentences
        .map((s) => SentenceBuilderStep(
              german: s.german,
              italianWords: s.italian,
            ))
        .toList();

    final allSteps = <AnyExerciseStep>[...mcSteps, ...sentenceSteps]
      ..shuffle(_rng);

    state = state.copyWith(
      phase: LessonPhase.exercise,
      currentIndex: 0,
      exerciseSteps: allSteps,
    );
  }

  void answerExercise(bool correct) {
    final newResults = Map<int, bool>.from(state.results);
    newResults[state.currentIndex] = correct;
    final next = state.currentIndex + 1;
    if (next >= state.exerciseSteps.length) {
      state = state.copyWith(phase: LessonPhase.done, results: newResults);
      _persist(newResults);
    } else {
      state = state.copyWith(currentIndex: next, results: newResults);
    }
  }

  // Backwards-compat
  void answerFlashcard(bool correct) => answerExercise(correct);

  Future<void> _persist(Map<int, bool> results) async {
    final db = ref.read(appDatabaseProvider);
    final steps = state.exerciseSteps;
    final now = DateTime.now();

    await db.transaction(() async {
      // Nur MC-Steps haben itemId für SM-2
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        if (step is! MCExerciseStep) continue;
        final itemId = step.vocab.itemId;
        final correct = results[i] ?? false;
        final existing = await (db.select(db.reviewState)
              ..where((r) => r.itemId.equals(itemId)))
            .getSingleOrNull();
        final sm2 = SM2.apply(
          easiness: existing?.easiness ?? 2.5,
          interval: existing?.interval ?? 0,
          repetitions: existing?.repetitions ?? 0,
          correct: correct,
        );
        await db.into(db.reviewState).insertOnConflictUpdate(
              ReviewStateCompanion.insert(
                itemId: itemId,
                easiness: Value(sm2.easiness),
                interval: Value(sm2.interval),
                repetitions: Value(sm2.repetitions),
                dueDate: sm2.dueDate,
                lastReviewed: Value(now),
              ),
            );
      }

      final correctCount = results.values.where((v) => v).length;
      final score =
          steps.isNotEmpty ? ((correctCount / steps.length) * 100).round() : 0;
      await db.into(db.lessonProgress).insertOnConflictUpdate(
            LessonProgressCompanion.insert(
              lessonId: _lessonId,
              status: 'completed',
              score: Value(score),
              completedAt: Value(now),
              updatedAt: now,
            ),
          );

      await recordItemsDone(db, steps.length);
    });
  }
}

// Cache by lessonId so same string → same provider object → Riverpod reuses state
final _lessonSessionCache = <String, dynamic>{};

NotifierProvider<LessonSessionNotifier, LessonSessionState>
    lessonSessionProvider(String lessonId) =>
        (_lessonSessionCache[lessonId] ??=
            NotifierProvider.autoDispose<LessonSessionNotifier,
                LessonSessionState>(
              () => LessonSessionNotifier(lessonId),
            ))
            as NotifierProvider<LessonSessionNotifier, LessonSessionState>;
