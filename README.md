# italiano-app

Flutter-basierte Sprachlern-App für Italienisch mit SM-2-basierter Wiederholung.

## Stack

Flutter 3.x · Riverpod 3.x · Drift 2.x · drift_flutter

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

> App läuft auf Android (S25+ per USB). Nach Schema- oder Provider-Änderungen build_runner neu ausführen.

## Struktur

```
lib/
  core/        # DB, Provider, SM-2, Widgets
  features/    # home, lesson, review
```

Siehe `CLAUDE.md` für vollständige Projektdokumentation.
