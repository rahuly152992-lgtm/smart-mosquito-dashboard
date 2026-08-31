@echo off
REM Mosquito Guard Mobile App - Build Commands for Windows
setlocal enabledelayedexpansion

echo.
echo ================================================
echo  Mosquito Guard Mobile App - Build Commands
echo ================================================
echo.

:menu
echo.
echo Select option:
echo 1. Run app on device/emulator
echo 2. Build APK (Debug)
echo 3. Build APK (Release)
echo 4. Build App Bundle (Play Store)
echo 5. Clean project
echo 6. Get dependencies
echo 7. Run tests
echo 8. View logs
echo 9. Flutter Doctor
echo 0. Exit
echo.

set /p choice="Enter your choice: "

if "%choice%"=="1" goto run_app
if "%choice%"=="2" goto build_debug_apk
if "%choice%"=="3" goto build_release_apk
if "%choice%"=="4" goto build_app_bundle
if "%choice%"=="5" goto clean
if "%choice%"=="6" goto get_deps
if "%choice%"=="7" goto run_tests
if "%choice%"=="8" goto view_logs
if "%choice%"=="9" goto flutter_doctor
if "%choice%"=="0" goto end

echo Invalid choice. Please try again.
goto menu

:run_app
echo.
echo Running app...
flutter run
pause
goto menu

:build_debug_apk
echo.
echo Building debug APK...
flutter build apk --debug
echo.
echo Saved to: build\app\outputs\flutter-app.apk
pause
goto menu

:build_release_apk
echo.
echo Building release APK...
flutter clean
flutter pub get
flutter build apk --release
echo.
echo Saved to: build\app\outputs\flutter-app.apk
pause
goto menu

:build_app_bundle
echo.
echo Building App Bundle for Play Store...
flutter clean
flutter pub get
flutter build appbundle --release
echo.
echo Saved to: build\app\outputs\bundle\release\app-release.aab
echo.
echo Upload this file to Google Play Console
pause
goto menu

:clean
echo.
echo Cleaning project...
flutter clean
echo Done!
pause
goto menu

:get_deps
echo.
echo Getting dependencies...
flutter pub get
echo Done!
pause
goto menu

:run_tests
echo.
echo Running tests...
flutter test
pause
goto menu

:view_logs
echo.
echo Showing device logs...
flutter logs
pause
goto menu

:flutter_doctor
echo.
echo Running flutter doctor...
flutter doctor -v
pause
goto menu

:end
echo.
echo Goodbye!
exit /b 0
