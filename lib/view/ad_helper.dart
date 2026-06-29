import 'package:flutter/foundation.dart';
import 'dart:io';

class AdHelper {
  static bool get shouldShowBannerAds => true;

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        return 'ca-app-pub-3940256099942544/6300978111';
      }
      return 'ca-app-pub-1815279805478806/3341032215';
    }
    throw UnsupportedError("Unsupported platform");
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        return 'ca-app-pub-3940256099942544/1033173712';
      }
      return 'ca-app-pub-1815279805478806/1864352912';
    }
    throw UnsupportedError("Unsupported platform");
  }

  static String? get rewardedAdUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        return 'ca-app-pub-3940256099942544/5224354917';
      }
      // Add your live rewarded ad unit here when it is ready.
      return null;
    }
    throw UnsupportedError("Unsupported platform");
  }
}
