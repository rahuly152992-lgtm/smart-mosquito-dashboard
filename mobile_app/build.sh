#!/bin/bash
# Mosquito Guard Mobile App - Build Commands
# Quick reference for common tasks

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        Mosquito Guard Mobile App - Build Commands             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navigate to app directory
cd "$(dirname "$0")" || exit

# Menu
PS3='Select option: '
options=(
  "📱 Run app on device/emulator"
  "🔨 Build APK (Debug)"
  "🚀 Build APK (Release)"
  "📦 Build App Bundle (Play Store)"
  "🧹 Clean project"
  "📥 Get dependencies"
  "🧪 Run tests"
  "📊 View logs"
  "🔍 Doctor (diagnose issues)"
  "❌ Exit"
)

select opt in "${options[@]}"
do
  case $opt in
    "📱 Run app on device/emulator")
      echo -e "${BLUE}Running app...${NC}"
      flutter run
      ;;
    "🔨 Build APK (Debug)")
      echo -e "${BLUE}Building debug APK...${NC}"
      flutter build apk --debug
      echo -e "${GREEN}✅ APK saved to: build/app/outputs/flutter-app.apk${NC}"
      ;;
    "🚀 Build APK (Release)")
      echo -e "${BLUE}Building release APK...${NC}"
      flutter clean
      flutter pub get
      flutter build apk --release
      echo -e "${GREEN}✅ APK saved to: build/app/outputs/flutter-app.apk${NC}"
      ;;
    "📦 Build App Bundle (Play Store)")
      echo -e "${BLUE}Building App Bundle...${NC}"
      flutter clean
      flutter pub get
      flutter build appbundle --release
      echo -e "${GREEN}✅ Bundle saved to: build/app/outputs/bundle/release/app-release.aab${NC}"
      echo -e "${YELLOW}Upload this file to Google Play Console${NC}"
      ;;
    "🧹 Clean project")
      echo -e "${BLUE}Cleaning project...${NC}"
      flutter clean
      echo -e "${GREEN}✅ Project cleaned${NC}"
      ;;
    "📥 Get dependencies")
      echo -e "${BLUE}Getting dependencies...${NC}"
      flutter pub get
      echo -e "${GREEN}✅ Dependencies updated${NC}"
      ;;
    "🧪 Run tests")
      echo -e "${BLUE}Running tests...${NC}"
      flutter test
      ;;
    "📊 View logs")
      echo -e "${BLUE}Showing device logs...${NC}"
      flutter logs
      ;;
    "🔍 Doctor (diagnose issues)")
      echo -e "${BLUE}Running flutter doctor...${NC}"
      flutter doctor -v
      ;;
    "❌ Exit")
      echo -e "${GREEN}Goodbye! 👋${NC}"
      break
      ;;
    *)
      echo -e "${YELLOW}Invalid option${NC}"
      ;;
  esac
  echo ""
done
