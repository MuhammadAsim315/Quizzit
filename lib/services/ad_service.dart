import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

/// Service for managing Google Mobile Ads
class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  
  AdService._();

  bool _isInitialized = false;

  /// Test Ad Unit IDs
  /// Replace these with your actual ad unit IDs from AdMob when ready
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Android/iOS test banner
  static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // Android/iOS test interstitial

  /// Initialize Google Mobile Ads
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Google Mobile Ads initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Google Mobile Ads: $e');
      }
    }
  }

  /// Request configuration for test ads
  RequestConfiguration getRequestConfiguration() {
    return RequestConfiguration(
      testDeviceIds: kDebugMode ? ['TEST_DEVICE_ID'] : [],
    );
  }

  /// Get banner ad unit ID (test or production)
  String getBannerAdUnitId() {
    // In debug mode, always use test ads
    if (kDebugMode) {
      return testBannerAdUnitId;
    }
    // TODO: Replace with your actual production ad unit ID
    return testBannerAdUnitId;
  }

  /// Get interstitial ad unit ID (test or production)
  String getInterstitialAdUnitId() {
    // In debug mode, always use test ads
    if (kDebugMode) {
      return testInterstitialAdUnitId;
    }
    // TODO: Replace with your actual production ad unit ID
    return testInterstitialAdUnitId;
  }
}

