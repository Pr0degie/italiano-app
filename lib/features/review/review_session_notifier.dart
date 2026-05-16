import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/database/providers.dart';
import '../../core/sm2/sm2.dart';
import '../home/home_providers.dart';
import '../lesson/lesson_providers.dart';

// ── State ─────────────────────────────────────────────────────────────────────

@immutable
class McOption {
  const McOption({required this.text, required this.isCorrect});
  final String text;
  final bool isCorrect;
}

@immutable
class ReviewExerciseStep {
  const ReviewExerciseStep({
    required this.itemId,
    required this.reviewEasiness,
    required this.reviewInterval,
    required this.reviewRepetitions,
    required this.consecutiveCorrectDays,
    required this.lastReviewedDate,
    required this.masteredAt,
    required this.vocab,
    required this.showItaliano,
    required this.options,
  });
  final String itemId;
  final double reviewEasiness;
  final int reviewInterval;
  final int reviewRepetitions;
  final int consecutiveCorrectDays;
  final String? lastReviewedDate;
  final DateTime? masteredAt;
  final VocabStepData vocab;
  final bool showItaliano;
  final List<McOption> options;
}

enum ReviewPhase { loading, exercise, done }

@immutable
class ReviewSessionState {
  const ReviewSessionState({
    required this.phase,
    required this.steps,
    required this.currentIndex,
    required this.results,
    required this.selectedOption,
    required this.retryQueue,
    required this.retryCount,
    this.error,
  });

  factory ReviewSessionState.loading() => const ReviewSessionState(
        phase: ReviewPhase.loading,
        steps: [],
        currentIndex: 0,
        results: {},
        selectedOption: null,
        retryQueue: [],
        retryCount: {},
      );

  final ReviewPhase phase;
  final List<ReviewExerciseStep> steps;
  final int currentIndex;
  final Map<int, bool> results;
  final int? selectedOption;

  /// Items die heute falsch waren — werden nach der Hauptqueue wiederholt.
  final List<ReviewExerciseStep> retryQueue;

  /// itemId → wie oft heute in die retryQueue gewandert (max 3).
  final Map<String, int> retryCount;

  final String? error;

  bool get isAnswered => selectedOption != null;

  bool get isInRetryPhase => currentIndex >= steps.length;

  ReviewExerciseStep? get currentStep {
    if (isInRetryPhase) {
      final retryIndex = currentIndex - steps.length;
      if (retryIndex < retryQueue.length) return retryQueue[retryIndex];
      return null;
    }
    if (currentIndex < steps.length) return steps[currentIndex];
    return null;
  }

