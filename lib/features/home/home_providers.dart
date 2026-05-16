import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/database/database.dart';
import '../../core/database/providers.dart';

// ── Data classes ─────────────────────────────────────────────────────────────

class LessonSummary {
  const LessonSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.isUnlocked,
  });
  final String id;
  final String title;
  final String status;
  final bool isUnlocked;
  bool get isCompleted => status == 'completed';
}

class ChapterSummary {
  const ChapterSummary({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.lessons,
    required this.isUnlocked,
  });
  final String id;
  final String title;
  final int sortOrder;
  final List<LessonSummary> lessons;
  final bool isUnlocked;

  double get completionRate {
    if (lessons.isEmpty) return 0;
    return lessons.where((l) => l.isCompleted).length / lessons.length;
  }
}

class HomeData {
  const HomeData({
    required this.chapters,
    required this.streak,
    required this.itemsDoneToday,
  });
  final List<ChapterSummary> chapters;
  final int streak;
  final int itemsDoneToday;
  double get goalProgress =>
      (itemsDoneToday / AppConstants.dailyGoalItems).clamp(0.0, 1.0);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _todayStr() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, "0")}-${n.day.toString().padLeft(2, "0")}';
}

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';

int _calcStreak(List<DailyActivityData> activities) {
  final met = {for (final a in activities) if (a.goalMet) a.date};
  if (met.isEmpty) return 0;
  var check = DateTime.now();
  if (!met.contains(_dateStr(check))) {
    check = check.subtract(const Duration(days: 1));
  }
  int streak = 0;
  while (met.contains(_dateStr(check))) {
    streak++;
    check = check.subtract(const Duration(days: 1));
  }
  return streak;
}

// ── Provider ──────────────────────────────────────────────────────────────────

final homeDataProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final lang = AppConstants.activeLang;

  final chapterRows = await db.select(db.chapters).get()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final chapterTrans = await db.select(db.chapterTranslations).get();
  final ctMap = {
    for (final ct in chapterTrans.where((ct) => ct.lang == lang))
      ct.chapterId: ct.title
  };

  final lessonRows = await db.select(db.lessons).get()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final lessonTrans = await db.select(db.lessonTranslations).get();
  final ltMap = {
    for (final lt in lessonTrans.where((lt) => lt.lang == lang))
      lt.lessonId: lt.title
  };

  final progressRows = await db.select(db.lessonProgress).get();
  final progressMap = {for (final p in progressRows) p.lessonId: p.status};

  final lessonsByChapter = <String, List<Lesson>>{};
  for (final l in lessonRows) {
    (lessonsByChapter[l.chapterId] ??= []).add(l);
  }

  final rawChapters = <ChapterSummary>[];
  for (final ch in chapterRows) {
    final chLessons = lessonsByChapter[ch.id] ?? [];
    final lessonSummaries = chLessons.map((l) => LessonSummary(
      id: l.id,
      title: ltMap[l.id] ?? l.id,
      status: progressMap[l.id] ?? 'not_started',
      isUnlocked: true,
    )).toList();
    rawChapters.add(ChapterSummary(
      id: ch.id,
      title: ctMap[ch.id] ?? ch.id,
      sortOrder: ch.sortOrder,
      lessons: lessonSummaries,
      isUnlocked: true,
    ));
  }

  final chapters = <ChapterSummary>[];
  for (var i = 0; i < rawChapters.length; i++) {
    final ch = rawChapters[i];
    final unlocked = i == 0 || rawChapters[i - 1].completionRate >= 0.8;
    chapters.add(ChapterSummary(
      id: ch.id,
      title: ch.title,
      sortOrder: ch.sortOrder,
      lessons: ch.lessons.map((l) => LessonSummary(
        id: l.id, title: l.title, status: l.status, isUnlocked: unlocked,
      )).toList(),
      isUnlocked: unlocked,
    ));
  }

  final activities = await db.select(db.dailyActivity).get();
  final todayRow = activities.where((a) => a.date == _todayStr()).firstOrNull;

  return HomeData(
    chapters: chapters,
    streak: _calcStreak(activities),
    itemsDoneToday: todayRow?.itemsDone ?? 0,
  );
});

// ── Daily activity helper ─────────────────────────────────────────────────────

Future<void> recordItemsDone(AppDatabase db, int count,
    {bool isLesson = false}) async {
  final today = _todayStr();
  final existing = await (db.select(db.dailyActivity)
        ..where((a) => a.date.equals(today)))
      .getSingleOrNull();
  final newCount = (existing?.itemsDone ?? 0) + count;
  final newLessons = (existing?.lessonsDone ?? 0) + (isLesson ? 1 : 0);
  final goalMet = newCount >= AppConstants.dailyGoalItems;
  await db.into(db.dailyActivity).insertOnConflictUpdate(
        DailyActivityCompanion.insert(
          date: today,
          itemsDone: Value(newCount),
          lessonsDone: Value(newLessons),
          goalMet: Value(goalMet),
        ),
      );
}
