# Google Mobile Ads Integration Guide

## ✅ Implementation Complete

Test ads have been successfully integrated into your Flutter quiz application. Banner ads are now displayed at the bottom of key screens.

---

## 📦 What Was Added

### 1. **Dependencies**
- Added `google_mobile_ads: ^5.1.0` to `pubspec.yaml`

### 2. **Ad Service** (`lib/services/ad_service.dart`)
- Singleton service for managing Google Mobile Ads
- Handles initialization
- Provides test ad unit IDs
- Configures request settings for test ads

### 3. **Banner Ad Widget** (`lib/widgets/banner_ad_widget.dart`)
- Reusable widget for displaying banner ads
- Handles ad loading, errors, and lifecycle
- Automatically hides when ad fails to load

### 4. **Configuration Files**
- **Android**: Added AdMob App ID to `AndroidManifest.xml`
- **iOS**: Added AdMob App ID to `Info.plist`

### 5. **Initialization**
- Ads initialized in `main.dart` after Firebase
- Test ad configuration enabled in debug mode

### 6. **Screens with Ads**
Banner ads added to the bottom of:
- ✅ Dashboard Screen
- ✅ Categories Screen
- ✅ Quiz Screen
- ✅ History Screen
- ✅ Statistics Screen

---

## 🧪 Test Ad Unit IDs

Currently using Google's test ad unit IDs:

- **Banner Ad**: `ca-app-pub-3940256099942544/6300978111`
- **Interstitial Ad**: `ca-app-pub-3940256099942544/1033173712` (available but not used yet)

**Android Test App ID**: `ca-app-pub-3940256099942544~3347511713`  
**iOS Test App ID**: `ca-app-pub-3940256099942544~1458002511`

---

## 🚀 Next Steps for Production

### 1. **Create AdMob Account**
1. Go to [Google AdMob](https://admob.google.com/)
2. Sign in with your Google account
3. Create a new app or link existing app

### 2. **Get Your Ad Unit IDs**
1. In AdMob dashboard, go to **Apps** → Your App
2. Click **Ad units** → **Add ad unit**
3. Select **Banner** ad type
4. Copy the **Ad unit ID** (format: `ca-app-pub-XXXXXXXXXX/XXXXXXXXXX`)

### 3. **Get Your App ID**
1. In AdMob dashboard, go to **Apps**
2. Find your app and copy the **App ID** (format: `ca-app-pub-XXXXXXXXXX~XXXXXXXXXX`)

### 4. **Update Configuration**

#### Update `lib/services/ad_service.dart`:
```dart
// Replace test ad unit IDs with your production IDs
String getBannerAdUnitId() {
  if (kDebugMode) {
    return testBannerAdUnitId; // Keep test ads in debug
  }
  return 'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_BANNER_AD_UNIT_ID'; // Your production ID
}
```

#### Update `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-YOUR_PUBLISHER_ID~YOUR_APP_ID"/>
```

#### Update `ios/Runner/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-YOUR_PUBLISHER_ID~YOUR_APP_ID</string>
```

---

## 📱 Testing

### Test on Real Device
1. Run the app on a physical device (not emulator)
2. You should see test banner ads at the bottom of screens
3. Test ads will show "Test Ad" label

### Verify Ad Loading
- Check console logs for:
  - `✅ Google Mobile Ads initialized successfully`
  - `✅ Banner ad loaded successfully`
- If you see errors, check:
  - Internet connection
  - AdMob App ID is correct
  - Ad unit ID is correct

---

## 🎨 Ad Placement

Banner ads are placed at the bottom of screens:
- Above the bottom navigation bar (Dashboard)
- At the very bottom (other screens)
- Automatically hidden if ad fails to load
- Responsive to screen size

---

## 🔧 Customization

### Change Ad Size
In `banner_ad_widget.dart`, you can change the ad size:
```dart
BannerAdWidget(
  adSize: AdSize.largeBanner, // or AdSize.mediumRectangle, etc.
)
```

### Disable Ads on Specific Screens
Simply remove the `BannerAdWidget()` from that screen's widget tree.

### Add Interstitial Ads
Interstitial ads are ready to use. Example:
```dart
final interstitialAd = InterstitialAd.load(
  adUnitId: AdService.instance.getInterstitialAdUnitId(),
  request: const AdRequest(),
  adLoadCallback: InterstitialAdLoadCallback(
    onAdLoaded: (ad) {
      ad.show();
    },
    onAdFailedToLoad: (error) {
      print('Interstitial ad failed: $error');
    },
  ),
);
```

---

## ⚠️ Important Notes

1. **Test Ads Only**: Currently using test ad unit IDs. Replace with production IDs before publishing.

2. **Debug Mode**: Test ads are automatically used in debug mode. Production ads will be used in release builds (after you update the IDs).

3. **Ad Policies**: Make sure your app complies with [AdMob policies](https://support.google.com/admob/answer/6128543).

4. **Rate Limiting**: AdMob has rate limits. Don't make excessive ad requests.

5. **User Experience**: Ads are placed at the bottom to minimize interference with app functionality.

---

## 🐛 Troubleshooting

### Ads Not Showing
1. **Check Internet Connection**: Ads require internet
2. **Verify App ID**: Make sure AdMob App ID is correct in manifest files
3. **Check Logs**: Look for error messages in console
4. **Test on Real Device**: Emulators may have issues with ads
5. **Wait a Few Minutes**: New AdMob accounts may take time to activate

### Build Errors
1. **Run `flutter pub get`**: After adding the package
2. **Clean Build**: `flutter clean && flutter pub get`
3. **Check Dependencies**: Ensure all dependencies are compatible

### Ad Loading Errors
- **ERROR_CODE_NO_FILL**: No ads available (normal for new accounts)
- **ERROR_CODE_NETWORK_ERROR**: Check internet connection
- **ERROR_CODE_INVALID_REQUEST**: Check ad unit ID format

---

## 📚 Resources

- [Google Mobile Ads Flutter Plugin](https://pub.dev/packages/google_mobile_ads)
- [AdMob Documentation](https://developers.google.com/admob)
- [AdMob Policies](https://support.google.com/admob/answer/6128543)
- [Test Ad Unit IDs](https://developers.google.com/admob/android/test-ads)

---

## ✅ Checklist for Production

- [ ] Create AdMob account
- [ ] Create app in AdMob dashboard
- [ ] Create banner ad unit
- [ ] Get production App ID
- [ ] Get production Ad Unit ID
- [ ] Update `ad_service.dart` with production IDs
- [ ] Update `AndroidManifest.xml` with production App ID
- [ ] Update `Info.plist` with production App ID
- [ ] Test on real device
- [ ] Verify ads are showing correctly
- [ ] Review AdMob policies compliance
- [ ] Submit app for review (if required)

---

*Integration completed successfully! 🎉*

