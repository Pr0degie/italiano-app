# Italiano-App Stufe 0 Setup
# Ausfuehren in: C:\Users\tobo2\repos\
# > cd C:\Users\tobo2\repos; .\italiano-app\setup_stufe0.ps1

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

Write-Host "=== Stufe 0: Flutter-Projekt anlegen ===" -ForegroundColor Cyan

# 1. flutter create
Write-Host "-> flutter create..." -ForegroundColor Yellow
Set-Location "C:\Users\tobo2\repos"
flutter create --org com.pr0degie --project-name italiano_app italiano-app
Set-Location "C:\Users\tobo2\repos\italiano-app"

# 2. dependencies
Write-Host "-> flutter pub add (prod)..." -ForegroundColor Yellow
flutter pub add flutter_riverpod riverpod_annotation drift drift_flutter

Write-Host "-> flutter pub add (dev)..." -ForegroundColor Yellow
flutter pub add --dev build_runner drift_dev riverpod_generator

# 3. Ordner
Write-Host "-> Ordner anlegen..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "assets\content" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\core\database\tables" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\core\seeding" | Out-Null

# 4. pubspec.yaml: assets-Section einsetzen
Write-Host "-> pubspec.yaml: assets-Eintrag hinzufuegen..." -ForegroundColor Yellow
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -notmatch "assets/content/") {
  $pubspec = $pubspec -replace "(  uses-material-design: true)", "`$1`n  assets:`n    - assets/content/"
  Set-Content "pubspec.yaml" -Value $pubspec -NoNewline
}

Write-Host "-> Alle Dateien wurden von Claude bereits geschrieben." -ForegroundColor Green
Write-Host ""

# 5. build_runner
Write-Host "=== build_runner ===" -ForegroundColor Cyan
dart run build_runner build --delete-conflicting-outputs

# 6. flutter run
Write-Host "=== flutter run ===" -ForegroundColor Cyan
flutter run
