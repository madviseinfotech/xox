// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dashBoardScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentOpacity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 0.58, curve: Curves.easeOutBack),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.22, 1, curve: Curves.easeOut),
    );
    _timer = Timer(const Duration(milliseconds: 2800), _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const DashBoardScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xff04111a),
                  Color(0xff0a1d26),
                  Color(0xff08111b),
                ],
              ),
            ),
          ),
          Positioned(
            top: -110,
            left: -90,
            child: _GlowOrb(
              size: 260,
              color: const Color(0xff14b8a6).withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            right: -60,
            top: 120,
            child: _GlowOrb(
              size: 210,
              color: const Color(0xfff59e0b).withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            left: -20,
            bottom: 110,
            child: _GlowOrb(
              size: 170,
              color: const Color(0xff38bdf8).withValues(alpha: 0.08),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ArcadeGridPainter(
                  lineColor: Colors.white.withValues(alpha: 0.035),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: FadeTransition(
                opacity: _contentOpacity,
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        '25+ games ready',
                        style: textTheme.labelLarge?.copyWith(
                          color: const Color(0xffcbd5e1),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'XOX Arcade',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        fontSize: 44,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Arcade fun, kids learning, puzzles, and local two-player play in one colorful game world.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xffcbd5e1),
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xff102a36),
                              const Color(0xff182535),
                              const Color(0xff241a34),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xff14b8a6,
                              ).withValues(alpha: 0.16),
                              blurRadius: 24,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _SplashStat(
                                    label: 'Games',
                                    value: '25+',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _SplashStat(
                                    label: 'Learning',
                                    value: '10+',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _SplashStat(
                                    label: 'Modes',
                                    value: 'Solo + 2P',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _SplashMiniCard(
                                    icon: Icons.sports_esports_rounded,
                                    title: 'Quick arcade',
                                    subtitle: 'Tap, race, guess, and play',
                                    accent: const Color(0xff14b8a6),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _SplashMiniCard(
                                    icon: Icons.school_rounded,
                                    title: 'Kids learning',
                                    subtitle: 'Words, counting, colors',
                                    accent: const Color(0xfff59e0b),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'What is inside',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: const Color(0xffcbd5e1),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _SplashModePill(
                                        icon: Icons.extension_rounded,
                                        label: 'Puzzle',
                                      ),
                                      _SplashModePill(
                                        icon: Icons.groups_rounded,
                                        label: '2 Player',
                                      ),
                                      _SplashModePill(
                                        icon: Icons.psychology_rounded,
                                        label: 'Brain Games',
                                      ),
                                      _SplashModePill(
                                        icon: Icons.child_care_rounded,
                                        label: 'Kids',
                                      ),
                                      _SplashModePill(
                                        icon: Icons.casino_rounded,
                                        label: 'Lucky Play',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _SplashChip(label: '2 Player'),
                        _SplashChip(label: 'Kids'),
                        _SplashChip(label: 'Puzzle'),
                        _SplashChip(label: 'Arcade'),
                        _SplashChip(label: 'Learning'),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Loading your game hub...',
                            style: textTheme.titleMedium?.copyWith(
                              color: const Color(0xffe2e8f0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 50, spreadRadius: 12)],
      ),
    );
  }
}

class _SplashChip extends StatelessWidget {
  const _SplashChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: const Color(0xffe2e8f0)),
      ),
    );
  }
}

class _SplashStat extends StatelessWidget {
  const _SplashStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashMiniCard extends StatelessWidget {
  const _SplashMiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 10),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: textTheme.labelMedium?.copyWith(
              color: const Color(0xffcbd5e1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashModePill extends StatelessWidget {
  const _SplashModePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xffe2e8f0)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xffe2e8f0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcadeGridPainter extends CustomPainter {
  const _ArcadeGridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const spacing = 48.0;

    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcadeGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
