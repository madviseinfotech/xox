import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:xox_madvise/theme/app_theme.dart';
import 'package:xox_madvise/utils/utility.dart';
import 'package:xox_madvise/view/ad_helper.dart';
import 'package:xox_madvise/view/back_interstitial_controller.dart';
import 'package:xox_madvise/view/retention_prompts.dart';

class GameScaffold extends StatefulWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
    this.scrollable = true,
    this.compactHeader = false,
    this.minimalHeader = false,
    this.showBannerAd = true,
    this.headerAction,
    this.backgroundMusicAsset = 'music/begin.mp3',
  });

  final String title;
  final String subtitle;
  final List<Color> accent;
  final Widget child;
  final bool scrollable;
  final bool compactHeader;
  final bool minimalHeader;
  final bool showBannerAd;
  final Widget? headerAction;
  final String? backgroundMusicAsset;

  @override
  State<GameScaffold> createState() => _GameScaffoldState();
}

class _GameScaffoldState extends State<GameScaffold> {
  final BackInterstitialController _backAdController =
      BackInterstitialController();

  BannerAd? _bannerAd;
  bool _isBannerReady = false;
  AudioPlayer? _musicPlayer;
  bool _musicEnabled = Utility.volume;

  @override
  void initState() {
    super.initState();
    _backAdController.load();
    _loadBanner();
    _setupBackgroundMusic();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _musicPlayer?.dispose();
    _backAdController.dispose();
    super.dispose();
  }

  Future<void> _setupBackgroundMusic() async {
    final asset = widget.backgroundMusicAsset;
    if (asset == null) return;
    final player = AudioPlayer();
    _musicPlayer = player;
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(0.35);
    if (_musicEnabled) {
      await player.play(AssetSource(asset));
    }
  }

  Future<void> _toggleMusic() async {
    final player = _musicPlayer;
    if (player == null) return;
    setState(() {
      _musicEnabled = !_musicEnabled;
      Utility.volume = _musicEnabled;
    });
    if (_musicEnabled) {
      await player.play(AssetSource(widget.backgroundMusicAsset!));
    } else {
      await player.stop();
    }
  }

  Future<void> _loadBanner() async {
    if (!widget.showBannerAd || !AdHelper.shouldShowBannerAds) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final adUnitId = _resolveBannerAdUnitId();
      if (adUnitId == null) return;
      final width = MediaQuery.of(context).size.width.truncate();
      final adaptiveSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

      final ad = BannerAd(
        adUnitId: adUnitId,
        size: adaptiveSize ?? AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _bannerAd = ad as BannerAd;
            setState(() => _isBannerReady = true);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _bannerAd = null;
              _isBannerReady = false;
            });
          },
        ),
      );

      _bannerAd = ad;
      ad.load();
    });
  }

  Future<void> _handleBack() async {
    await _backAdController.showThen(() async {
      if (!mounted) return;
      await showLeaveGamePrompt(context);
    });
  }

  String? _resolveBannerAdUnitId() {
    try {
      return AdHelper.bannerAdUnitId;
    } on UnsupportedError {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;
    final bottomInset = mediaQuery.padding.bottom;
    final viewBottomInset = mediaQuery.viewPadding.bottom;
    final gestureBottomInset = mediaQuery.systemGestureInsets.bottom;
    final safeBottomInset = math.max(
      bottomInset,
      math.max(viewBottomInset, gestureBottomInset),
    );
    final bannerHeight = _bannerAd?.size.height.toDouble() ?? 50.0;
    final showBanner =
        widget.showBannerAd && _isBannerReady && _bannerAd != null;
    final bottomPadding =
        24.0 + safeBottomInset + (showBanner ? bannerHeight + 12 : 0.0);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.accent.first.withValues(alpha: 0.18),
                      const Color(0xff0f172a),
                      const Color(0xff020617),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -18,
              child: _ambientOrb(
                widget.accent.last.withValues(alpha: 0.16),
                152,
              ),
            ),
            Positioned(
              top: 180,
              left: -30,
              child: _ambientOrb(
                widget.accent.first.withValues(alpha: 0.12),
                116,
              ),
            ),
            SafeArea(
              bottom: false,
              child: widget.scrollable
                  ? SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        topInset > 0 ? 12 : 20,
                        20,
                        bottomPadding,
                      ),
                      child: _buildScaffoldBody(textTheme, false),
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        topInset > 0 ? 12 : 20,
                        20,
                        bottomPadding,
                      ),
                      child: _buildScaffoldBody(textTheme, true),
                    ),
            ),
            if (showBanner)
              Positioned(
                left: 0,
                right: 0,
                bottom: safeBottomInset,
                child: Container(
                  color: AppColors.panel,
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Center(
                    child: SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _ambientOrb(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 50, spreadRadius: 10)],
      ),
    );
  }

  Widget _buildScaffoldBody(TextTheme textTheme, bool fillContent) {
    final isCompact = widget.compactHeader || widget.minimalHeader;
    final headerPadding = widget.compactHeader ? 18.0 : 22.0;
    final headerRadius = widget.compactHeader ? 22.0 : 28.0;
    final titleStyle = widget.compactHeader
        ? textTheme.headlineMedium
        : textTheme.displaySmall;
    final subtitleStyle =
        (widget.compactHeader ? textTheme.bodySmall : textTheme.bodyMedium)
            ?.copyWith(color: const Color(0xffe2e8f0));
    final trailingActions = <Widget>[
      if (widget.backgroundMusicAsset != null)
        GestureDetector(
          onTap: _toggleMusic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(
              _musicEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: widget.accent.last,
              size: 18,
            ),
          ),
        ),
      if (widget.headerAction != null) widget.headerAction!,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GameEntrance(
          delay: const Duration(milliseconds: 30),
          child: GestureDetector(
            onTap: _handleBack,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: widget.minimalHeader ? 10 : 18),
        _GameEntrance(
          delay: const Duration(milliseconds: 110),
          child: widget.minimalHeader
              ? Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: textTheme.headlineSmall),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelMedium?.copyWith(
                              color: const Color(0xffcbd5e1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (trailingActions.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Icon(
                          Icons.sports_esports_rounded,
                          color: widget.accent.last,
                          size: 18,
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: trailingActions
                            .map(
                              (action) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: action,
                              ),
                            )
                            .toList(growable: false),
                      ),
                  ],
                )
              : Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(headerPadding),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(headerRadius),
                    gradient: LinearGradient(colors: widget.accent),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.last.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: IgnorePointer(child: _GameHeroPattern()),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: titleStyle),
                          const SizedBox(height: 8),
                          Text(widget.subtitle, style: subtitleStyle),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
        SizedBox(height: widget.minimalHeader ? 12 : (isCompact ? 16 : 22)),
        if (fillContent)
          Expanded(
            child: _GameEntrance(
              delay: const Duration(milliseconds: 190),
              child: widget.child,
            ),
          )
        else
          _GameEntrance(
            delay: const Duration(milliseconds: 190),
            child: widget.child,
          ),
      ],
    );
  }
}

