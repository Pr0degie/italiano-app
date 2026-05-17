import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../lesson/lesson_player_screen.dart';
import '../stats/stats_screen.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeDataProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Italiano'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistik',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (data) => _HomeContent(data: data),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.data});
  final HomeData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatsBar(streak: data.streak, goalProgress: data.goalProgress,
            itemsDone: data.itemsDoneToday),
        const SizedBox(height: 20),
        ...data.chapters.map((ch) => _ChapterCard(chapter: ch)),
      ],
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.streak, required this.goalProgress,
      required this.itemsDone});
  final int streak;
  final double goalProgress;
  final int itemsDone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(children: [
              const Text('🔥', style: TextStyle(fontSize: 28)),
              Text('$streak',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Text('Tage', style: TextStyle(fontSize: 12)),
            ]),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tagesziel: $itemsDone / ${AppConstants.dailyGoalItems}',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goalProgress,
                      minHeight: 10,
                      backgroundColor: cs.surfaceContainerHighest,
                      color: goalProgress >= 1.0 ? Colors.green : cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterCard extends StatefulWidget {
  const _ChapterCard({required this.chapter});
  final ChapterSummary chapter;
  @override
  State<_ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<_ChapterCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final ch = widget.chapter;
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(ch.isUnlocked ? Icons.folder_outlined : Icons.lock_outline,
                      size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(ch.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ch.isUnlocked
                                ? null
                                : cs.onSurface.withOpacity(0.4))),
                  ),
                  Text('${(ch.completionRate * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12,
                          color: cs.onSurface.withOpacity(0.6))),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ch.completionRate,
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: ch.completionRate >= 1.0
                        ? Colors.green
                        : ch.isUnlocked
                            ? cs.primary
                            : cs.onSurface.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...ch.lessons.map((l) => _LessonTile(lesson: l)),
      ]),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});
  final LessonSummary lesson;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locked = !lesson.isUnlocked;
    final icon = locked
        ? Icons.lock_outline
        : lesson.isCompleted
            ? Icons.check_circle
            : Icons.play_circle_outline;
    final iconColor = locked
        ? cs.onSurface.withOpacity(0.3)
        : lesson.isCompleted
            ? Colors.green
            : cs.primary;

    return InkWell(
      onTap: locked
          ? null
          : () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) =>
                        LessonPlayerScreen(lessonId: lesson.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Text(lesson.title,
              style: TextStyle(
                  color: locked ? cs.onSurface.withOpacity(0.3) : null)),
        ]),
      ),
    );
  }
}
