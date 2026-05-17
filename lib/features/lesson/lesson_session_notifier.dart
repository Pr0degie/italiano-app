import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/database/providers.dart';
import '../home/home_providers.dart';
import 'lesson_providers.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum LessonPhase { loading, intro, exercise, done }

sealed class AnyExerciseStep {}

@immutable
class MCExerciseStep extends AnyExerciseStep {
  MCExerciseStep({required this.vocab, required this.options});
  final VocabStepData vocab;
  final List<String> options; // 4 shuffled native translations, one correct
}

@immutable
class SentenceBuilderStep extends AnyExerciseStep {
  SentenceBuilderStep({required this.nativePrompt, required this.targetWords});

  /// Satz in der Muttersprache (Frage).
  final String nativePrompt;

  /// Wörter in der Zielsprache in korrekter Reihenfolge.
  final List<String> targetWords;
}

@immutable
class PairExerciseStep extends AnyExerciseStep {
  PairExerciseStep({required this.vocab});

  /// Vokabeln, die in dieser Übung gepaart werden sollen (typisch 4).
  final List<VocabStepData> vocab;
}

@immutable
class TypingExerciseStep extends AnyExerciseStep {
  TypingExerciseStep({required this.vocab});
  final VocabStepData vocab;
}

// Backwards-compat alias so bestehende call-sites (falls vorhanden) nicht brechen
typedef ExerciseStep = MCExerciseStep;

@immutable
class LessonSessionState {
  const LessonSessionState({
    required this.phase,
    required this.steps,
    required this.sentences,
    required this.currentIndex,
    required this.exerciseSteps,
    required this.results,
    this.error,
  });

  factory LessonSessionState.loading() => const LessonSessionState(
        phase: LessonPhase.loading,
        steps: [],
        sentences: [],
        currentIndex: 0,
        exerciseSteps: [],
        results: {},
      );

  final LessonPhase phase;
  final List<VocabStepData> steps;
  final List<SentenceBuilderData> sentences;
  final int currentIndex;
  final List<AnyExerciseStep> exerciseSteps;
  final Map<int, bool> results;
  final String? error;

  LessonSessionState copyWith({
    LessonPhase? phase,
    List<VocabStepData>? steps,
    List<SentenceBuilderData>? sentences,
    int? currentIndex,
    List<AnyExerciseStep>? exerciseSteps,
    Map<int, bool>? results,
    String? error,
  }) =>
      LessonSessionState(
        phase: phase ?? this.phase,
        steps: steps ?? this.steps,
        sentences: sentences ?? this.sentences,
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
        sentences: data.sentences,
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
    final allTranslations = state.steps.map((s) => s.native).toList();

    // Vokabeln nach suggestedExerciseType partitionieren
    final pairVocab = <VocabStepData>[];
    final typingVocab = <VocabStepData>[];
    final mcVocab = <VocabStepData>[];
    for (final v in state.steps) {
      switch (v.suggestedExerciseType ?? 'mc') {
        case 'pair':
          pairVocab.add(v);
          break;
        case 'typing':
          typingVocab.add(v);
          break;
        default:
          mcVocab.add(v);
      }
    }

    // Pair: in 4er-Gruppen batchen. Rest <4 → MC-Fallback.
    const pairSize = 4;
    final pairSteps = <AnyExerciseStep>[];
    for (var i = 0; i + pairSize <= pairVocab.length; i += pairSize) {
      pairSteps.add(
          PairExerciseStep(vocab: pairVocab.sublist(i, i + pairSize)));
    }
    final leftover = pairVocab.length % pairSize;
    if (leftover > 0) {
      mcVocab.addAll(pairVocab.sublist(pairVocab.length - leftover));
    }

    final typingSteps =
        typingVocab.map((v) => TypingExerciseStep(vocab: v)).toList();

    final mcSteps =
        mcVocab.map((v) => _buildMC(v, allTranslations)).toList();

    final sentenceSteps = state.sentences
        .map((s) => SentenceBuilderStep(
              nativePrompt: s.nativePrompt,
              targetWords: s.targetWords,
            ))
        .toList();

    final allSteps = <AnyExerciseStep>[
      ...mcSteps,
      ...pairSteps,
      ...typingSteps,
      ...sentenceSteps,
    ]..shuffle(_rng);

    state = state.copyWith(
      phase: LessonPhase.exercise,
      currentIndex: 0,
      exerciseSteps: allSteps,
    );
  }

  MCExerciseStep _buildMC(VocabStepData v, List<String> translationPool) {
    final correct = v.native;
    final distractors =
        translationPool.where((t) => t != correct).toList()..shuffle(_rng);
    final options = [correct, ...distractors.take(3)]..shuffle(_rng);
    return MCExerciseStep(vocab: v, options: options);
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
      // Alle Vokabel-itemIds aus dieser Session sammeln
      final touchedItemIds = <String>{
        for (final step in steps)
          ...switch (step) {
            MCExerciseStep s => [s.vocab.itemId],
            PairExerciseStep s => s.vocab.map((v) => v.itemId),
            TypingExerciseStep s => [s.vocab.itemId],
            SentenceBuilderStep _ => const <String>[],
          },
      };

      // Neue Items in Phase 1 (Daily Drill) eintragen — nur wenn noch kein Eintrag existiert
      for (final itemId in touchedItemIds) {
        final existing = await (db.select(db.reviewState)
              ..where((r) => r.itemId.equals(itemId)))
            .getSingleOrNull();
        if (existing != null) continue; // bereits bekannt, nicht überschreiben
        await db.into(db.reviewState).insertOnConflictUpdate(
              ReviewStateCompanion.insert(
                itemId: itemId,
                // Phase-1-Start: kein dueDate, kein Streak, noch nicht reviewed
                dueDate: const Value(null),
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

      // Items zählen pro Vokabel/Satz (Pair = 4 Items), nicht pro UI-Übung
      final itemCount = steps.fold<int>(
        0,
        (acc, step) => acc + switch (step) {
          MCExerciseStep _ => 1,
          PairExerciseStep s => s.vocab.length,
          TypingExerciseStep _ => 1,
          SentenceBuilderStep _ => 1,
        },
      );
      await recordItemsDone(db, itemCount, isLesson: true);
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
