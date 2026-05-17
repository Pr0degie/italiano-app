import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/multiple_choice_widget.dart';
import '../../core/widgets/flash_card.dart';
import '../../core/widgets/pair_widget.dart';
import '../../core/widgets/sentence_builder_widget.dart';
import '../home/home_providers.dart';
import 'lesson_session_notifier.dart';

class LessonPlayerScreen extends ConsumerWidget {
  const LessonPlayerScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(lessonSessionProvider(lessonId));
    return switch (session.phase) {
      LessonPhase.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      LessonPhase.intro =>
          _IntroScreen(lessonId: lessonId, session: session),
      LessonPhase.exercise =>
          _ExerciseScreen(lessonId: lessonId, session: session),
      LessonPhase.done => _DoneScreen(session: session),
    };
  }
}

// ── Intro ─────────────────────────────────────────────────────────────────────

class _IntroScreen extends ConsumerStatefulWidget {
  const _IntroScreen({required this.lessonId, required this.session});
  final String lessonId;
  final LessonSessionState session;

  @override
  ConsumerState<_IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<_IntroScreen> {
  final _cardCtrl = FlashCardController();

  @override
  void didUpdateWidget(_IntroScreen old) {
    super.didUpdateWidget(old);
    if (old.session.currentIndex != widget.session.currentIndex) {
      _cardCtrl.reset();
    }
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!_cardCtrl.isFlipped) {
      _cardCtrl.flip();
    } else {
      ref.read(lessonSessionProvider(widget.lessonId).notifier).nextIntroStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final step = session.steps[session.currentIndex];
    final total = session.steps.length;
    final current = session.currentIndex + 1;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Einführung $current/$total'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: current / total),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlashCard(
              controller: _cardCtrl,
              onTap: _onTap,
              minHeight: 220,
              front: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(step.target,
                      style: tt.displaySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ],
              ),
              back: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(step.target,
                      style: tt.displaySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  if (step.partOfSpeech != null) ...[
                    const SizedBox(height: 14),
                    Text(step.partOfSpeech!,
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.45),
                            fontSize: 13)),
                    const SizedBox(height: 14),
                  ] else
                    const SizedBox(height: 24),
                  Text(step.native,
                      style: tt.headlineSmall,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exercise Router ───────────────────────────────────────────────────────────

class _ExerciseScreen extends ConsumerWidget {
  const _ExerciseScreen({required this.lessonId, required this.session});
  final String lessonId;
  final LessonSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = session.exerciseSteps.length;
    final current = session.currentIndex + 1;
    final step = session.exerciseSteps[session.currentIndex];
    final notifier = ref.read(lessonSessionProvider(lessonId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Übung $current/$total'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: current / total),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: switch (step) {
            MCExerciseStep s => _MCExerciseBody(
                key: ValueKey('mc-${session.currentIndex}'),
                step: s,
                onAnswer: notifier.answerExercise,
              ),
            SentenceBuilderStep s => SentenceBuilderWidget(
                key: ValueKey('sb-${session.currentIndex}'),
                nativeSentence: s.nativePrompt,
                targetWords: s.targetWords,
                onComplete: notifier.answerExercise,
              ),
            PairExerciseStep s => PairWidget(
                key: ValueKey('pair-${session.currentIndex}'),
                targets: s.vocab.map((v) => v.target).toList(),
                natives: s.vocab.map((v) => v.native).toList(),
                onComplete: notifier.answerExercise,
              ),
          },
        ),
      ),
    );
  }
}

// ── MC Exercise Body ──────────────────────────────────────────────────────────

class _MCExerciseBody extends StatefulWidget {
  const _MCExerciseBody({super.key, required this.step, required this.onAnswer});
  final MCExerciseStep step;
  final void Function(bool correct) onAnswer;

  @override
  State<_MCExerciseBody> createState() => _MCExerciseBodyState();
}

class _MCExerciseBodyState extends State<_MCExerciseBody> {
  final _cardCtrl = FlashCardController();

  String? _selected;
  bool _isCorrect = false;
  bool _flipping = false;
  Color? _cardColor;
  bool _pendingAnswer = false;

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

  void _onSelect(String option, String correct) {
    if (_selected != null) return;
    _isCorrect = option == correct;
    _pendingAnswer = true;
    setState(() {
      _selected = option;
      _cardColor = _isCorrect ? Colors.green[600] : Colors.red[600];
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _flipping = true);
        _cardCtrl.flip();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final correct = step.vocab.native;
    final wordWidget = Text(
      step.vocab.target,
      style: Theme.of(context)
          .textTheme
          .displaySmall
          ?.copyWith(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FlashCard(
          controller: _cardCtrl,
          color: _cardColor,
          minHeight: 140,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          front: Center(child: wordWidget),
          back: Center(child: wordWidget),
          onFlipMidpoint: () {
            if (!_pendingAnswer) return;
            _pendingAnswer = false;
            final wasCorrect = _isCorrect;
            setState(() {
              _cardColor = null;
              _selected = null;
            });
            widget.onAnswer(wasCorrect);
          },
          onFlipComplete: () {
            _cardCtrl.reset();
            setState(() {
              _flipping = false;
              _selected = null;
            });
          },
        ),
        const SizedBox(height: 32),
        MultipleChoiceWidget(
          options: step.options,
          correct: correct,
          selected: _selected,
          onSelect: (option) => _onSelect(option, correct),
        ),
      ],
    );
  }
}

// ── Done ──────────────────────────────────────────────────────────────────────

class _DoneScreen extends ConsumerWidget {
  const _DoneScreen({required this.session});
  final LessonSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correct = session.results.values.where((v) => v).length;
    final total = session.exerciseSteps.length;
    final pct = total > 0 ? (correct / total * 100).round() : 0;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(pct >= 80 ? '🎉' : '💪',
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('Lektion abgeschlossen!',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('$correct / $total richtig ($pct%)',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  ref.invalidate(homeDataProvider);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52)),
                child: const Text('Weiter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
