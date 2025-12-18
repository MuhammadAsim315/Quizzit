# Fixing OneDrive Sync Issues with Flutter Build

## Problem
OneDrive sync locks files in the `build` directory, preventing Flutter/Gradle from deleting them during builds.

## Quick Fix

Run the cleanup script:
```powershell
.\clean_build.ps1
```

Or manually run:
```powershell
flutter clean
```

If that fails, use the robocopy method:
```powershell
$emptyDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
robocopy $emptyDir build /MIR /R:0 /W:0 | Out-Null
Remove-Item $emptyDir -Force
Remove-Item build -Recurse -Force
```

## Permanent Solution: Exclude Build Directory from OneDrive Sync

### Option 1: Exclude via OneDrive Settings (Recommended)

1. **Right-click the OneDrive icon** in your system tray (bottom-right)
2. Click **Settings** → **Sync and backup** → **Advanced settings**
3. Click **"Choose folders"** or **"Manage backup"**
4. Navigate to: `App Dev\quizsystem`
5. **Uncheck** these folders:
   - `build`
   - `.dart_tool`
   - `android\build`
   - `android\.gradle`
   - `android\app\build`
6. Click **OK**

### Option 2: Move Project Outside OneDrive

Move your Flutter project to a location outside OneDrive:
- `C:\Dev\quizsystem`
- `D:\Dev\quizsystem` (if D: is not synced)

### Option 3: Pause OneDrive Sync Temporarily

When building/running Flutter:
1. Right-click OneDrive icon → **Pause syncing** → **2 hours** (or longer)
2. Run your Flutter commands (`flutter run`, `flutter build`, etc.)
3. Resume syncing when done

## Why This Happens

OneDrive syncs files in real-time, which can lock files that Flutter/Gradle needs to delete during the build process. Build artifacts don't need to be synced since they're generated files that can be recreated.

## Additional Tips

- **Never commit build directories** - They're already in `.gitignore`
- **Use a local development folder** - Consider `C:\Dev` or `D:\Dev` for projects
- **Keep OneDrive for documents** - Use it for documents, not development projects

## Build Directory Contents (Safe to Exclude)

These directories are generated and don't need syncing:
- `build/` - Flutter build output
- `.dart_tool/` - Dart tooling cache
- `android/build/` - Android build artifacts
- `android/.gradle/` - Gradle cache
- `ios/Pods/` - iOS dependencies (if using CocoaPods)
- `.flutter-plugins-dependencies` - Flutter plugin cache

