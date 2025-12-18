import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../services/ad_service.dart';

/// Widget that displays a banner ad at the bottom of the screen
class BannerAdWidget extends StatefulWidget {
  final AdSize? adSize;
  final String? adUnitId;

  const BannerAdWidget({
    super.key,
    this.adSize,
    this.adUnitId,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (_isAdLoading) return;

    setState(() {
      _isAdLoading = true;
    });

    final adUnitId = widget.adUnitId ?? AdService.instance.getBannerAdUnitId();
    final adSize = widget.adSize ?? AdSize.banner;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isAdLoading = false;
            });
          }
          if (kDebugMode) {
            print('✅ Banner ad loaded successfully');
          }
        },
        onAdFailedToLoad: (ad, error) {
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _isAdLoading = false;
            });
          }
          if (kDebugMode) {
            print('❌ Banner ad failed to load: $error');
          }
          ad.dispose();
        },
        onAdOpened: (_) {
          if (kDebugMode) {
            print('Banner ad opened');
          }
        },
        onAdClosed: (_) {
          if (kDebugMode) {
            print('Banner ad closed');
          }
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) {
      // Don't show anything while loading or if ad failed
      return const SizedBox.shrink();
    }

    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

