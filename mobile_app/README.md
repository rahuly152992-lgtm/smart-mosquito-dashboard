# Mosquito Guard - Mobile App

A native Android/iOS Flutter application for real-time mosquito breeding detection via ESP32 sensors.

## Features

✅ **Real-time Monitoring**
- Live temperature & humidity readings
- Risk level assessment
- Active alert notifications
- Device connection status

✅ **Hardware-Only Mode**
- Shows connection screen when ESP32 is offline
- Only displays data when hardware is connected
- No fake/demo data

✅ **Clean UI**
- Material Design 3
- Dark/Light theme support
- Responsive layouts
- Smooth animations

✅ **Ready for Play Store**
- Production-ready build configuration
- Proper error handling
- Battery optimized
- Network resilient

---

## Quick Start

### Prerequisites
```bash
# Install Flutter
https://flutter.dev/docs/get-started/install

# Verify installation
flutter doctor
```

### 1. Get Dependencies
```bash
cd mosquito_mobile_app
flutter pub get
```

### 2. Run on Emulator/Device
```bash
# List available devices
flutter devices

# Run app
flutter run -v

# Release mode
flutter run --release
```

### 3. Build APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-app.apk
```

### 4. Build for Play Store
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## Project Structure

```
mosquito_mobile_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── services/
│   │   └── api_service.dart     # Backend API calls
│   ├── providers/
│   │   └── sensor_provider.dart # State management
│   └── screens/
│       ├── home_screen.dart     # Live data dashboard
│       └── connection_screen.dart # No hardware screen
├── android/                      # Android config
├── ios/                         # iOS config
├── assets/                      # Images, icons, fonts
├── pubspec.yaml                 # Dependencies
└── PLAY_STORE_GUIDE.md         # Deployment guide
```

---

## Configuration

### Update API URL
Edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://your-api-domain.com';
```

### Update App Name & Package
Edit `pubspec.yaml`:
```yaml
name: mosquito_guard
description: Your description
version: 1.0.0+1
```

### Update Android Package ID
Edit `android/app/build.gradle`:
```gradle
applicationId "com.yourcompany.mosquitoguard"
```

---

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test
```

### Manual Testing Checklist
- [ ] App loads correctly
- [ ] Shows connection screen when offline
- [ ] Shows home screen when connected
- [ ] Displays correct sensor values
- [ ] Refresh works (pull-to-refresh)
- [ ] Auto-refresh every 10 seconds
- [ ] Status indicator updates
- [ ] Handles network errors gracefully

---

## Debugging

### View Logs
```bash
flutter logs
```

### Debug Mode
```bash
flutter run
# With verbose logging
flutter run -v
```

### Android Logcat
```bash
flutter logs --device-only
```

---

## Distribution

### Google Play Store
See `PLAY_STORE_GUIDE.md` for detailed steps.

**Quick Summary**:
1. Create Google Play Developer account ($25)
2. Build app bundle: `flutter build appbundle --release`
3. Upload to Play Console
4. Complete app information
5. Submit for review (24-48 hours)

### Direct APK Distribution
1. Build APK: `flutter build apk --release`
2. Share APK file directly
3. Users can install: `adb install app-release.apk`

---

## Troubleshooting

### "No device connected" Error
```bash
flutter emulators --launch <emulator_name>
# or connect physical device via USB
```

### API Connection Issues
- Check backend is running
- Verify HTTPS certificate
- Check network connectivity
- Review API endpoint URL

### Build Fails
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter build apk --release -v
```

### Permissions Issues
- Check `AndroidManifest.xml` has required permissions
- Verify app requested permissions in settings
- Test on Android 6+ with runtime permissions

---

## Performance Optimization

### Current Optimizations
- ✅ Auto-refresh every 10 seconds (battery friendly)
- ✅ Lazy loading of historical data
- ✅ Efficient state management with Provider
- ✅ Network connection caching
- ✅ Error boundary implementation

### Further Optimizations
- Add local caching with Hive/Sqflite
- Implement background sync
- Use WebSocket for real-time updates
- Add image optimization for alerts
- Implement pagination for history

---

## Security Notes

- ✅ All API calls use HTTPS
- ✅ No hardcoded API keys
- ✅ Network timeout: 10 seconds
- ✅ Proper error handling (no sensitive data in logs)
- ⚠️ TODO: Add certificate pinning for production

---

## Future Enhancements

- [ ] Offline mode with local data caching
- [ ] Push notifications for alerts
- [ ] Data export (CSV/PDF)
- [ ] Map view for multiple sensors
- [ ] IoS app release
- [ ] WebSocket real-time updates
- [ ] Dark theme support
- [ ] Multiple device support

---

## Support

For issues or questions:
1. Check Logcat output: `flutter logs -v`
2. Review Play Store guide: `PLAY_STORE_GUIDE.md`
3. Check backend API status

---

## License

Proprietary - Mosquito Guard Smart Detection System

---

**Status**: Ready for Play Store Release 🚀
