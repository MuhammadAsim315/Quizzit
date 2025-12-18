# Troubleshooting White Screen Issue

## Quick Fixes to Try

### 1. Check Console for Errors
Run the app and check the console/terminal output for any error messages:
```bash
flutter run
```

Look for:
- Firebase initialization errors
- Build errors
- Exception messages

### 2. Verify Firebase Configuration

**Check google-services.json:**
- Ensure `android/app/google-services.json` exists
- Verify it matches your Firebase project
- Check that the package name in the file matches `com.ProgramEz.Quizzit`

**Check Firebase Console:**
- Ensure Firebase project is created
- Verify Email/Password authentication is enabled
- Check that Firestore is created (if using it)

### 3. Clean and Rebuild

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### 4. Check if Screens Render Without Firebase

The updated code now has error handling. If you see an error screen, that's progress! It means the app is running but Firebase has an issue.

### 5. Common Causes

**Firebase Not Initialized:**
- Error: "FirebaseApp not initialized"
- Solution: Ensure `google-services.json` is in the correct location

**Package Name Mismatch:**
- Error: "Default FirebaseApp is not initialized"
- Solution: Verify package name in `google-services.json` matches `android/app/build.gradle.kts`

**Missing Firebase Setup:**
- Error: "PlatformException" or "MissingPluginException"
- Solution: Run `flutter clean` and rebuild

### 6. Test Without Firebase (Temporary)

If you want to test if the screens work without Firebase, temporarily modify `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Temporarily skip Firebase initialization
  // await Firebase.initializeApp();
  
  runApp(const QuizGeneratorApp());
}
```

And modify `AuthWrapper` to always show login:
```dart
return const LoginScreen(); // Always show login for testing
```

### 7. Check Device/Emulator

- Ensure device/emulator is properly connected
- Check if other Flutter apps run on the same device
- Try running on a different device/emulator

### 8. Check Logs

**Android:**
```bash
adb logcat | grep -i flutter
```

**Or check Android Studio Logcat for errors**

## What the Updated Code Does

The updated `main.dart` now:
1. ✅ Catches Firebase initialization errors
2. ✅ Shows error messages in debug console
3. ✅ Handles authentication stream errors
4. ✅ Falls back to login screen if Firebase fails
5. ✅ Shows error UI instead of white screen

## Next Steps

1. **Run the app** and check the console output
2. **Look for error messages** - they will tell you what's wrong
3. **Share the error message** if you need more help

The app should now show either:
- Login screen (if working)
- Error screen with message (if Firebase has issues)
- Loading indicator (while checking auth state)

No more white screen! 🎉