class ScorePanel extends StatelessWidget {
  const ScorePanel({
    super.key,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.footer,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _stat(leftLabel, leftValue)),
              Container(
                width: 1,
                height: 54,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(child: _stat(rightLabel, rightValue)),
            ],
          ),
          const SizedBox(height: 16),
          Text(footer, style: textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Text(
            value,
            key: ValueKey(value),
            style: AppTextStyles.statValue,
          ),
        ),
      ],
    );
  }
}

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.message,
    this.accent = const Color(0xff38bdf8),
    this.highlight = false,
    this.headline,
  });

  final String message;
  final Color accent;
  final bool highlight;
  final String? headline;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.12),
                ],
              )
            : null,
        color: highlight ? null : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withValues(alpha: highlight ? 0.42 : 0.24),
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey('${headline ?? ''}_$message'),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (highlight && headline != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: accent.withValues(alpha: 0.95),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      headline!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: highlight ? 15 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactMetricCard extends StatelessWidget {
  const CompactMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: const Color(0xff94a3b8),
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              value,
              key: ValueKey(value),
              style: compact ? textTheme.titleMedium : textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class InlineStatusStrip extends StatelessWidget {
  const InlineStatusStrip({
    super.key,
    required this.message,
    required this.accent,
    this.compact = false,
    this.highlight = false,
  });

  final String message;
  final Color accent;
  final bool compact;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.24),
                  accent.withValues(alpha: 0.1),
                ],
              )
            : null,
        color: highlight ? null : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(
          color: accent.withValues(alpha: highlight ? 0.4 : 0.24),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xffe2e8f0),
          height: 1.2,
          fontSize: compact
              ? (message.length > 32 ? 12 : 13)
              : (message.length > 44 ? 12 : 13),
        ),
      ),
    );
  }
}

class HeadToHeadPanel extends StatelessWidget {
  const HeadToHeadPanel({
    super.key,
    required this.leftLabel,
    required this.leftChild,
    required this.rightLabel,
    required this.rightChild,
    this.highlightLeft = false,
    this.highlightRight = false,
  });

  final String leftLabel;
  final Widget leftChild;
  final String rightLabel;
  final Widget rightChild;
  final bool highlightLeft;
  final bool highlightRight;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      child: Row(
        children: [
          Expanded(
            child: _HeadToHeadSlot(
              label: leftLabel,
              highlight: highlightLeft,
              child: leftChild,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _HeadToHeadSlot(
              label: rightLabel,
              highlight: highlightRight,
              child: rightChild,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadToHeadSlot extends StatelessWidget {
  const _HeadToHeadSlot({
    required this.label,
    required this.child,
    required this.highlight,
  });

  final String label;
  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: highlight
            ? const LinearGradient(
                colors: [Color(0x3322c55e), Color(0x1414b8a6)],
              )
            : null,
        border: Border.all(
          color: highlight
              ? const Color(0xff34d399).withValues(alpha: 0.36)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? Colors.white : const Color(0xff94a3b8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class ResetActionButton extends StatelessWidget {
  const ResetActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}

class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _GameEntrance extends StatefulWidget {
  const _GameEntrance({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_GameEntrance> createState() => _GameEntranceState();
}

class _GameEntranceState extends State<_GameEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _visible = true;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (!mounted) return;
        setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final visible = reducedMotion ? true : _visible;
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 0.06),
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: reducedMotion
            ? Duration.zero
            : const Duration(milliseconds: 320),
        child: widget.child,
      ),
    );
  }
}

class _GameHeroPattern extends StatefulWidget {
  const _GameHeroPattern();

  @override
  State<_GameHeroPattern> createState() => _GameHeroPatternState();
}

class _GameHeroPatternState extends State<_GameHeroPattern>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return CustomPaint(painter: _GamePatternPainter(progress: 0.22));
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GamePatternPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _GamePatternPainter extends CustomPainter {
  const _GamePatternPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.08);

    final drift = progress * 24;
    for (double x = -size.height; x < size.width + size.height; x += 40) {
      canvas.drawLine(
        Offset(x + drift, 0),
        Offset(x - size.height + drift, size.height),
        linePaint,
      );
    }

    final orb = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.22), 52, orb);
  }

  @override
  bool shouldRepaint(covariant _GamePatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