  ReviewSessionState copyWith({
    ReviewPhase? phase,
    List<ReviewExerciseStep>? steps,
    int? currentIndex,
    Map<int, bool>? results,
    int? selectedOption,
    bool clearSelected = false,
    List<ReviewExerciseStep>? retryQueue,
    Map<String, int>? retryCount,
    String? error,
  }) =>
      ReviewSessionState(
        phase: phase ?? this.phase,
        steps: steps ?? this.steps,
        currentIndex: currentIndex ?? this.currentIndex,
        results: results ?? this.results,
        selectedOption:
            clearSelected ? null : (selectedOption ?? this.selectedOption),
        retryQueue: retryQueue ?? this.retryQueue,
        retryCount: retryCount ?? this.retryCount,
        error: error ?? this.error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

const _maxRetriesPerItem = 3;

class ReviewSessionNotifier extends Notifier<ReviewSessionState> {
  final _rng = Random();

  String get _today {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  ReviewSessionState build() {
    Future.microtask(_init);
    return ReviewSessionState.loading();
  }

  Future<void> _init() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final now = DateTime.now();
      final today = _today;

      final allStates = await db.select(db.reviewState).get();

      final dueStates = allStates.where((r) {
        if (r.masteredAt == null) {
          // Phase 1: täglich bis Mastery — fällig wenn heute noch nicht gemacht
          return r.lastReviewedDate != today;
        } else {
          // Phase 2: SM-2 Langzeit
          return r.dueDate != null && !r.dueDate!.isAfter(now);
        }
      }).toList();

      if (dueStates.isEmpty) {
        state = state.copyWith(phase: ReviewPhase.done);
        return;
      }

      final allVocabItems = await db.select(db.vocabItems).get();
      final allTrans = await db.select(db.itemTranslations).get();
      final transDE = allTrans.where((t) => t.lang == 'de').toList();
      final vocabMap = {for (final v in allVocabItems) v.itemId: v};
      final transMap = {for (final t in transDE) t.itemId: t.translation};

      final allVocab = allVocabItems
          .map((v) => VocabStepData(
                itemId: v.itemId,
                italiano: v.front,
                translationDe: transMap[v.itemId] ?? '',
                partOfSpeech: v.partOfSpeech,
              ))
          .toList();

      final steps = <ReviewExerciseStep>[];
      for (final rs in dueStates) {
        final v = vocabMap[rs.itemId];
        final vocab = VocabStepData(
          itemId: rs.itemId,
          italiano: v?.front ?? rs.itemId,
          translationDe: transMap[rs.itemId] ?? '',
          partOfSpeech: v?.partOfSpeech,
        );
        final showIT = _rng.nextBool();
        final options = _buildOptions(vocab, showIT, allVocab);
        steps.add(ReviewExerciseStep(
          itemId: rs.itemId,
          reviewEasiness: rs.easiness,
          reviewInterval: rs.interval,
          reviewRepetitions: rs.repetitions,
          consecutiveCorrectDays: rs.consecutiveCorrectDays,
          lastReviewedDate: rs.lastReviewedDate,
          masteredAt: rs.masteredAt,
          vocab: vocab,
          showItaliano: showIT,
          options: options,
        ));
      }
      steps.shuffle(_rng);

      state = state.copyWith(
        phase: ReviewPhase.exercise,
        steps: steps,
        currentIndex: 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  List<McOption> _buildOptions(
      VocabStepData correct, bool showItaliano, List<VocabStepData> all) {
    final correctText =
        showItaliano ? correct.translationDe : correct.italiano;
    final pool =
        all.where((v) => v.itemId != correct.itemId).toList()..shuffle(_rng);
    final distractors = pool.take(3).map((v) => McOption(
          text: showItaliano ? v.translationDe : v.italiano,
          isCorrect: false,
        )).toList();
    // Auffüllen falls weniger als 3 Distraktoren vorhanden
    while (distractors.length < 3) {
      distractors.add(McOption(text: '—', isCorrect: false));
    }
    return [McOption(text: correctText, isCorrect: true), ...distractors]
      ..shuffle(_rng);
  }

  void selectOption(int optionIndex) {
    if (state.isAnswered) return;
    state = state.copyWith(selectedOption: optionIndex);
  }

  void advance() {
    if (!state.isAnswered) return;

    final step = state.currentStep!;
    final correct = step.options[state.selectedOption!].isCorrect;

    final newResults = Map<int, bool>.from(state.results);
    newResults[state.currentIndex] = correct;

    _applyResult(step, correct);

    var newRetryQueue = List<ReviewExerciseStep>.from(state.retryQueue);
    var newRetryCount = Map<String, int>.from(state.retryCount);

    if (!correct) {
      // Falsch: in retryQueue wenn Limit nicht erreicht
      final count = newRetryCount[step.itemId] ?? 0;
      if (count < _maxRetriesPerItem) {
        newRetryQueue.add(step);
        newRetryCount[step.itemId] = count + 1;
      }
    }

    final next = state.currentIndex + 1;
    final totalAvailable = state.steps.length + newRetryQueue.length;

    if (next >= totalAvailable) {
      state = state.copyWith(
        phase: ReviewPhase.done,
        results: newResults,
        retryQueue: newRetryQueue,
        retryCount: newRetryCount,
        clearSelected: true,
      );
      _recordActivity(state.results.length);
    } else {
      state = state.copyWith(
        currentIndex: next,
        results: newResults,
        retryQueue: newRetryQueue,
        retryCount: newRetryCount,
        clearSelected: true,
      );
    }
  }

  Future<void> _applyResult(ReviewExerciseStep step, bool correct) async {
    final db = ref.read(appDatabaseProvider);
    final today = _today;
    final now = DateTime.now();

    final isPhase2 = step.masteredAt != null;

    if (isPhase2) {
      if (!correct) {
        // Falsch in Phase 2 → zurück in Phase 1
        await db.into(db.reviewState).insertOnConflictUpdate(
              ReviewStateCompanion.insert(
                itemId: step.itemId,
                easiness: Value(step.reviewEasiness),
                interval: Value(step.reviewInterval),
                repetitions: Value(step.reviewRepetitions),
                consecutiveCorrectDays: const Value(0),
                lastReviewedDate: const Value(null),
                masteredAt: const Value(null),
                dueDate: const Value(null),
                lastReviewed: Value(now),
              ),
            );
      } else {
        // Richtig in Phase 2 → SM-2 weiter
        final sm2 = SM2.apply(
          easiness: step.reviewEasiness,
          interval: step.reviewInterval,
          repetitions: step.reviewRepetitions,
          correct: true,
        );
        await db.into(db.reviewState).insertOnConflictUpdate(
              ReviewStateCompanion.insert(
                itemId: step.itemId,
                easiness: Value(sm2.easiness),
                interval: Value(sm2.interval),
                repetitions: Value(sm2.repetitions),
                consecutiveCorrectDays:
                    Value(step.consecutiveCorrectDays),
                lastReviewedDate: Value(today),
                masteredAt: Value(step.masteredAt),
                dueDate: Value(sm2.dueDate),
                lastReviewed: Value(now),
              ),
            );
      }
      return;
    }

    // Phase 1
    if (!correct) {
      // Streak reset; lastReviewedDate NICHT updaten → Item bleibt heute fällig
      await (db.update(db.reviewState)
            ..where((r) => r.itemId.equals(step.itemId)))
          .write(ReviewStateCompanion(
        consecutiveCorrectDays: const Value(0),
        lastReviewed: Value(now),
      ));
      return;
    }

    // Richtig in Phase 1
    // Retry (in retryCount) = Same-Day → streak nicht erhöhen
    final isRetry = (state.retryCount[step.itemId] ?? 0) > 0;
    final newStreak =
        isRetry ? step.consecutiveCorrectDays : step.consecutiveCorrectDays + 1;

    if (newStreak >= 3) {
      // Mastery erreicht → SM-2 starten
      final sm2 = SM2.applyAfterMastery(easiness: step.reviewEasiness);
      await db.into(db.reviewState).insertOnConflictUpdate(
            ReviewStateCompanion.insert(
              itemId: step.itemId,
              easiness: Value(sm2.easiness),
              interval: Value(sm2.interval),
              repetitions: Value(sm2.repetitions),
              consecutiveCorrectDays: Value(newStreak),
              lastReviewedDate: Value(today),
              masteredAt: Value(now),
              dueDate: Value(sm2.dueDate),
              lastReviewed: Value(now),
            ),
          );
    } else {
      await db.into(db.reviewState).insertOnConflictUpdate(
            ReviewStateCompanion.insert(
              itemId: step.itemId,
              easiness: Value(step.reviewEasiness),
              interval: Value(step.reviewInterval),
              repetitions: Value(step.reviewRepetitions),
              consecutiveCorrectDays: Value(newStreak),
              lastReviewedDate: Value(today),
              masteredAt: const Value(null),
              dueDate: const Value(null),
              lastReviewed: Value(now),
            ),
          );
    }
  }

  Future<void> _recordActivity(int count) async {
    final db = ref.read(appDatabaseProvider);
    await recordItemsDone(db, count);
  }
}

final reviewSessionProvider =
    NotifierProvider.autoDispose<ReviewSessionNotifier, ReviewSessionState>(
  ReviewSessionNotifier.new,
);
