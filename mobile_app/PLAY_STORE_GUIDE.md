# Mosquito Guard - Google Play Store Deployment Guide

## Prerequisites
- ✅ Flutter SDK installed
- ✅ Android SDK installed (API 34)
- ✅ Google Play Developer Account ($25 one-time fee)
- ✅ Java 11+ installed
- ✅ Keystore for app signing

---

## Step 1: Build APK & App Bundle

### 1.1 Build Release APK
```bash
cd mosquito_mobile_app
flutter clean
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-app.apk`

### 1.2 Build App Bundle (Recommended for Play Store)
```bash
flutter build appbundle --release
```

**Output**: `build/app/outputs/bundle/release/app-release.aab`

---

## Step 2: Prepare for Play Store

### 2.1 Update App Version in `pubspec.yaml`
```yaml
version: 1.0.0+1  # Format: version+build
```

For next releases:
- Update version number: `1.0.1+2`
- Increment build number for each release

### 2.2 Configure App Signing (First Time Only)

Create a keystore:
```bash
keytool -genkey -v -keystore ~/mosquito_guard_key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mosquito_guard
```

Create `android/key.properties`:
```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=mosquito_guard
storeFile=/path/to/mosquito_guard_key.jks
```

---

## Step 3: Create Google Play Developer Account

1. Go to: https://play.google.com/console
2. Click **Create app**
3. Fill in app details:
   - **App name**: Mosquito Guard
   - **Default language**: English
   - **App type**: App
   - **Category**: Tools or Health & Fitness

---

## Step 4: Set Up App on Play Console

### 4.1 App Information
- **Short description**: Real-time mosquito breeding detection
- **Full description**: Smart mosquito risk monitoring connected to ESP32 sensors
- **Category**: Tools or Utilities
- **Content rating**: Complete the questionnaire

### 4.2 Target Audience
- Designed for: 3+ years
- Unrated app

### 4.3 Content Ratings Questionnaire
- Answer questions about app content
- Get content rating certificate

### 4.4 Pricing and Distribution
- **Free**: Yes (recommended)
- **Countries**: Select all or your target countries
- **Content guidelines**: Accept all

---

## Step 5: Upload Release

### 5.1 Create Release

1. Go to **Release** → **Production** (or **Closed Testing** for beta)
2. Click **Create new release**
3. Upload `app-release.aab` file
4. Fill in Release notes:
   ```
   v1.0.0 - Initial Release
   
   Features:
   - Real-time ESP32 sensor monitoring
   - Live temperature & humidity tracking
   - Risk assessment alerts
   - Connection status monitoring
   
   Improvements:
   - Optimized for offline functionality
   - Improved UI/UX
   - Battery optimization
   ```

### 5.2 Set Rollout Percentage
- Start with 5% for testing
- Monitor crashes & feedback
- Gradually increase to 100%

---

## Step 6: App Content Rating

1. Go to **Setup** → **App content**
2. Complete the IARC questionnaire
3. You'll get a content rating from Google Play

---

## Step 7: Provide Policies

1. **Privacy Policy**: Required
   - Create at: https://www.privacypolicygenerator.info/
   - Upload to your server (e.g., GitHub Pages)
   
2. **Terms of Service**: Optional

---

## Step 8: Provide Screenshots & Description

1. **Screenshots** (5-8 recommended):
   - Login/Connection screen
   - Live data dashboard
   - Alert notifications
   - Device status
   - Historical data view

2. **Feature graphic** (1024 x 500 px)

3. **Promotional graphic** (180 x 120 px)

---

## Step 9: Submit for Review

1. Verify all required fields are filled
2. Review all content once more
3. Click **Review release**
4. Check for any errors or warnings
5. Click **Start rollout to Production**

**Review time**: Usually 24-48 hours

---

## Monitoring After Launch

### Check Release Status
- Go to **Release** → **Production**
- View real-time crash data
- Monitor star ratings and reviews
- Check install metrics

### Common Issues

**Issue**: Crashes reported
- **Fix**: Check Logcat: `flutter logs`
- Update to Play Console internal testing first

**Issue**: Low ratings for performance
- **Fix**: Optimize API calls
- Implement caching
- Reduce refresh frequency

**Issue**: Users report "No connection"
- **Fix**: Improve error messaging
- Add connection diagnostics
- Provide troubleshooting guide in app

---

## Updating the App

### Release New Version

1. Update `pubspec.yaml` version
2. Make code changes
3. Test thoroughly with `flutter test`
4. Build: `flutter build appbundle --release`
5. Upload new `.aab` to Play Console
6. Update release notes
7. Submit for review

### Rollout Strategy
- 5% → 10% → 25% → 50% → 100%
- Wait 2-3 days between rollouts
- Monitor crash metrics at each stage

---

## Useful Links

- Google Play Console: https://play.google.com/console
- Flutter Deployment: https://flutter.dev/docs/deployment/android
- App Bundle: https://developer.android.com/guide/app-bundle
- Privacy Policy Generator: https://www.privacypolicygenerator.info/
- Firebase Crashlytics (optional): https://firebase.google.com/docs/crashlytics

---

## Security Checklist

- ✅ API uses HTTPS only
- ✅ No hardcoded passwords/secrets
- ✅ Validate all user inputs
- ✅ Permissions: Only request necessary
- ✅ Data encryption: Implement if storing sensitive data
- ✅ Test on multiple Android versions

---

## Cost

- Google Play Developer Account: **$25** (one-time)
- App listing: **FREE**
- Keystore: **FREE**
- Build & Deploy: **FREE** (via Flutter CLI)

**Total Initial Cost: $25**

---

**Status**: Ready to deploy! 🚀
