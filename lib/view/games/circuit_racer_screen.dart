import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class CircuitRacerScreen extends StatefulWidget {
  const CircuitRacerScreen({super.key});

  @override
  State<CircuitRacerScreen> createState() => _CircuitRacerScreenState();
}

class _CircuitRacerScreenState extends State<CircuitRacerScreen> {
  static const Duration _tick = Duration(milliseconds: 50);
  static const double _trackLength = 3200;
  static const int _targetLaps = 3;
  static const double _maxTrackOffset = 1.0;
  static const List<_TrackSection> _sections = [
    _TrackSection(
      label: 'Main Straight',
      start: 0.00,
      end: 0.18,
      recommendedSpeed: 220,
      curve: 0.00,
    ),
    _TrackSection(
      label: 'Turn 1',
      start: 0.18,
      end: 0.31,
      recommendedSpeed: 110,
      curve: 0.72,
    ),
    _TrackSection(
      label: 'Back Straight',
      start: 0.31,
      end: 0.52,
      recommendedSpeed: 230,
      curve: -0.12,
    ),
    _TrackSection(
      label: 'Hairpin',
      start: 0.52,
      end: 0.64,
      recommendedSpeed: 82,
      curve: -0.90,
    ),
    _TrackSection(
      label: 'Middle Sector',
      start: 0.64,
      end: 0.82,
      recommendedSpeed: 170,
      curve: 0.34,
    ),
    _TrackSection(
      label: 'Final Chicane',
      start: 0.82,
      end: 1.00,
      recommendedSpeed: 118,
      curve: -0.66,
    ),
  ];

  Timer? _timer;
  final Stopwatch _raceClock = Stopwatch();

  double _playerSpeed = 0;
  double _rivalSpeed = 0;
  double _playerDistance = 0;
  double _rivalDistance = 0;
  double _trackOffset = 0;
  double _grip = 100;
  int _lap = 1;
  int _rivalLap = 1;
  bool _raceRunning = false;
  bool _finished = false;
  bool _throttleHeld = false;
  bool _brakeHeld = false;
  bool _steerLeftHeld = false;
  bool _steerRightHeld = false;
  String _message =
      'Hold throttle on the straights, brake before corners, and complete 3 laps.';

  @override
  void dispose() {
    _timer?.cancel();
    _raceClock.stop();
    super.dispose();
  }

  _TrackSection get _playerSection => _sectionForProgress(_playerProgress);

  _TrackSection get _rivalSection => _sectionForProgress(_rivalProgress);

  double get _playerProgress => (_playerDistance % _trackLength) / _trackLength;

  double get _rivalProgress => (_rivalDistance % _trackLength) / _trackLength;

