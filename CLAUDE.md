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
    constants.dart          # AppConstants.activeLang (Muttersprache) + targetLang (Zielsprache)
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
    content/
      models.dart           # ContentManifest, ContentChapter, ContentLesson, sealed ContentStep
      content_loader.dart   # ContentLoader: liest JSON-Assets via rootBundle
    seeding/
      seeder.dart           # ContentSeeder: LoadedContent → DB; nutzt contentVersion zum Re-Seed-Trigger
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
assets/
  content/
    it/
      manifest.json         # schemaVersion + contentVersion + chapters[].lessonFiles[]
      lessons/
        lesson.*.json       # eine Datei pro Lektion: steps[] mit kind-Discriminator
```
Feature-Dateien sind **flach** (kein data/application/presentation-Split).

## Konventionen
- Content-IDs: stabile Slugs (`lesson.basics-01`, `vocab.casa`, `ex.01-01.s01`). User-Zeilen autoincrement.
- Übersetzbares in `*_translations`-Tabellen; Zielsprache direkt auf Content-Tabellen (`vocab_items.front`).
- `AppConstants.activeLang` / `.targetLang` verwenden — Sprache nie hardcoden.
- Naming: `target` (Zielsprache) ↔ `native` (Muttersprache des Nutzers). Nie `italiano`/`german`.
- Drift-Tabellen in `lib/core/database/tables/`, nach Domäne gruppiert.
- Neue Übungstypen: Discriminator-Wert in JSON (`kind`) + neuer Subtyp von `ContentStep` + neuer Subtyp von `AnyExerciseStep` + Widget in `lib/core/widgets/`.
- Bei Content-Änderung in `assets/content/it/`: `manifest.json` → `contentVersion` hochzählen, sonst läuft Re-Seed nicht.
- Code selbsterklärend; Kommentare nur wo nicht offensichtlich.

## Audio / Long-Press-Vorlesen
Jedes Widget das Text in der Zielsprache anzeigt, soll Long-Press zum Vorlesen unterstützen.
Implementierung via `audioServiceProvider` (`core/audio/audio_service.dart`):

```dart
GestureDetector(
  onLongPress: () => ref.read(audioServiceProvider).speak(targetText),
  child: Text(targetText),
)
```

Bis Stufe 4 ist der Provider ein No-Op (tut nichts). In Stufe 4 wird nur die
Provider-Implementierung getauscht — alle Widgets bleiben unverändert.
→ Bei neuen Widgets die Zielsprache-Text rendern: `onLongPress` von Anfang an verdrahten.

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

### ✅ Stufe 2 — Weitere Übungstypen + Content-Pipeline + Sprachagnostik

Komplett bis auf den finalen Content-Konvert (siehe unten).

- **Sprachagnostik**: `AppConstants.targetLang`/`.activeLang`, durchgängig `target`/`native`-Naming.
- **JSON-Content-Pipeline**: `assets/content/it/{manifest.json, lessons/*.json}`; `models.dart` (sealed `ContentStep`) + `content_loader.dart` + `seeder.dart` mit `contentVersion`-Trigger.
- **`suggestedExerciseType`**: wird im Player über Switch ausgewertet (`_buildExercisePhase`).
- **Übungstyp `pair`**: `PairWidget` (4er-Match-Spiel, Tap, Audio-Long-Press). Vokabeln mit `suggested: pair` werden zu 4er-Gruppen gebatcht; Rest <4 → MC-Fallback.
- **Übungstyp `typing`**: `TypingWidget` + `lib/core/text/fuzzy_match.dart` (Diakritika-Normalisierung + Levenshtein, Toleranz ≤1/≤2). Drei Ergebnis-Stufen: exact, almost (gelb), wrong.
- **Stats-Screen**: `lib/features/stats/` mit Vokabel-/Lektion-KPIs + 30-Tage-Aktivitäts-Chart. Home-AppBar hat Bar-Chart-Icon.
- **Content-Authoring**: `tools/`-Ordner
  - `content_data.py` — 10 Lektionen vorbefüllt (100 Vokabeln, 30 Sätze, gemischt mc/pair/typing)
  - `build_template.py` → erzeugt `tools/content_template.xlsx`
  - `xlsx_to_json.py` → liest das xlsx und schreibt `assets/content/it/` neu (bumpt `contentVersion` automatisch)

#### Offener Rest in Stufe 2
- Freundin reviewt `tools/content_template.xlsx`. Danach `python3 tools/xlsx_to_json.py` ausführen → ersetzt die bestehenden Lessons. `flutter run` triggert den Re-Seed automatisch über `contentVersion`.

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
