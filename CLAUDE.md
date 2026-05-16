# italiano-app — Claude-Arbeitsanweisung

## Verhalten
- Kein Filler, keine Vorreden, keine Disclaimer.
- Code: direkt, ohne Tutorial-Erklärung.
- Fehler: erst selbst fixen; Eskalation = Fehler + Hypothese.
- Nur bei echter Mehrdeutigkeit fragen. Annahmen explizit machen, dann fortfahren.
- Roadmap-Vorgriffe verboten — immer nur aktuelle Stufe.

## Tech-Stack
Flutter 3.x · Riverpod 3.x (Hand-Provider, kein Codegen) · Drift 2.x · drift_flutter

**Bekannte Einschränkung:** `riverpod_generator` ist bewusst nicht installiert (offener Bug).
→ Keine `@Riverpod`-Annotation. Provider immer manuell:
```dart
final fooProvider = NotifierProvider<FooNotifier, FooState>(FooNotifier.new);
final barProvider = NotifierProvider.autoDispose<BarNotifier, BarState>(BarNotifier.new);
```

## Projektstruktur (Ist-Zustand)
```
lib/
  core/
    constants.dart          # AppConstants.activeLang etc.
    database/
      database.dart         # AppDatabase (alle Tabellen registriert)
      database.g.dart       # generiert — nicht anfassen
      providers.dart        # appDatabaseProvider
      tables/               # eine Datei pro Domäne
        chapters.dart       # Chapters, ChapterTranslations
        content.dart        # Meta, Items, VocabItems, ItemTranslations
        exercises.dart      # Exercises, ExerciseTranslations
        lessons.dart        # Lessons, LessonTranslations, LessonSteps
        progress.dart       # ReviewState, LessonProgress, DailyActivity
    seeding/
      seeder.dart           # DB-Seeder (nur dev-Start, kein Prod-Pfad)
      dummy_content.dart    # Seed-Daten (Ausnahme vom Anti-Pattern: Seeder-only)
    sm2/
      sm2.dart              # SM-2-Algorithmus
    widgets/
      choice_grid.dart
      flash_card.dart
  features/
    home/                   # home_screen.dart, home_providers.dart
    lesson/                 # lesson_player_screen.dart, lesson_providers.dart,
                            # lesson_session_notifier.dart
    review/                 # review_screen.dart, review_providers.dart,
                            # review_session_notifier.dart
```
Feature-Dateien sind **flach** (kein data/application/presentation-Split).

## Konventionen
- Content-IDs: stabile Slugs (`lesson.basics-01`, `vocab.casa`). User-Zeilen autoincrement.
- Übersetzbares in `*_translations`-Tabellen. Italienisch direkt auf Content-Tabellen.
- `AppConstants.activeLang` verwenden — Sprache nie hardcoden.
- Drift-Tabellen in `lib/core/database/tables/`, nach Domäne gruppiert.
- Code selbsterklärend; Kommentare nur wo nicht offensichtlich.

## Build
Schema- oder Provider-Änderungen → build_runner:
```
dart run build_runner build --delete-conflicting-outputs
```
App-Run: `flutter run` (S25+ per USB)

## Git
Commits lowercase, kein Conventional-Commits-Präfix (`add lesson_steps table`, nicht `feat: ...`).
Commit-Message vor `git commit` als Vorschlag zeigen.

## Anti-Patterns
- Repository-/Mapper-Schichten ohne konkreten Anlass
- Premature Abstraction
- `@Riverpod`-Annotation (riverpod_generator nicht installiert)
- Roadmap-Vorgriffe

---

## Projektstatus & Stufen

### ✅ Stufe 0 — Foundation
Flutter-Projekt, pubspec, Ordnerstruktur, Drift-DB mit vollem Schema, build_runner-Setup.

### ✅ Stufe 1 — Lesson-Player + Review
- DB-Schema komplett (Chapters → Lessons → LessonSteps → Items/Exercises, Progress, SM-2)
- Seeder mit Dummy-Vokabeln
- Home-Screen (Kapitel/Lektionen-Liste, Review-Badge, DailyActivity-Streak-Placeholder)
- Lesson-Player: Intro-Phase (FlashCard) → Exercise-Phase (MC, 4 Optionen) → Done
- Review-Session: fällige Items per SM-2, MC bidirektional (IT→DE / DE→IT)
- SM-2-Algorithmus in `core/sm2/sm2.dart`
- `LessonProgress` + `DailyActivity` werden nach jeder Session geschrieben

### 🔜 Stufe 2 — Content-Pipeline & Übungstypen
Ziel: echte Inhalte aus JSON laden, weitere Übungstypen aktivieren.
- JSON-Content-Loader: `assets/content/manifest.json` → Seeder ersetzt Dummy-Daten
- Übungstypen: `pair` (Zuordnung), `typing` (Freitext), `listening` (Audio-MC)
- `Items.audioRef` verdrahten (lokale Asset-Dateien oder TTS)
- `LessonSteps.suggestedExerciseType` auswerten im Player

### 🔜 Stufe 3 — Statistiken & Daily Goal
- DailyActivity-UI: Streak-Anzeige, Tages-Ziel (`AppConstants.dailyGoalItems`)
- Fortschrittsbalken pro Kapitel auf Home-Screen
- Einfache Stats-Seite (Items gelernt, Wiederholungen, Erfolgsquote)

### 🔜 Stufe 4 — Mehrsprachigkeit & Release
- UI-Sprache via `AppConstants.activeLang` vollständig entkoppelt
- Weitere Zielsprachen (Schema bereits vorbereitet: `*_translations`-Tabellen)
- Play Store Release, App-Icon, Splash
