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
    required this.vocab,
    required this.showItaliano,
    required this.options,
  });
  final String itemId;
  final double reviewEasiness;
  final int reviewInterval;
  final int reviewRepetitions;
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
    this.error,
  });

  factory ReviewSessionState.loading() => const ReviewSessionState(
        phase: ReviewPhase.loading,
        steps: [],
        currentIndex: 0,
        results: {},
        selectedOption: null,
      );

  final ReviewPhase phase;
  final List<ReviewExerciseStep> steps;
  final int currentIndex;
  final Map<int, bool> results;
  final int? selectedOption;
  final String? error;

  bool get isAnswered => selectedOption != null;

  ReviewSessionState copyWith({
    ReviewPhase? phase,
    List<ReviewExerciseStep>? steps,
    int? currentIndex,
    Map<int, bool>? results,
    int? selectedOption,
    bool clearSelected = false,
    String? error,
  }) =>
      ReviewSessionState(
        phase: phase ?? this.phase,
        steps: steps ?? this.steps,
        currentIndex: currentIndex ?? this.currentIndex,
        results: results ?? this.results,
        selectedOption:
            clearSelected ? null : (selectedOption ?? this.selectedOption),
        error: error ?? this.error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ReviewSessionNotifier
    extends Notifier<ReviewSessionState> {
  final _rng = Random();

  @override
  ReviewSessionState build() {
    Future.microtask(_init);
    return ReviewSessionState.loading();
  }

  Future<void> _init() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final now = DateTime.now();

      // Load all review states, filter due items in Dart
      final allStates = await db.select(db.reviewState).get();
      final dueStates =
          allStates.where((r) => !r.dueDate.isAfter(now)).toList();

      if (dueStates.isEmpty) {
        state = state.copyWith(phase: ReviewPhase.done);
        return;
      }

      // Load all vocab + translations for matching and distractors
      final allVocabItems = await db.select(db.vocabItems).get();
      final allTrans = await db.select(db.itemTranslations).get();
      final transDE = allTrans.where((t) => t.lang == 'de').toList();
      final vocabMap = {for (final v in allVocabItems) v.itemId: v};
      final transMap = {for (final t in transDE) t.itemId: t.translation};

      final allVocab = allVocabItems.map((v) => VocabStepData(
            itemId: v.itemId,
            italiano: v.front,
            translationDe: transMap[v.itemId] ?? '',
            partOfSpeech: v.partOfSpeech,
          )).toList();

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
        ));
    return [McOption(text: correctText, isCorrect: true), ...distractors]
      ..shuffle(_rng);
  }

  void selectOption(int optionIndex) {
    if (state.isAnswered) return;
    state = state.copyWith(selectedOption: optionIndex);
  }

  void advance() {
    if (!state.isAnswered) return;
    final step = state.steps[state.currentIndex];
    final correct = step.options[state.selectedOption!].isCorrect;
    final newResults = Map<int, bool>.from(state.results);
    newResults[state.currentIndex] = correct;

    _applySm2(step, correct);

    final next = state.currentIndex + 1;
    if (next >= state.steps.length) {
      state = state.copyWith(
          phase: ReviewPhase.done, results: newResults, clearSelected: true);
      _recordActivity(state.steps.length);
    } else {
      state = state.copyWith(
          currentIndex: next, results: newResults, clearSelected: true);
    }
  }

  Future<void> _applySm2(ReviewExerciseStep step, bool correct) async {
    final db = ref.read(appDatabaseProvider);
    final sm2 = SM2.apply(
      easiness: step.reviewEasiness,
      interval: step.reviewInterval,
      repetitions: step.reviewRepetitions,
      correct: correct,
    );
    await db.into(db.reviewState).insertOnConflictUpdate(
          ReviewStateCompanion.insert(
            itemId: step.itemId,
            easiness: Value(sm2.easiness),
            interval: Value(sm2.interval),
            repetitions: Value(sm2.repetitions),
            dueDate: sm2.dueDate,
            lastReviewed: Value(DateTime.now()),
          ),
        );
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
