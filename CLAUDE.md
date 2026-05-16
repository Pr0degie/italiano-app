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
      seeder.dart              # DB-Seeder (nur dev-Start, kein Prod-Pfad)
      dummy_content.dart       # Seed-Daten (Ausnahme vom Anti-Pattern: Seeder-only)
      sentence_exercises.dart  # Satz-Bau-Übungen je Lektion (in-memory, kein DB)
    audio/
      audio_service.dart    # AudioService (abstract) + _NoOpAudioService + audioServiceProvider
    sm2/
      sm2.dart              # SM-2-Algorithmus
    widgets/
      multiple_choice_widget.dart
      flash_card.dart
      sentence_builder_widget.dart  # Wort-Reihenfolge-Übung mit Drag & Drop
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

## Audio / Long-Press-Vorlesen
Jedes Widget das italienischen Text anzeigt, soll Long-Press zum Vorlesen unterstützen.
Implementierung via `audioServiceProvider` (`core/audio/audio_service.dart`):

```dart
GestureDetector(
  onLongPress: () => ref.read(audioServiceProvider).speak(italianoText),
  child: Text(italianoText),
)
```

Bis Stufe 4 ist der Provider ein No-Op (tut nichts). In Stufe 4 wird nur die
Provider-Implementierung getauscht — alle Widgets bleiben unverändert.
→ Bei neuen Widgets die IT-Text rendern: `onLongPress` von Anfang an verdrahten.

## Build
Schema- oder Provider-Änderungen → build_runner:
```
dart run build_runner build --delete-conflicting-outputs
```
App-Run: `flutter run` (S25+ per USB)

## Git
Commits lowercase, kein Conventional-Commits-Präfix (`add lesson_steps table`, nicht `feat: ...`).
Commit-Messages immer auf Englisch.
Commit-Message vor `git commit` als Vorschlag zeigen.

## Anti-Patterns
- Repository-/Mapper-Schichten ohne konkreten Anlass
- Premature Abstraction
- `@Riverpod`-Annotation (riverpod_generator nicht installiert)
- Roadmap-Vorgriffe

---

## Projektstatus & Stufen

### ✅ Stufe 0 — Fundament
Flutter-Projekt, pubspec, Ordnerstruktur, Drift-DB mit vollem Schema, build_runner-Setup.

### ✅ Stufe 1 — Vokabel-Lektionen + Lektionsstruktur + Streak/Tagesziel
- DB-Schema komplett (Chapters → Lessons → LessonSteps → Items/Exercises, Progress, SM-2)
- Seeder mit Dummy-Vokabeln
- Home-Screen: Kapitel/Lektionen-Liste, Streak-Anzeige, Tagesziel-Balken, Fortschrittsbalken pro Kapitel
- Lesson-Player: Intro-Phase (FlashCard) → Exercise-Phase → Done
- Exercise-Phase: gemischte Übungstypen via `sealed class AnyExerciseStep`
  - `MCExerciseStep`: Multiple-Choice (4 Optionen, FlashCard-Flip-Feedback)
  - `SentenceBuilderStep`: Wörter per Tap oder Drag & Drop in richtige Reihenfolge bringen
    - Slots sized nach Zielwort (transparenter Platzhaltertext)
    - Drag: Pool→Slot, Slot→Slot (swap), Slot→Pool; Hover-Highlight
    - Layout: Satz oben, Slots+Pool unten (einhändige Bedienung); `SafeArea` gegen Navigationsleiste
    - Satz-Daten in `sentence_exercises.dart` (in-memory, 3 Sätze je Lektion für chapter.01)
- Review-Session: fällige Items, MC bidirektional (IT→DE / DE→IT), `MultipleChoiceWidget`
- SM-2-Algorithmus in `core/sm2/sm2.dart`
- `LessonProgress` + `DailyActivity` werden nach jeder Session geschrieben

#### Wiederholungsmodell (zweiphasig)

**Phase 1 – Daily Drill** (`masteredAt == null`):
- Täglich fällig wenn `lastReviewedDate != today`
- Richtig → `consecutiveCorrectDays + 1`, morgen wieder; bei == 3 → Mastery
- Falsch → Streak = 0, `lastReviewedDate` bleibt leer (heute nochmal fällig), retry queue (max 3×/Session)

**Phase 2 – SM-2 Langzeit** (`masteredAt != null`):
- Fälligkeit über `dueDate`, Startintervall 7 Tage nach Mastery
- Falsch → zurück in Phase 1 (`masteredAt = null`, `consecutiveCorrectDays = 0`)

Felder in `ReviewState`: `consecutiveCorrectDays`, `lastReviewedDate`, `masteredAt`, `dueDate` (nullable).

### 🔜 Stufe 2 — Weitere Übungstypen + Content-Pipeline + Sprachagnostik

#### Content-Pipeline
- JSON-Content-Loader: `assets/content/<lang>/manifest.json` → Seeder ersetzt Dummy-Daten
- `LessonSteps.suggestedExerciseType` im Player auswerten
- Satz-Übungen aus JSON statt Hardcode (`sentence_exercises.dart` entfällt)
- Stats-Seite: Items gelernt, Wiederholungen, Erfolgsquote

#### Neue Übungstypen
- `pair`: Zuordnung Wort↔Übersetzung per Drag oder Tap
- `typing`: Freitext-Eingabe mit Toleranz für Tippfehler

#### Sprachagnostik (Ziel: neue Sprache = neue JSON-Datei)
Das Schema ist bereits korrekt (`*_translations`-Tabellen mit `lang`-Spalte). Folgendes muss bereinigt werden:

- Hardcodiertes `'de'` in Queries → `AppConstants.activeLang` (3 Stellen: `lesson_providers.dart`, `review_session_notifier.dart`)
- `VocabStepData.italiano` + `.translationDe` → `.target` + `.native` (zieht sich durch lesson/review)
- `SentenceBuilderStep.italianWords` + `.german` → `.targetWords` + `.nativePrompt`
- `AppConstants` um `targetLang` (Zielsprache, z.B. `'it'`) erweitern, nicht nur `activeLang` (Muttersprache)
- JSON-Struktur: `assets/content/<targetLang>/` — eine Sprache, ein Ordner

### 🔜 Stufe 3 — Grammatik-Lektionen + Grammatik-Übungen
- Neuer Lektionstyp `grammar` neben `vocab`
- DB-Erweiterung: Grammatikregeln, Beispielsätze, Ausnahmen
- Grammatik-spezifische Übungstypen (z. B. Lückentext, Konjugationstabelle)

### 🔜 Stufe 4 — Hörverstehen (Audio)
- `audioServiceProvider` durch echte Implementierung ersetzen (flutter_tts oder Asset-Audio)
- Long-Press auf beliebige IT-Wörter/-Sätze → Vorlesen (Infrastruktur bereits verdrahtet)
- Entscheidung: mitgeliefertes Audio (Assets) vs. TTS (z. B. flutter_tts)
- Übungstyp `listening`: Audio hören → Antwort tippen oder per MC

### 🔜 Stufe 5 — Gamification + Politur + Release
- XP-System: Punkte pro Übung, Levelsystem
- Mastery-Stufen pro Vokabel (sichtbar auf Home-Screen)
- UI-Sprache vollständig über `AppConstants.activeLang` entkoppelt
- Weitere Zielsprachen (Schema bereits vorbereitet: `*_translations`-Tabellen)
- Play Store Release, App-Icon, Splash