  void _startRace() {
    _timer?.cancel();
    _raceClock
      ..stop()
      ..reset()
      ..start();
    setState(() {
      _playerSpeed = 0;
      _rivalSpeed = 126;
      _playerDistance = 0;
      _rivalDistance = 0;
      _trackOffset = 0;
      _grip = 100;
      _lap = 1;
      _rivalLap = 1;
      _raceRunning = true;
      _finished = false;
      _throttleHeld = false;
      _brakeHeld = false;
      _steerLeftHeld = false;
      _steerRightHeld = false;
      _message =
          'Green light. Build speed on the straight, then brake into Turn 1.';
    });
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  _TrackSection _sectionForProgress(double progress) {
    return _sections.firstWhere(
      (section) => progress >= section.start && progress < section.end,
      orElse: () => _sections.last,
    );
  }

  Future<void> _onTick() async {
    if (!_raceRunning || !mounted) return;

    final playerSection = _playerSection;
    final rivalSection = _rivalSection;

    var nextSpeed = _playerSpeed;
    if (_throttleHeld) {
      nextSpeed += 7.5;
    } else {
      nextSpeed -= 3.4;
    }
    if (_brakeHeld) {
      nextSpeed -= 10.5;
    }
    nextSpeed = nextSpeed.clamp(0.0, 252.0);

    var steerForce = 0.0;
    if (_steerLeftHeld) steerForce -= 0.085;
    if (_steerRightHeld) steerForce += 0.085;

    final desiredOffset = (-playerSection.curve * 0.58).clamp(
      -_maxTrackOffset,
      _maxTrackOffset,
    );
    var nextOffset = _trackOffset + steerForce;
    if (!_steerLeftHeld && !_steerRightHeld) {
      nextOffset += (desiredOffset - nextOffset) * 0.12;
    }
    nextOffset = nextOffset.clamp(-1.2, 1.2);

    var nextGrip = _grip;
    final overspeed =
        math.max(0, nextSpeed - playerSection.recommendedSpeed).toDouble();
    final racingLineError = (nextOffset - desiredOffset).abs();
    final cornerStress = playerSection.curve.abs();

    if (cornerStress > 0.2) {
      nextGrip -= overspeed * 0.045;
      nextGrip -= racingLineError * 5.5;
    } else {
      nextGrip += 1.6;
    }
    nextGrip = nextGrip.clamp(0.0, 100.0);

    if (nextGrip <= 0 || nextOffset.abs() > 1.1) {
      await _finishRace(playerWon: false, reason: 'You lost grip and spun off.');
      return;
    }

    final playerDistanceBefore = _playerDistance;
    final rivalDistanceBefore = _rivalDistance;
    final nextPlayerDistance = playerDistanceBefore + (nextSpeed * 0.82);

    var nextRivalSpeed = _rivalSpeed;
    final rivalTarget = rivalSection.recommendedSpeed + 10 - (rivalSection.curve.abs() * 18);
    if (nextRivalSpeed < rivalTarget) {
      nextRivalSpeed += 4.8;
    } else {
      nextRivalSpeed -= 4.1;
    }
    nextRivalSpeed = nextRivalSpeed.clamp(72.0, 225.0);
    final nextRivalDistance = rivalDistanceBefore + (nextRivalSpeed * 0.78);

    final nextLap = (nextPlayerDistance / _trackLength).floor() + 1;
    final nextRivalLap = (nextRivalDistance / _trackLength).floor() + 1;

    if (nextLap > _targetLaps) {
      await _finishRace(
        playerWon: true,
        reason: 'Chequered flag. You brought it home in front.',
      );
      return;
    }
    if (nextRivalLap > _targetLaps) {
      await _finishRace(
        playerWon: false,
        reason: 'The rival crossed the line first.',
      );
      return;
    }

    setState(() {
      _playerSpeed = nextSpeed;
      _rivalSpeed = nextRivalSpeed;
      _playerDistance = nextPlayerDistance;
      _rivalDistance = nextRivalDistance;
      _trackOffset = nextOffset;
      _grip = nextGrip;
      _lap = nextLap;
      _rivalLap = nextRivalLap;
      if (cornerStress > 0.2 && overspeed > 18) {
        _message =
            'Too fast for ${playerSection.label}. Brake and tighten your line.';
      } else if (cornerStress > 0.2) {
        _message = 'Set the car for ${playerSection.label}. Hold the racing line.';
      } else if (nextSpeed < 120) {
        _message = 'Main straight is open. Feed in more throttle.';
      } else {
        _message = 'Good pace. Prepare for ${_nextSection(playerSection).label}.';
      }
    });
  }

  _TrackSection _nextSection(_TrackSection current) {
    final index = _sections.indexOf(current);
    return _sections[(index + 1) % _sections.length];
  }

  Future<void> _finishRace({
    required bool playerWon,
    required String reason,
  }) async {
    _timer?.cancel();
    _raceClock.stop();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _raceRunning = false;
      _finished = true;
      _throttleHeld = false;
      _brakeHeld = false;
      _steerLeftHeld = false;
      _steerRightHeld = false;
      _message = playerWon
          ? '$reason Final time: ${_formatDuration(_raceClock.elapsed)}.'
          : reason;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hundredths =
        ((duration.inMilliseconds % 1000) / 10).floor().toString().padLeft(2, '0');
    return '$minutes:$seconds.$hundredths';
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xffef4444), Color(0xfff97316)];
    return GameScaffold(
      title: 'Circuit Racer',
      subtitle:
          'Throttle, brake, and steer through corners like a real track session.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Lap',
            leftValue: '$_lap/$_targetLaps',
            rightLabel: 'Speed',
            rightValue: '${_playerSpeed.round()} km/h',
            footer:
                'Grip ${_grip.round()}% • Rival lap $_rivalLap • Gap ${((_rivalDistance - _playerDistance) / 10).round()} m',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final panelWidth = constraints.maxWidth;
                final screenHeight = MediaQuery.sizeOf(context).height;
                final compact = screenHeight < 760 || panelWidth < 340;
                final trackHeight = compact ? 220.0 : 300.0;
                final controlWidth = panelWidth < 420
                    ? ((panelWidth - 12) / 2)
                    : ((panelWidth - 36) / 4);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTrackView(height: trackHeight),
                    SizedBox(height: compact ? 12 : 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TelemetryChip(
                            label: 'Section',
                            value: _playerSection.label,
                            compact: compact,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TelemetryChip(
                            label: 'Target',
                            value: '${_playerSection.recommendedSpeed} km/h',
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _playerProgress,
                      minHeight: compact ? 8 : 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xfff97316),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track progress',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xff94a3b8),
                      ),
                    ),
                    SizedBox(height: compact ? 14 : 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: controlWidth,
                          child: _HoldButton(
                            icon: Icons.keyboard_double_arrow_left_rounded,
                            label: 'Left',
                            active: _steerLeftHeld,
                            compact: compact,
                            onChanged: (active) {
                              setState(() => _steerLeftHeld = active);
                            },
                          ),
                        ),
                        SizedBox(
                          width: controlWidth,
                          child: _HoldButton(
                            icon: Icons.speed_rounded,
                            label: 'Throttle',
                            active: _throttleHeld,
                            compact: compact,
                            accent: const Color(0xff22c55e),
                            onChanged: (active) {
                              setState(() => _throttleHeld = active);
                            },
                          ),
                        ),
                        SizedBox(
                          width: controlWidth,
                          child: _HoldButton(
                            icon: Icons.stop_circle_outlined,
                            label: 'Brake',
                            active: _brakeHeld,
                            compact: compact,
                            accent: const Color(0xffef4444),
                            onChanged: (active) {
                              setState(() => _brakeHeld = active);
                            },
                          ),
                        ),
                        SizedBox(
                          width: controlWidth,
                          child: _HoldButton(
                            icon: Icons.keyboard_double_arrow_right_rounded,
                            label: 'Right',
                            active: _steerRightHeld,
                            compact: compact,
                            onChanged: (active) {
                              setState(() => _steerRightHeld = active);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _raceRunning ? null : _startRace,
                        child: Text(_finished ? 'Race again' : 'Start race'),
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

  Widget _buildTrackView({required double height}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final carCenter = width / 2 + (_trackOffset * width * 0.22);
        final curveDrift = _playerSection.curve * 36;
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff0f172a), Color(0xff020617)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CustomPaint(
                      painter: _RoadPainter(
                        laneOffset: curveDrift,
                        speed: _playerSpeed,
                        grip: _grip,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    _formatDuration(_raceClock.elapsed),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    _playerSection.label,
                    style: const TextStyle(
                      color: Color(0xffe2e8f0),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 36,
                left: carCenter - 26,
                child: Transform.rotate(
                  angle: (_trackOffset + _playerSection.curve * 0.35) * 0.32,
                  child: _CarSprite(
                    color: const Color(0xfff97316),
                    glow: const Color(0xfffb7185),
                  ),
                ),
              ),
              Positioned(
                top: 86,
                left: width / 2 + ((_rivalProgress - _playerProgress) * width * 0.75),
                child: Opacity(
                  opacity: 0.78,
                  child: const _CarSprite(
                    color: Color(0xff38bdf8),
                    glow: Color(0xff60a5fa),
                    scale: 0.82,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrackSection {
  const _TrackSection({
    required this.label,
    required this.start,
    required this.end,
    required this.recommendedSpeed,
    required this.curve,
  });

  final String label;
  final double start;
  final double end;
  final int recommendedSpeed;
  final double curve;
}

class _TelemetryChip extends StatelessWidget {
  const _TelemetryChip({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xff94a3b8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 15 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onChanged,
    this.compact = false,
    this.accent = const Color(0xff38bdf8),
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool compact;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onChanged(true),
      onTapUp: (_) => onChanged(false),
      onTapCancel: () => onChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(vertical: compact ? 12 : 14),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? accent : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? accent : Colors.white, size: compact ? 22 : 24),
            SizedBox(height: compact ? 4 : 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                fontSize: compact ? 13 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarSprite extends StatelessWidget {
  const _CarSprite({
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
        width: 52,
        height: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, glow],
          ),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 24,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xffdbeafe),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: 18,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter({
    required this.laneOffset,
    required this.speed,
    required this.grip,
  });

  final double laneOffset;
  final double speed;
  final double grip;

  @override
  void paint(Canvas canvas, Size size) {
    final roadRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final roadPaint = Paint()..color = const Color(0xff1f2937);
    final edgePaint = Paint()
      ..color = const Color(0xffef4444).withValues(alpha: 0.85)
      ..strokeWidth = 5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(roadRect, const Radius.circular(24)),
      roadPaint,
    );

    final centerX = size.width / 2 + laneOffset;
    final leftEdgeTop = centerX - (size.width * 0.22);
    final rightEdgeTop = centerX + (size.width * 0.22);
    final leftEdgeBottom = size.width * 0.18;
    final rightEdgeBottom = size.width * 0.82;

    final leftPath = Path()
      ..moveTo(leftEdgeTop, 0)
      ..lineTo(leftEdgeBottom, size.height);
    final rightPath = Path()
      ..moveTo(rightEdgeTop, 0)
      ..lineTo(rightEdgeBottom, size.height);
    canvas.drawPath(leftPath, edgePaint);
    canvas.drawPath(rightPath, edgePaint);

    final dashCount = 9;
    final roadCenterBottom = (leftEdgeBottom + rightEdgeBottom) / 2;
    for (var i = 0; i < dashCount; i++) {
      final progress = i / dashCount;
      final y = ((progress * size.height) + (speed * 2.6)) % (size.height + 34) - 34;
      final lerpX =
          lerpDouble(centerX, roadCenterBottom, y / size.height) ?? centerX;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(lerpX, y), width: 8, height: 26),
          const Radius.circular(999),
        ),
        Paint()..color = const Color(0xCCFFFFFF),
      );
    }

    final gripGlow = Paint()
      ..color = (grip < 35 ? const Color(0xffef4444) : const Color(0xff22c55e))
          .withValues(alpha: 0.12);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 52, size.width, 52),
      gripGlow,
    );
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) {
    return oldDelegate.laneOffset != laneOffset ||
        oldDelegate.speed != speed ||
        oldDelegate.grip != grip;
  }
}
