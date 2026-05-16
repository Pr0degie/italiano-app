# Stufe 1 Build + Run
# Ausfuehren in: C:\Users\tobo2\repos\italiano-app\
# > cd C:\Users\tobo2\repos\italiano-app; .\run_stufe1.ps1

Set-StrictMode -Off
$ErrorActionPreference = "Stop"
Set-Location "C:\Users\tobo2\repos\italiano-app"

Write-Host "=== build_runner ===" -ForegroundColor Cyan
dart run build_runner build --delete-conflicting-outputs

Write-Host "=== flutter run ===" -ForegroundColor Cyan
flutter run
