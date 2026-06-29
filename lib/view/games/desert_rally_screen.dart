import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class DesertRallyScreen extends StatefulWidget {
  const DesertRallyScreen({super.key});

  @override
  State<DesertRallyScreen> createState() => _DesertRallyScreenState();
}

class _DesertRallyScreenState extends State<DesertRallyScreen> {
  static const double _trackWidth = 220;
  static const double _trackHeight = 380;
  static const double _playerWidth = 34;
  static const double _playerHeight = 64;
  static const double _hazardSize = 32;

  final math.Random _random = math.Random();
  final List<_RallyHazard> _hazards = [];
  Timer? _timer;

  double _playerX = 0;
  double _roadCenterX = 0;
  double _curveTargetX = 0;
  double _curveProgress = 0;
  double _distance = 0;
  double _speed = 5.4;
  double _dashOffset = 0;
  int _score = 0;
  int _heat = 0;
  int _boostFrames = 0;
  int _steerDirection = 0;
  bool _running = false;
  bool _finished = false;
  String _message =
      'Steer through the desert, stay on the road, and avoid rocks.';

  @override
  void initState() {
    super.initState();
    _resetRun();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetRun() {
    _timer?.cancel();
    _hazards
      ..clear()
      ..addAll(
        List<_RallyHazard>.generate(4, (index) {
          final laneShift = (index.isEven ? -1 : 1) * (34 + index * 10);
          return _RallyHazard(
            x: laneShift.toDouble(),
            y: -70.0 - (index * 120),
            type: index == 2 ? _RallyHazardType.boost : _RallyHazardType.rock,
          );
        }),
      );
    setState(() {
      _playerX = 0;
      _roadCenterX = 0;
      _curveTargetX = 0;
      _curveProgress = 0;
      _distance = 0;
      _speed = 5.4;
      _dashOffset = 0;
      _score = 0;
      _heat = 0;
      _boostFrames = 0;
      _steerDirection = 0;
      _running = false;
      _finished = false;
      _message =
          'Steer through the desert, stay on the road, and avoid rocks.';
    });
  }

  void _startRun() {
    _resetRun();
    setState(() {
      _running = true;
      _message =
          'Rally live. Use short steering moves and hold the racing line.';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!_running || !mounted) return;

    final boosted = _boostFrames > 0;
    final steeringGrip = boosted ? 8.6 : 7.1;
    final nextPlayerX = (_playerX + (_steerDirection * steeringGrip)).clamp(
      -140.0,
      140.0,
    );

    final nextCurveProgress = _curveProgress + 0.018;
    double nextCurveTargetX = _curveTargetX;
    if (nextCurveProgress >= 1) {
      nextCurveTargetX = (_random.nextDouble() * 120) - 60;
    }
    final curveBlend = nextCurveProgress >= 1 ? 0.0 : nextCurveProgress;
    final nextRoadCenterX =
        _roadCenterX +
        (nextCurveTargetX - _roadCenterX) * (0.08 + curveBlend * 0.02);

    final pace = _speed + (boosted ? 2.6 : 0);
    final playerY = _trackHeight - _playerHeight - 16;
    final updatedHazards = <_RallyHazard>[];
    var crashed = false;
    var passedHazards = 0;
    var collectedBoost = false;

    for (final hazard in _hazards) {
      final nextY = hazard.y + pace;
      final roadAdjustedX = hazard.x + (nextRoadCenterX * 0.85);
      final overlapX =
          (roadAdjustedX - nextPlayerX).abs() <
          (_playerWidth + _hazardSize) / 2;
      final overlapY =
          nextY < playerY + _playerHeight - 8 &&
          nextY + _hazardSize > playerY + 8;

      if (overlapX && overlapY) {
        if (hazard.type == _RallyHazardType.boost) {
          collectedBoost = true;
          continue;
        }
        crashed = true;
        break;
      }

      if (nextY > _trackHeight + 36) {
        passedHazards += hazard.type == _RallyHazardType.rock ? 1 : 0;
        continue;
      }

      updatedHazards.add(hazard.copyWith(y: nextY));
    }

    if (crashed) {
      await _finishRun(
        'Rock hit. Distance ${(_distance / 10).floor()} m with $_score clean passes.',
      );
      return;
    }

    if (updatedHazards.length < 5) {
      final offset =
          (_random.nextDouble() * (_trackWidth - 70)) -
          ((_trackWidth - 70) / 2);
      updatedHazards.add(
        _RallyHazard(
          x: offset,
          y: -_hazardSize - _random.nextInt(90),
          type: _random.nextDouble() < 0.18
              ? _RallyHazardType.boost
              : _RallyHazardType.rock,
        ),
      );
    }

    final roadEdgeBuffer = (_trackWidth / 2) - 18;
    final offRoad = (nextPlayerX - nextRoadCenterX).abs() > roadEdgeBuffer;
    final nextHeat = offRoad
        ? math.min(100, _heat + (boosted ? 4 : 6))
        : math.max(0, _heat - 7);

    if (nextHeat >= 100) {
      await _finishRun(
        'You slid off the road. Keep the car inside the rally track.',
      );
      return;
    }

    final nextDistance = _distance + (pace * 2.1);
    final nextScore = _score + passedHazards + (collectedBoost ? 2 : 0);
    final nextBoostFrames = collectedBoost
        ? 36
        : (_boostFrames > 0 ? _boostFrames - 1 : 0);

    setState(() {
      _playerX = nextPlayerX;
      _roadCenterX = nextRoadCenterX;
      _curveTargetX = nextCurveTargetX;
      _curveProgress = nextCurveProgress >= 1 ? 0 : nextCurveProgress;
      _distance = nextDistance;
      _speed = math.min(9.8, _speed + 0.012);
      _dashOffset = (_dashOffset + pace) % 42;
      _score = nextScore;
      _heat = nextHeat;
      _boostFrames = nextBoostFrames;
      _hazards
        ..clear()
        ..addAll(updatedHazards);
      _message = collectedBoost
          ? 'Nitro canister picked. Push the next section.'
          : offRoad
          ? 'Dust cloud up. Move back to the middle of the road.'
          : passedHazards > 0
          ? 'Clean dodge. Desert ${(nextDistance / 10).floor()} m.'
          : boosted
          ? 'Boost active. The rally car is flying.'
          : 'Keep the nose straight and prepare for the next bend.';
    });
  }

  Future<void> _finishRun(String reason) async {
    _timer?.cancel();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _steerDirection = 0;
      _message = reason;
    });
  }

