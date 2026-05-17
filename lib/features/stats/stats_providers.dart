import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/database/providers.dart';

class DayActivity {
  const DayActivity({
    required this.date,
    required this.itemsDone,
    required this.goalMet,
  });
  final DateTime date;
  final int itemsDone;
  final bool goalMet;
}

class StatsData {
  const StatsData({
    required this.vocabTotal,
    required this.vocabMastered,
    required this.vocabInDailyDrill,
    required this.lessonsCompleted,
    required this.avgScore,
    required this.currentStreak,
    required this.last30Days,
    required this.goalMetRate30d,
  });

  final int vocabTotal;
  final int vocabMastered;
  final int vocabInDailyDrill;
  final int lessonsCompleted;
  final int? avgScore; // 0..100, null wenn keine Lektion gewertet
  final int currentStreak;
  final List<DayActivity> last30Days;
  final double goalMetRate30d; // 0..1
}

final statsProvider = FutureProvider.autoDispose<StatsData>((ref) async {
  final db = ref.watch(appDatabaseProvider);

  // ── Vokabeln ────────────────────────────────────────────────────────────
  final reviews = await db.select(db.reviewState).get();
  final vocabTotal = reviews.length;
  final vocabMastered = reviews.where((r) => r.masteredAt != null).length;
  final vocabInDailyDrill = vocabTotal - vocabMastered;

  // ── Lektionen ───────────────────────────────────────────────────────────
  final progress = await db.select(db.lessonProgress).get();
  final completed =
      progress.where((p) => p.status == 'completed').toList();
  final lessonsCompleted = completed.length;
  final scored = completed.where((p) => p.score != null).toList();
  final avgScore = scored.isEmpty
      ? null
      : (scored.map((p) => p.score!).reduce((a, b) => a + b) / scored.length)
          .round();

  // ── Aktivität (letzte 30 Tage) ──────────────────────────────────────────
  final activities = await (db.select(db.dailyActivity)
        ..orderBy([(a) => OrderingTerm.asc(a.date)]))
      .get();
  final actMap = {for (final a in activities) a.date: a};

  final today = DateTime.now();
  final today0 = DateTime(today.year, today.month, today.day);
  final last30 = <DayActivity>[];
  for (var i = 29; i >= 0; i--) {
    final d = today0.subtract(Duration(days: i));
    final key = _dateStr(d);
    final row = actMap[key];
    last30.add(DayActivity(
      date: d,
      itemsDone: row?.itemsDone ?? 0,
      goalMet: row?.goalMet ?? false,
    ));
  }
  final goalMetCount = last30.where((d) => d.goalMet).length;
  final goalMetRate30d = goalMetCount / 30.0;

  final currentStreak = _calcStreak(activities, today0);

  return StatsData(
    vocabTotal: vocabTotal,
    vocabMastered: vocabMastered,
    vocabInDailyDrill: vocabInDailyDrill,
    lessonsCompleted: lessonsCompleted,
    avgScore: avgScore,
    currentStreak: currentStreak,
    last30Days: last30,
    goalMetRate30d: goalMetRate30d,
  );
});

// ── Helpers ──────────────────────────────────────────────────────────────────

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

int _calcStreak(List<DailyActivityData> activities, DateTime today0) {
  final met = {for (final a in activities) if (a.goalMet) a.date};
  if (met.isEmpty) return 0;
  var check = today0;
  if (!met.contains(_dateStr(check))) {
    check = check.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (met.contains(_dateStr(check))) {
    streak++;
    check = check.subtract(const Duration(days: 1));
  }
  return streak;
}
