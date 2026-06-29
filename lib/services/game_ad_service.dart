import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:xox_madvise/view/ad_helper.dart';

class GameInterstitialService {
  GameInterstitialService._();

  static final GameInterstitialService instance = GameInterstitialService._();

  // Keep interstitials conservative so short games are not interrupted too often.
  static const Duration _cooldown = Duration(minutes: 3);
  static const Duration _minimumAppAgeBeforeInterstitial = Duration(minutes: 1);
  static const int _minCompletedRoundsBeforeShow = 3;
  static const Duration _retryDelay = Duration(seconds: 8);

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  bool _isShowing = false;
  int _completedRounds = 0;
  DateTime? _lastShownAt;
  final DateTime _serviceStartedAt = DateTime.now();
  Timer? _retryTimer;

  void load() {
    if (_isLoading || _interstitialAd != null || _isShowing) return;
    _retryTimer?.cancel();

    final adUnitId = _resolveAdUnitId();
    if (adUnitId == null) return;

    _isLoading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _interstitialAd = ad;
          _interstitialAd?.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _interstitialAd = null;
          _scheduleRetry();
        },
      ),
    );
  }

  void registerRoundCompletion() {
    _completedRounds += 1;
    load();
  }

  Future<bool> maybeShowOnExit() async {
    if (_isShowing) return false;
    return _showLoadedInterstitial(ignoreRestrictions: true);
  }

  Future<bool> maybeShow() async {
    if (_isShowing) return false;
    if (_completedRounds < _minCompletedRoundsBeforeShow) {
      load();
      return false;
    }

    if (DateTime.now().difference(_serviceStartedAt) <
        _minimumAppAgeBeforeInterstitial) {
      load();
      return false;
    }

    final lastShownAt = _lastShownAt;
    if (lastShownAt != null &&
        DateTime.now().difference(lastShownAt) < _cooldown) {
      load();
      return false;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      load();
      return false;
    }

    return _showLoadedInterstitial(ignoreRestrictions: false);
  }

  Future<bool> _showLoadedInterstitial({
    required bool ignoreRestrictions,
  }) async {
    final ad = _interstitialAd;
    if (ad == null) {
      load();
      return false;
    }

    _interstitialAd = null;
    _isShowing = true;
    final completer = Completer<bool>();

    void complete(bool shown) {
      if (completer.isCompleted) return;
      completer.complete(shown);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        if (!ignoreRestrictions) {
          _lastShownAt = DateTime.now();
          _completedRounds = 0;
        }
        load();
        complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowing = false;
        load();
        complete(false);
      },
    );

    try {
      ad.setImmersiveMode(true);
      ad.show();
    } catch (_) {
      ad.dispose();
      _isShowing = false;
      load();
      complete(false);
    }

    return completer.future;
  }

  String? _resolveAdUnitId() {
    try {
      return AdHelper.interstitialAdUnitId;
    } on UnsupportedError {
      return null;
    }
  }

  void _scheduleRetry() {
    if (_retryTimer?.isActive ?? false) return;
    _retryTimer = Timer(_retryDelay, load);
  }
}

class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isShowing = false;
  Timer? _retryTimer;

  void load() {
    if (_isLoading || _rewardedAd != null || _isShowing) return;
    _retryTimer?.cancel();

    final adUnitId = _resolveAdUnitId();
    if (adUnitId == null) return;

    _isLoading = true;
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _rewardedAd = null;
          _scheduleRetry();
        },
      ),
    );
  }

  Future<bool> show({
    required BuildContext context,
    required FutureOr<void> Function() onRewardEarned,
    String loadingMessage =
        'Reward ad is loading. Please try again in a moment.',
    String unavailableMessage = 'Reward ad is not configured yet.',
  }) async {
    if (_isShowing) return false;

    final adUnitId = _resolveAdUnitId();
    if (adUnitId == null) {
      showGameAdSnackBar(context, unavailableMessage);
      return false;
    }

    final ad = _rewardedAd;
    if (ad == null) {
      load();
      showGameAdSnackBar(context, loadingMessage);
      return false;
    }

    _rewardedAd = null;
    _isShowing = true;
    final completer = Completer<bool>();
    var rewarded = false;

    void complete(bool earned) {
      if (completer.isCompleted) return;
      completer.complete(earned);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        load();
        complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowing = false;
        load();
        complete(false);
      },
    );

    try {
      ad.setImmersiveMode(true);
      ad.show(
        onUserEarnedReward: (adWithoutView, reward) async {
          rewarded = true;
          await onRewardEarned();
        },
      );
    } catch (_) {
      ad.dispose();
      _isShowing = false;
      load();
      complete(false);
    }

    return completer.future;
  }

  String? _resolveAdUnitId() {
    try {
      return AdHelper.rewardedAdUnitId;
    } on UnsupportedError {
      return null;
    }
  }

  void _scheduleRetry() {
    if (_retryTimer?.isActive ?? false) return;
    _retryTimer = Timer(const Duration(seconds: 10), load);
  }
}

void showGameAdSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}