  Color _heatColor() {
    if (_heat < 35) return const Color(0xff22c55e);
    if (_heat < 70) return const Color(0xfff59e0b);
    return const Color(0xffef4444);
  }

  @override
  Widget build(BuildContext context) {
    const accent = [Color(0xfff97316), Color(0xfffacc15)];

    return GameScaffold(
      title: 'Desert Rally',
      subtitle:
          'Race through a shifting desert road, dodge rocks, and recover before the sand traps you.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Distance',
            leftValue: '${(_distance / 10).floor()} m',
            rightLabel: 'Score',
            rightValue: '$_score',
            footer:
                'Heat $_heat%  •  Speed ${_speed.toStringAsFixed(1)}  •  ${_boostFrames > 0 ? 'Boost live' : 'Rally run'}',
          ),
          const SizedBox(height: 14),
          StatusCard(
            message: _message,
            accent: _finished
                ? const Color(0xffef4444)
                : (_boostFrames > 0
                      ? const Color(0xfffacc15)
                      : const Color(0xfff97316)),
            highlight: _finished || _boostFrames > 0,
          ),
          const SizedBox(height: 14),
          GamePanel(
            child: Column(
              children: [
                _RallyTrack(
                  playerX: _playerX,
                  roadCenterX: _roadCenterX,
                  dashOffset: _dashOffset,
                  heat: _heat,
                  heatColor: _heatColor(),
                  hazards: _hazards,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SteerButton(
                        icon: Icons.keyboard_arrow_left_rounded,
                        label: 'Left',
                        onPressChanged: (pressed) {
                          if (!_running) return;
                          setState(() {
                            _steerDirection = pressed ? -1 : 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _running ? _resetRun : _startRun,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _running
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xfff97316),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                        ),
                        icon: Icon(
                          _running
                              ? Icons.refresh_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(_running ? 'Restart' : 'Start'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SteerButton(
                        icon: Icons.keyboard_arrow_right_rounded,
                        label: 'Right',
                        onPressChanged: (pressed) {
                          if (!_running) return;
                          setState(() {
                            _steerDirection = pressed ? 1 : 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SteerButton extends StatelessWidget {
  const _SteerButton({
    required this.icon,
    required this.label,
    required this.onPressChanged,
  });

  final IconData icon;
  final String label;
  final ValueChanged<bool> onPressChanged;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onPressChanged(true),
      onPointerUp: (_) => onPressChanged(false),
      onPointerCancel: (_) => onPressChanged(false),
      child: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _RallyTrack extends StatelessWidget {
  const _RallyTrack({
    required this.playerX,
    required this.roadCenterX,
    required this.dashOffset,
    required this.heat,
    required this.heatColor,
    required this.hazards,
  });

  final double playerX;
  final double roadCenterX;
  final double dashOffset;
  final int heat;
  final Color heatColor;
  final List<_RallyHazard> hazards;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _DesertRallyScreenState._trackHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          return ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xfff59e0b).withValues(alpha: 0.32),
                          const Color(0xff451a03),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RallyTrackPainter(
                      roadCenterX: roadCenterX,
                      dashOffset: dashOffset,
                    ),
                  ),
                ),
                for (final hazard in hazards)
                  Positioned(
                    left:
                        centerX +
                        hazard.x +
                        (roadCenterX * 0.85) -
                        (_DesertRallyScreenState._hazardSize / 2),
                    top: hazard.y,
                    child: _HazardChip(type: hazard.type),
                  ),
                Positioned(
                  left:
                      centerX +
                      playerX -
                      (_DesertRallyScreenState._playerWidth / 2),
                  bottom: 16,
                  child: const _PlayerCar(),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  top: 14,
                  child: LinearProgressIndicator(
                    value: heat / 100,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: Colors.black.withValues(alpha: 0.18),
                    valueColor: AlwaysStoppedAnimation<Color>(heatColor),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RallyTrackPainter extends CustomPainter {
  const _RallyTrackPainter({
    required this.roadCenterX,
    required this.dashOffset,
  });

  final double roadCenterX;
  final double dashOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final desertPaint = Paint()
      ..color = const Color(0xfff59e0b).withValues(alpha: 0.18);
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawCircle(Offset(28 + ((y * 0.37) % 26), y), 10, desertPaint);
      canvas.drawCircle(
        Offset(size.width - 28 - ((y * 0.28) % 22), y + 12),
        8,
        desertPaint,
      );
    }

    final roadRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset((size.width / 2) + roadCenterX, size.height / 2),
        width: _DesertRallyScreenState._trackWidth,
        height: size.height + 24,
      ),
      const Radius.circular(80),
    );

    final roadPaint = Paint()..color = const Color(0xff374151);
    canvas.drawRRect(roadRect, roadPaint);

    final shoulderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0xfffef3c7).withValues(alpha: 0.9);
    canvas.drawRRect(roadRect, shoulderPaint);

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    for (double y = -40 + dashOffset; y < size.height + 40; y += 42) {
      canvas.drawLine(
        Offset((size.width / 2) + roadCenterX, y),
        Offset((size.width / 2) + roadCenterX, y + 18),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RallyTrackPainter oldDelegate) {
    return oldDelegate.roadCenterX != roadCenterX ||
        oldDelegate.dashOffset != dashOffset;
  }
}

class _HazardChip extends StatelessWidget {
  const _HazardChip({required this.type});

  final _RallyHazardType type;

  @override
  Widget build(BuildContext context) {
    final isBoost = type == _RallyHazardType.boost;
    return Container(
      width: _DesertRallyScreenState._hazardSize,
      height: _DesertRallyScreenState._hazardSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isBoost ? const Color(0xfffacc15) : const Color(0xff92400e),
        border: Border.all(
          color: isBoost ? const Color(0xfffef08a) : const Color(0xfffcd34d),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isBoost ? const Color(0xfffacc15) : Colors.black).withValues(
              alpha: 0.28,
            ),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        isBoost ? Icons.flash_on_rounded : Icons.terrain_rounded,
        color: isBoost ? const Color(0xff78350f) : const Color(0xfffef3c7),
        size: 18,
      ),
    );
  }
}

class _PlayerCar extends StatelessWidget {
  const _PlayerCar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _DesertRallyScreenState._playerWidth,
      height: _DesertRallyScreenState._playerHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffef4444), Color(0xff991b1b)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffef4444).withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xfffca5a5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _Wheel(),
                _Wheel(),
                _Wheel(),
                _Wheel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xff111827),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

enum _RallyHazardType { rock, boost }

class _RallyHazard {
  const _RallyHazard({
    required this.x,
    required this.y,
    required this.type,
  });

  final double x;
  final double y;
  final _RallyHazardType type;

  _RallyHazard copyWith({
    double? x,
    double? y,
    _RallyHazardType? type,
  }) {
    return _RallyHazard(
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
    );
  }
}
