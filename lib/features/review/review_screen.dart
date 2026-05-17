import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_service.dart';
import '../../core/widgets/multiple_choice_widget.dart';
import 'review_session_notifier.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(reviewSessionProvider);
    return switch (session.phase) {
      ReviewPhase.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      ReviewPhase.exercise => _ReviewExerciseScreen(session: session),
      ReviewPhase.done => _ReviewDoneScreen(session: session),
    };
  }
}

class _ReviewDoneScreen extends StatelessWidget {
  const _ReviewDoneScreen({required this.session});
  final ReviewSessionState session;

  @override
  Widget build(BuildContext context) {
    final hadItems = session.steps.isNotEmpty;
    final correct = session.results.values.where((v) => v).length;
    final total = session.results.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Wiederholen')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(hadItems ? '✅' : '🎯',
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(hadItems ? 'Alles erledigt!' : 'Nichts fällig',
                  style: Theme.of(context).textTheme.headlineMedium),
              if (hadItems) ...[
                const SizedBox(height: 8),
                Text('$correct / $total richtig',
                    style: Theme.of(context).textTheme.bodyLarge),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Mach zuerst ein paar Lektionen,\ndann kommen Items hierher.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewExerciseScreen extends ConsumerWidget {
  const _ReviewExerciseScreen({required this.session});
  final ReviewSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = session.currentStep;
    if (step == null) return const SizedBox.shrink();

    final notifier = ref.read(reviewSessionProvider.notifier);
    final totalSteps = session.steps.length + session.retryQueue.length;
    final current = session.currentIndex + 1;

    final isRetry = session.isInRetryPhase;
    final questionText =
        step.showTarget ? step.vocab.target : step.vocab.native;
    final questionLabel = step.showTarget
        ? 'Wie heißt auf Deutsch?'
        : 'Wie heißt auf Italienisch?';

    final options = step.options.map((o) => o.text).toList();
    final correct = step.options.firstWhere((o) => o.isCorrect).text;
    final selected = session.selectedOption != null
        ? step.options[session.selectedOption!].text
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRetry
            ? 'Wiederholen – nochmal'
            : 'Wiederholen $current/$totalSteps'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: current / totalSteps),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: session.isAnswered ? notifier.advance : null,
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                questionLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onLongPress: () =>
                    ref.read(audioServiceProvider).speak(step.vocab.target),
                child: Text(
                  questionText,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              MultipleChoiceWidget(
                options: options,
                correct: correct,
                selected: selected,
                onSelect: (text) {
                  final idx = step.options.indexWhere((o) => o.text == text);
                  if (idx != -1) notifier.selectOption(idx);
                },
              ),
              const SizedBox(height: 16),
              if (session.isAnswered)
                Text(
                  'Tippen zum Weitergehen',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4)),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
