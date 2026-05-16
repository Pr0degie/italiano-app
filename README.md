# 🇮🇹 italiano-app

> Italienisch lernen mit täglichem Drill und intelligentem Langzeitgedächtnis.

Flutter-App für Android. Vokabeln werden täglich trainiert bis sie sitzen — danach hält ein SM-2-Algorithmus sie langfristig frisch.

---

## Stack

Flutter 3.x · Riverpod 3.x · Drift 2.x · drift_flutter

---

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

> Läuft auf Android (S25+ per USB). Nach Schema- oder Provider-Änderungen build_runner neu ausführen.

---

## Struktur

```
lib/
  core/        # DB, Provider, SM-2, Widgets
  features/    # home, lesson, review
```

---

## Wiederholungsmodell

Jedes Wort durchläuft zwei Phasen:

### Phase 1 — Daily Drill

```
Tag 1: richtig → Streak 1 ✓
Tag 2: richtig → Streak 2 ✓
Tag 3: richtig → Streak 3 ✓ → MASTERED 🎉
```

- Jedes Wort ist **täglich fällig** bis es gemeistert ist
- **Richtig** → Streak +1, morgen wieder
- **Falsch** → Streak reset auf 0, kommt **noch heute nochmal dran** (max. 3×)

### Phase 2 — SM-2 Langzeit

Nach 3 Tagen in Folge übernimmt SM-2 die Planung:

```
Mastery  →  +7 Tage  →  +17 Tage  →  +42 Tage  →  …
```

- Intervall wächst exponentiell je nachdem wie sicher die Antwort war
- **Falsch** → zurück in Phase 1 (Streak = 0, Mastery aufgehoben)

---

Siehe `CLAUDE.md` für vollständige Projektdokumentation.
