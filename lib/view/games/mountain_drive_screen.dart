import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class MountainDriveScreen extends StatefulWidget {
  const MountainDriveScreen({super.key});

  @override
  State<MountainDriveScreen> createState() => _MountainDriveScreenState();
}

class _MountainDriveScreenState extends State<MountainDriveScreen> {
  static const Duration _tick = Duration(milliseconds: 50);
  static const double _finishDistance = 3000;
  static const List<_HillSection> _sections = [
    _HillSection(
      label: 'Valley Straight',
      start: 0.00,
      end: 0.18,
      curve: 0.00,
      target: 190,
    ),
    _HillSection(
      label: 'Forest Bend',
      start: 0.18,
      end: 0.34,
      curve: 0.52,
      target: 122,
    ),
    _HillSection(
      label: 'Cliff Run',
      start: 0.34,
      end: 0.54,
      curve: -0.18,
      target: 178,
    ),
    _HillSection(
      label: 'Mountain Hairpin',
      start: 0.54,
      end: 0.70,
      curve: -0.82,
      target: 82,
    ),
    _HillSection(
      label: 'Summit Sweep',
      start: 0.70,
      end: 0.86,
      curve: 0.34,
      target: 152,
    ),
    _HillSection(
      label: 'Finish Descent',
      start: 0.86,
      end: 1.00,
      curve: 0.08,
      target: 210,
    ),
  ];

  Timer? _timer;
  final Stopwatch _clock = Stopwatch();

  double _speed = 0;
  double _distance = 0;
  double _rivalDistance = 0;
  double _offset = 0;
  double _grip = 100;
  double _sceneryOffset = 0;
  bool _running = false;
  bool _finished = false;
  bool _throttleHeld = false;
  bool _brakeHeld = false;
  bool _leftHeld = false;
  bool _rightHeld = false;
  String _message =
      'Drive the mountain road cleanly. Use the straights, respect the bends, and beat the rival to the summit.';

  @override
  void dispose() {
    _timer?.cancel();
    _clock.stop();
    super.dispose();
  }

  double get _progress => (_distance / _finishDistance).clamp(0.0, 1.0);

  _HillSection get _section => _sectionFor(_progress);

  _HillSection _sectionFor(double progress) {
    return _sections.firstWhere(
      (section) => progress >= section.start && progress < section.end,
      orElse: () => _sections.last,
    );
  }

