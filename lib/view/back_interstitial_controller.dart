import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:xox_madvise/view/ad_helper.dart';

class BackInterstitialController {
  InterstitialAd? _interstitialAd;
  bool _isShowing = false;

  void load() {
    if (_isShowing) return;
    final adUnitId = _resolveAdUnitId();
    if (adUnitId == null) return;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd?.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> showThen(Future<void> Function() next) async {
    if (_isShowing) return;
    final ad = _interstitialAd;
    if (ad == null) {
      await next();
      return;
    }

    _isShowing = true;
    _interstitialAd = null;
    var continued = false;
    var hasPresented = false;

    Future<void> continueOnce() async {
      if (continued) return;
      continued = true;
      _isShowing = false;
      await next();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        hasPresented = true;
      },
      onAdDismissedFullScreenContent: (ad) async {
        ad.dispose();
        load();
        await continueOnce();
      },
      onAdFailedToShowFullScreenContent: (ad, error) async {
        ad.dispose();
        load();
        await continueOnce();
      },
    );

    try {
      ad.setImmersiveMode(true);
      ad.show();
      Future.delayed(const Duration(milliseconds: 2200), () async {
        if (!hasPresented) {
          await continueOnce();
        }
      });
    } catch (_) {
      ad.dispose();
      load();
      await continueOnce();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isShowing = false;
  }

  String? _resolveAdUnitId() {
    try {
      return AdHelper.interstitialAdUnitId;
    } on UnsupportedError {
      return null;
    }
  }
}
