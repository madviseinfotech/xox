import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // return 'ca-app-pub-3940256099942544/6300978111'; test
      return 'ca-app-pub-1815279805478806/3341032215';
    }
    throw UnsupportedError("Unsupported platform");
  }
}
