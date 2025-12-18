# Firebase Setup Guide for Quiz System

This guide will help you set up Firebase for your Flutter quiz system application.

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. Firebase CLI installed (optional, but recommended)

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Enter your project name (e.g., "Quiz System")
4. Follow the setup wizard:
   - Enable/disable Google Analytics (optional)
   - Accept terms and create project

## Step 2: Enable Firebase Authentication

1. In Firebase Console, go to **Authentication** → **Get started**
2. Click on **Sign-in method** tab
3. Enable **Email/Password** authentication:
   - Click on "Email/Password"
   - Toggle "Enable" to ON
   - Click "Save"

## Step 3: Enable Cloud Firestore

1. In Firebase Console, go to **Firestore Database** → **Create database**
2. Choose **Start in test mode** (for development)
3. Select a location for your database
4. Click "Enable"

## Step 4: Add Android App to Firebase

1. In Firebase Console, click the Android icon (or go to Project Settings → Add app)
2. Enter your Android package name: `com.ProgramEz.Quizzit`
   - You can find this in `android/app/build.gradle.kts` under `applicationId`
3. Enter app nickname (optional): "Quiz System Android"
4. Click "Register app"
5. Download `google-services.json`
6. Place the file in: `android/app/google-services.json`
   - ✅ **Already done** - Your project already has this file

## Step 5: Add iOS App to Firebase (if needed)

1. In Firebase Console, click the iOS icon (or go to Project Settings → Add app)
2. Enter your iOS bundle ID: `com.ProgramEz.Quizzit`
   - You can find this in `ios/Runner.xcodeproj/project.pbxproj` or Xcode
3. Enter app nickname (optional): "Quiz System iOS"
4. Click "Register app"
5. Download `GoogleService-Info.plist`
6. Place the file in: `ios/Runner/GoogleService-Info.plist`
7. Open `ios/Runner.xcworkspace` in Xcode
8. Right-click on `Runner` folder → "Add Files to Runner"
9. Select `GoogleService-Info.plist` and ensure "Copy items if needed" is checked

## Step 6: Install Dependencies

Run the following command in your project root:

```bash
flutter pub get
```

## Step 7: (Optional) Use FlutterFire CLI for Better Configuration

The FlutterFire CLI automatically generates `firebase_options.dart` which provides better configuration management.

### Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

### Configure Firebase:

```bash
flutterfire configure
```

This will:
- Detect your Firebase projects
- Let you select platforms (Android, iOS, Web, etc.)
- Generate `lib/firebase_options.dart` automatically

After running this, update `lib/main.dart` to use:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const QuizGeneratorApp());
}
```

## Step 8: Verify Setup

1. Run your app:
   ```bash
   flutter run
   ```

2. Test authentication:
   - Try signing up with a new email
   - Try signing in with the created account
   - Check Firebase Console → Authentication → Users to see registered users

## Troubleshooting

### Android Build Errors

If you get build errors related to Google Services:
1. Ensure `google-services.json` is in `android/app/`
2. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean && cd ..
   flutter run
   ```

### iOS Build Errors

If you get errors on iOS:
1. Ensure `GoogleService-Info.plist` is added to Xcode project
2. Run `pod install` in `ios/` directory:
   ```bash
   cd ios
   pod install
   cd ..
   ```

### Firebase Initialization Errors

If you see "FirebaseApp not initialized" errors:
- Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location
- Verify the package name/bundle ID matches Firebase Console
- Check that Firebase.initializeApp() is called before using any Firebase services

## Current Configuration Status

✅ **Android**: Configured (google-services.json present)
❓ **iOS**: Needs GoogleService-Info.plist (if building for iOS)
✅ **Dependencies**: firebase_core, firebase_auth, cloud_firestore added
✅ **Build Files**: Android Gradle files configured

## Next Steps

1. Complete the Firebase Console setup (Steps 1-3)
2. Verify `google-services.json` matches your Firebase project
3. (Optional) Run `flutterfire configure` for automatic setup
4. Test the login/signup functionality

## Additional Resources

- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Firebase Authentication Guide](https://firebase.google.com/docs/auth)
- [Cloud Firestore Guide](https://firebase.google.com/docs/firestore)