  void _startRace() {
    _timer?.cancel();
    _clock
      ..stop()
      ..reset()
      ..start();
    setState(() {
      _speed = 0;
      _distance = 0;
      _rivalDistance = 120;
      _offset = 0;
      _grip = 100;
      _sceneryOffset = 0;
      _running = true;
      _finished = false;
      _throttleHeld = false;
      _brakeHeld = false;
      _leftHeld = false;
      _rightHeld = false;
      _message =
          'Green light. Build speed through the valley before the forest bend.';
    });
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  Future<void> _onTick() async {
    if (!_running || !mounted) return;

    final section = _section;
    var nextSpeed = _speed;
    if (_throttleHeld) {
      nextSpeed += 7.0;
    } else {
      nextSpeed -= 3.3;
    }
    if (_brakeHeld) {
      nextSpeed -= 10.0;
    }
    nextSpeed = nextSpeed.clamp(0.0, 228.0);

    var steer = 0.0;
    if (_leftHeld) steer -= 0.082;
    if (_rightHeld) steer += 0.082;

    final targetOffset = (-section.curve * 0.58).clamp(-1.0, 1.0);
    var nextOffset = _offset + steer;
    if (!_leftHeld && !_rightHeld) {
      nextOffset += (targetOffset - nextOffset) * 0.11;
    }
    nextOffset = nextOffset.clamp(-1.18, 1.18);

    final overspeed = math.max(0, nextSpeed - section.target).toDouble();
    final lineError = (nextOffset - targetOffset).abs();
    final cornerLoad = section.curve.abs();

    var nextGrip = _grip;
    if (cornerLoad > 0.2) {
      nextGrip -= overspeed * 0.05;
      nextGrip -= lineError * 5.8;
    } else {
      nextGrip += 1.4;
    }
    nextGrip = nextGrip.clamp(0.0, 100.0);

    if (nextGrip <= 0 || nextOffset.abs() > 1.08) {
      await _finishRace(
        won: false,
        reason: 'You slipped wide off the mountain road and lost the run.',
      );
      return;
    }

    final nextDistance = _distance + (nextSpeed * 0.78);
    var nextRivalDistance = _rivalDistance;
    final rivalTarget = section.target + 8 - (section.curve.abs() * 20);
    if (nextRivalDistance < _finishDistance) {
      nextRivalDistance += rivalTarget * 0.72;
    }

    if (nextDistance >= _finishDistance) {
      _distance = nextDistance;
      await _finishRace(
        won: nextDistance >= nextRivalDistance,
        reason: nextDistance >= nextRivalDistance
            ? 'Finish line first. You owned the mountain pass.'
            : 'Lap complete, but the rival reached the summit first.',
      );
      return;
    }

    if (nextRivalDistance >= _finishDistance) {
      await _finishRace(
        won: false,
        reason:
            'The rival got to the summit first. Push harder on the next run.',
      );
      return;
    }

    setState(() {
      _speed = nextSpeed;
      _distance = nextDistance;
      _rivalDistance = nextRivalDistance;
      _offset = nextOffset;
      _grip = nextGrip;
      _sceneryOffset = (_sceneryOffset + (nextSpeed * 0.45)) % 180;
      _message = cornerLoad > 0.2 && overspeed > 14
          ? 'Too quick for ${section.label}. Brake and hold the road.'
          : cornerLoad > 0.2
          ? 'Mountain road tightens here. Guide the car through ${section.label}.'
          : nextSpeed < 120
          ? 'Road opens up. Feed in throttle and let the scenery fly by.'
          : 'Clean rhythm. Chase the rival toward ${_nextSection(section).label}.';
    });
  }

  _HillSection _nextSection(_HillSection current) {
    final index = _sections.indexOf(current);
    return _sections[(index + 1) % _sections.length];
  }

  Future<void> _finishRace({required bool won, required String reason}) async {
    _timer?.cancel();
    _clock.stop();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _throttleHeld = false;
      _brakeHeld = false;
      _leftHeld = false;
      _rightHeld = false;
      _message = won
          ? '$reason Time ${_format(_clock.elapsed)}.'
          : '$reason Gap ${((_rivalDistance - _distance) / 10).round()} m.';
    });
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hundredths = ((duration.inMilliseconds % 1000) / 10)
        .floor()
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$hundredths';
  }

  @override
  Widget build(BuildContext context) {
    const accent = [Color(0xff22c55e), Color(0xff0ea5e9)];
    final rivalGap = ((_rivalDistance - _distance) / 10).round();
    return GameScaffold(
      title: 'Mountain Drive',
      subtitle:
          'Race through trees, hills, and mountain roads with a more realistic scenic feel.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Distance',
            leftValue: '${(_distance / 10).floor()} m',
            rightLabel: 'Speed',
            rightValue: '${_speed.round()} km/h',
            footer:
                'Grip ${_grip.round()}% • Rival ${rivalGap >= 0 ? '+' : ''}$rivalGap m • ${_section.label}',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final compact = width < 360;
                final carCenter = width / 2 + (_offset * width * 0.23);
                final rivalShift = ((_rivalDistance - _distance) * 0.06).clamp(
                  -120.0,
                  120.0,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: compact ? 250 : 320,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _MountainScenePainter(
                                curve: _section.curve,
                                sceneryOffset: _sceneryOffset,
                                speed: _speed,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.24),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                _format(_clock.elapsed),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 18,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                _section.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 84 + rivalShift,
                            left: width / 2 - 18,
                            child: const Opacity(
                              opacity: 0.74,
                              child: _ScenicRaceVehicle(
                                color: Color(0xff38bdf8),
                                glow: Color(0xff7dd3fc),
                                scale: 0.84,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 28,
                            left: carCenter - 28,
                            child: Transform.rotate(
                              angle: (_offset + (_section.curve * 0.32)) * 0.24,
                              child: const _ScenicRaceVehicle(
                                color: Color(0xffef4444),
                                glow: Color(0xfffb7185),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xff22c55e),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mountain course progress',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xff94a3b8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: compact ? (width - 12) / 2 : (width - 36) / 4,
                          child: _PressControl(
                            icon: Icons.keyboard_double_arrow_left_rounded,
                            label: 'Left',
                            active: _leftHeld,
                            onChanged: (value) =>
                                setState(() => _leftHeld = value),
                          ),
                        ),
                        SizedBox(
                          width: compact ? (width - 12) / 2 : (width - 36) / 4,
                          child: _PressControl(
                            icon: Icons.speed_rounded,
                            label: 'Throttle',
                            active: _throttleHeld,
                            accent: const Color(0xff22c55e),
                            onChanged: (value) =>
                                setState(() => _throttleHeld = value),
                          ),
                        ),
                        SizedBox(
                          width: compact ? (width - 12) / 2 : (width - 36) / 4,
                          child: _PressControl(
                            icon: Icons.stop_circle_outlined,
                            label: 'Brake',
                            active: _brakeHeld,
                            accent: const Color(0xffef4444),
                            onChanged: (value) =>
                                setState(() => _brakeHeld = value),
                          ),
                        ),
                        SizedBox(
                          width: compact ? (width - 12) / 2 : (width - 36) / 4,
                          child: _PressControl(
                            icon: Icons.keyboard_double_arrow_right_rounded,
                            label: 'Right',
                            active: _rightHeld,
                            onChanged: (value) =>
                                setState(() => _rightHeld = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _running ? null : _startRace,
                        child: Text(
                          _finished ? 'Drive again' : 'Start mountain race',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HillSection {
  const _HillSection({
    required this.label,
    required this.start,
    required this.end,
    required this.curve,
    required this.target,
  });

  final String label;
  final double start;
  final double end;
  final double curve;
  final int target;
}

class _PressControl extends StatelessWidget {
  const _PressControl({
    required this.icon,
    required this.label,
    required this.active,
    required this.onChanged,
    this.accent = const Color(0xff38bdf8),
  });

  final IconData icon;
  final String label;
  final bool active;
  final ValueChanged<bool> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onChanged(true),
      onTapUp: (_) => onChanged(false),
      onTapCancel: () => onChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: accent.withValues(alpha: active ? 0.28 : 0.14),
          border: Border.all(
            color: accent.withValues(alpha: active ? 0.72 : 0.32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenicRaceVehicle extends StatelessWidget {
  const _ScenicRaceVehicle({
    required this.color,
    required this.glow,
    this.scale = 1,
  });

  final Color color;
  final Color glow;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 56,
        height: 78,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.36),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 12,
              right: 12,
              top: 4,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.24), color],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              right: 6,
              bottom: 22,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xff0f172a),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Positioned(
              left: 5,
              top: 12,
              width: 10,
              height: 20,
              child: _wheel(),
            ),
            Positioned(
              right: 5,
              top: 12,
              width: 10,
              height: 20,
              child: _wheel(),
            ),
            Positioned(
              left: 5,
              bottom: 12,
              width: 10,
              height: 20,
              child: _wheel(),
            ),
            Positioned(
              right: 5,
              bottom: 12,
              width: 10,
              height: 20,
              child: _wheel(),
            ),
            Positioned(
              left: 18,
              right: 18,
              top: 14,
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xffdbeafe).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wheel() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff020617),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _MountainScenePainter extends CustomPainter {
  const _MountainScenePainter({
    required this.curve,
    required this.sceneryOffset,
    required this.speed,
  });

  final double curve;
  final double sceneryOffset;
  final double speed;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xff7dd3fc), Color(0xffd9f99d)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final mountainBack = Path()
      ..moveTo(0, size.height * 0.42)
      ..lineTo(size.width * 0.12, size.height * 0.24)
      ..lineTo(size.width * 0.24, size.height * 0.39)
      ..lineTo(size.width * 0.38, size.height * 0.18)
      ..lineTo(size.width * 0.52, size.height * 0.37)
      ..lineTo(size.width * 0.68, size.height * 0.20)
      ..lineTo(size.width * 0.84, size.height * 0.40)
      ..lineTo(size.width, size.height * 0.28)
      ..lineTo(size.width, size.height * 0.54)
      ..lineTo(0, size.height * 0.54)
      ..close();
    canvas.drawPath(mountainBack, Paint()..color = const Color(0xff64748b));

    final mountainFront = Path()
      ..moveTo(0, size.height * 0.56)
      ..lineTo(size.width * 0.14, size.height * 0.34)
      ..lineTo(size.width * 0.28, size.height * 0.50)
      ..lineTo(size.width * 0.44, size.height * 0.30)
      ..lineTo(size.width * 0.58, size.height * 0.52)
      ..lineTo(size.width * 0.74, size.height * 0.32)
      ..lineTo(size.width * 0.92, size.height * 0.50)
      ..lineTo(size.width, size.height * 0.46)
      ..lineTo(size.width, size.height * 0.68)
      ..lineTo(0, size.height * 0.68)
      ..close();
    canvas.drawPath(mountainFront, Paint()..color = const Color(0xff475569));

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.60, size.width, size.height * 0.40),
      Paint()..color = const Color(0xff65a30d),
    );

    final roadTopWidth = size.width * 0.22;
    final roadBottomWidth = size.width * 0.92;
    final roadCenter = size.width / 2 + (curve * size.width * 0.18);
    final road = Path()
      ..moveTo(roadCenter - roadTopWidth / 2, size.height * 0.56)
      ..lineTo(roadCenter + roadTopWidth / 2, size.height * 0.56)
      ..lineTo(size.width / 2 + roadBottomWidth / 2, size.height)
      ..lineTo(size.width / 2 - roadBottomWidth / 2, size.height)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xff374151));

    final shoulderPaint = Paint()
      ..color = const Color(0xfff59e0b).withValues(alpha: 0.6);
    final leftShoulder = Path()
      ..moveTo(roadCenter - roadTopWidth / 2 - 8, size.height * 0.56)
      ..lineTo(roadCenter - roadTopWidth / 2, size.height * 0.56)
      ..lineTo(size.width / 2 - roadBottomWidth / 2, size.height)
      ..lineTo(size.width / 2 - roadBottomWidth / 2 - 18, size.height)
      ..close();
    final rightShoulder = Path()
      ..moveTo(roadCenter + roadTopWidth / 2 + 8, size.height * 0.56)
      ..lineTo(roadCenter + roadTopWidth / 2, size.height * 0.56)
      ..lineTo(size.width / 2 + roadBottomWidth / 2, size.height)
      ..lineTo(size.width / 2 + roadBottomWidth / 2 + 18, size.height)
      ..close();
    canvas.drawPath(leftShoulder, shoulderPaint);
    canvas.drawPath(rightShoulder, shoulderPaint);

    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 4;
    for (
      double y = size.height * 0.60;
      y < size.height;
      y += 36 + (100 - speed) * 0.04
    ) {
      final t = (y - size.height * 0.56) / (size.height * 0.44);
      final centerShift = curve * 90 * (1 - t);
      final laneX = (size.width / 2) + centerShift;
      final laneHalf = lerpDouble(6, 30, t)!;
      canvas.drawLine(
        Offset(laneX - laneHalf, y),
        Offset(laneX - laneHalf + (t * 4), y + 16),
        lanePaint,
      );
      canvas.drawLine(
        Offset(laneX + laneHalf, y),
        Offset(laneX + laneHalf - (t * 4), y + 16),
        lanePaint,
      );
    }

    _paintTreeRow(canvas, size, left: true);
    _paintTreeRow(canvas, size, left: false);
  }

  void _paintTreeRow(Canvas canvas, Size size, {required bool left}) {
    final baseX = left ? size.width * 0.15 : size.width * 0.85;
    for (var index = 0; index < 7; index++) {
      final raw = ((index * 34.0) + sceneryOffset) % 180;
      final y = size.height - raw;
      if (y < size.height * 0.46 || y > size.height) continue;
      final scale = ((y - size.height * 0.46) / (size.height * 0.54)).clamp(
        0.2,
        1.0,
      );
      final shift = curve * 40 * (1 - scale);
      final x = left
          ? baseX + shift - (scale * 26)
          : baseX + shift + (scale * 26);
      final foliage = Path()
        ..moveTo(x, y - 28 * scale)
        ..lineTo(x - 16 * scale, y)
        ..lineTo(x + 16 * scale, y)
        ..close();
      canvas.drawPath(foliage, Paint()..color = const Color(0xff166534));
      canvas.drawPath(
        Path()
          ..moveTo(x, y - 44 * scale)
          ..lineTo(x - 20 * scale, y - 10 * scale)
          ..lineTo(x + 20 * scale, y - 10 * scale)
          ..close(),
        Paint()..color = const Color(0xff15803d),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, y + 10 * scale),
          width: 4 * scale,
          height: 16 * scale,
        ),
        Paint()..color = const Color(0xff7c2d12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MountainScenePainter oldDelegate) {
    return oldDelegate.curve != curve ||
        oldDelegate.sceneryOffset != sceneryOffset ||
        oldDelegate.speed != speed;
  }
}
