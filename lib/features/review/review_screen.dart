import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final total = session.steps.length;

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
                Text('Mach zuerst ein paar Lektionen,\ndann kommen Items hierher.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
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
    final step = session.steps[session.currentIndex];
    final total = session.steps.length;
    final current = session.currentIndex + 1;
    final notifier = ref.read(reviewSessionProvider.notifier);

    final questionText = step.showItaliano
        ? step.vocab.italiano
        : step.vocab.translationDe;
    final questionLabel = step.showItaliano
        ? 'Wie heißt auf Deutsch?'
        : 'Wie heißt auf Italienisch?';

    return Scaffold(
      appBar: AppBar(
        title: Text('Wiederholen $current/$total'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: current / total),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(questionLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5)),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(questionText,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const Spacer(),
            ...step.options.asMap().entries.map((e) => _OptionTile(
                  text: e.value.text,
                  isCorrect: e.value.isCorrect,
                  isSelected: session.selectedOption == e.key,
                  isAnswered: session.isAnswered,
                  onTap: session.isAnswered
                      ? null
                      : () => notifier.selectOption(e.key),
                )),
            const SizedBox(height: 16),
            if (session.isAnswered)
              FilledButton(
                onPressed: notifier.advance,
                style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52)),
                child: Text(current == total ? 'Fertig' : 'Weiter'),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.isCorrect,
    required this.isSelected,
    required this.isAnswered,
    this.onTap,
  });
  final String text;
  final bool isCorrect;
  final bool isSelected;
  final bool isAnswered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color? borderColor;
    IconData? trailingIcon;
    if (isAnswered) {
      if (isCorrect) {
        bgColor = Colors.green.withOpacity(0.15);
        borderColor = Colors.green;
        trailingIcon = Icons.check;
      } else if (isSelected) {
        bgColor = Colors.red.withOpacity(0.15);
        borderColor = Colors.red;
        trailingIcon = Icons.close;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(
              color: borderColor ??
                  Theme.of(context).colorScheme.outline.withOpacity(0.4),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Expanded(child: Text(text,
                style: Theme.of(context).textTheme.bodyLarge)),
            if (trailingIcon != null)
              Icon(trailingIcon,
                  color: isCorrect ? Colors.green : Colors.red),
          ]),
        ),
      ),
    );
  }
}
