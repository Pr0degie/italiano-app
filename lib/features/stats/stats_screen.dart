import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stats_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(statsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (data) => _StatsBody(data: data),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.data});
  final StatsData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Vokabeln'),
        Row(children: [
          Expanded(child: _Kpi(label: 'Gesamt', value: '${data.vocabTotal}')),
          const SizedBox(width: 12),
          Expanded(
              child: _Kpi(
                  label: 'Gemastert',
                  value: '${data.vocabMastered}',
                  accent: Colors.green)),
          const SizedBox(width: 12),
          Expanded(
              child: _Kpi(
                  label: 'In Wdh.',
                  value: '${data.vocabInDailyDrill}')),
        ]),
        const SizedBox(height: 24),
        _SectionTitle('Lektionen'),
        Row(children: [
          Expanded(
              child: _Kpi(
                  label: 'Abgeschlossen', value: '${data.lessonsCompleted}')),
          const SizedBox(width: 12),
          Expanded(
              child: _Kpi(
                  label: 'Ø Score',
                  value: data.avgScore == null ? '–' : '${data.avgScore}%')),
        ]),
        const SizedBox(height: 24),
        _SectionTitle('Aktivität (letzte 30 Tage)'),
        Row(children: [
          Expanded(
              child: _Kpi(
                  label: 'Streak',
                  value: '${data.currentStreak}',
                  suffix: ' Tage',
                  emoji: '🔥')),
          const SizedBox(width: 12),
          Expanded(
              child: _Kpi(
                  label: 'Ziel erreicht',
                  value: '${(data.goalMetRate30d * 100).round()}%')),
        ]),
        const SizedBox(height: 16),
        _ActivityBars(days: data.last30Days),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold)),
      );
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    this.suffix,
    this.accent,
    this.emoji,
  });
  final String label;
  final String value;
  final String? suffix;
  final Color? accent;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic, children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
              ],
              Text(value,
                  style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accent)),
              if (suffix != null)
                Text(suffix!,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ActivityBars extends StatelessWidget {
  const _ActivityBars({required this.days});
  final List<DayActivity> days;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxItems =
        days.map((d) => d.itemsDone).fold<int>(0, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: _DayBar(
                          itemsDone: d.itemsDone,
                          maxItems: maxItems,
                          goalMet: d.goalMet,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Text('vor 30 Tagen',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const Spacer(),
              Text('heute',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.itemsDone,
    required this.maxItems,
    required this.goalMet,
  });
  final int itemsDone;
  final int maxItems;
  final bool goalMet;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Min-Höhe für besseren visuellen Eindruck bei nicht-null Tagen
    final ratio = maxItems == 0 ? 0.0 : itemsDone / maxItems;
    final color = itemsDone == 0
        ? cs.surfaceContainerHighest
        : goalMet
            ? Colors.green
            : cs.primary.withValues(alpha: 0.5);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: itemsDone == 0 ? 3 : (ratio * 100).clamp(8, 100),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
