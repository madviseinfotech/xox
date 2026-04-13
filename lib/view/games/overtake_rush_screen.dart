import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class OvertakeRushScreen extends StatefulWidget {
  const OvertakeRushScreen({super.key});

  @override
  State<OvertakeRushScreen> createState() => _OvertakeRushScreenState();
}

class _OvertakeRushScreenState extends State<OvertakeRushScreen> {
  static const int _laneCount = 4;
  static const int _targetOvertakes = 18;
  static const double _trackHeight = 360;
  static const double _playerCarHeight = 68;
  static const double _rivalCarHeight = 60;
  static const Duration _tick = Duration(milliseconds: 45);

  final math.Random _random = math.Random();
  final List<_RivalCar> _rivals = [];

  Timer? _timer;
  int _playerLane = 1;
  int _overtakes = 0;
  int _bestOvertakes = 0;
  int _combo = 0;
  double _distance = 0;
  double _speed = 5.4;
  double _heat = 0;
  double _roadOffset = 0;
  bool _running = false;
  bool _finished = false;
  bool _boostHeld = false;
  String _message =
      'Pass slower cars, hold boost in short bursts, and avoid overheating.';

  @override
  void initState() {
    super.initState();
    _loadBest();
    _resetRun();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestOvertakes = snapshot.overtakeRushBestScore;
    });
  }

  void _resetRun() {
    _timer?.cancel();
    _rivals
      ..clear()
      ..addAll(_seedRivals());
    setState(() {
      _playerLane = 1;
      _overtakes = 0;
      _combo = 0;
      _distance = 0;
      _speed = 5.4;
      _heat = 0;
      _roadOffset = 0;
      _running = false;
      _finished = false;
      _boostHeld = false;
      _message =
          'Pass slower cars, hold boost in short bursts, and avoid overheating.';
    });
  }

  List<_RivalCar> _seedRivals() {
    return List<_RivalCar>.generate(4, (index) {
      return _RivalCar(
        lane: index % _laneCount,
        y: -40.0 - (index * 110),
        pace: 2.0 + _random.nextDouble() * 1.8,
        color: _rivalColor(index),
      );
    });
  }

  Color _rivalColor(int seed) {
    const palette = <Color>[
      Color(0xff38bdf8),
      Color(0xfff97316),
      Color(0xfffacc15),
      Color(0xff34d399),
      Color(0xfffb7185),
    ];
    return palette[seed % palette.length];
  }

  void _startRun() {
    _resetRun();
    setState(() {
      _running = true;
      _message =
          'Race on. Use quick boosts to clear traffic without cooking the engine.';
    });
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  Future<void> _onTick() async {
    if (!_running || !mounted) return;

    final playerY = _trackHeight - _playerCarHeight - 16;
    var nextHeat = _heat;
    var nextSpeed = 5.1 + (_overtakes * 0.08);

    if (_boostHeld && nextHeat < 100) {
      nextSpeed += 3.2;
      nextHeat += 4.8;
    } else {
      nextHeat -= 2.6;
    }
    nextHeat = nextHeat.clamp(0.0, 100.0);

    if (nextHeat >= 100) {
      await _finishRun(
        playerWon: false,
        reason: 'Engine overheated. Ease off boost between passes.',
      );
      return;
    }

    final updatedRivals = <_RivalCar>[];
    var overtakesThisTick = 0;
    var crashed = false;

    for (final rival in _rivals) {
      final relativeSpeed = nextSpeed - rival.pace;
      final nextY = rival.y + relativeSpeed;
      final overlapsPlayer =
          rival.lane == _playerLane &&
          nextY < playerY + _playerCarHeight - 10 &&
          nextY + _rivalCarHeight > playerY + 10;

      if (overlapsPlayer) {
        crashed = true;
        break;
      }

      final passedPlayer =
          rival.y <= playerY && nextY > playerY + _playerCarHeight;
      if (passedPlayer) {
        overtakesThisTick += 1;
      }

      if (nextY > _trackHeight + 100) {
        updatedRivals.add(
          _spawnRival(topY: -_rivalCarHeight - _random.nextInt(80)),
        );
      } else {
        updatedRivals.add(rival.copyWith(y: nextY));
      }
    }

    if (crashed) {
      await _finishRun(
        playerWon: false,
        reason:
            'You clipped traffic. Change lanes earlier before the closing gap.',
      );
      return;
    }

    while (updatedRivals.length < 5) {
      final topY = updatedRivals.isEmpty
          ? -_rivalCarHeight
          : -_random.nextInt(160).toDouble() - _rivalCarHeight;
      updatedRivals.add(_spawnRival(topY: topY));
    }

    final nextOvertakes = _overtakes + overtakesThisTick;
    if (nextOvertakes >= _targetOvertakes) {
      _overtakes = nextOvertakes;
      _distance += nextSpeed * 5.6;
      await _finishRun(
        playerWon: true,
        reason: 'Finish line reached. You carved through the field.',
      );
      return;
    }

    setState(() {
      _rivals
        ..clear()
        ..addAll(updatedRivals);
      _overtakes = nextOvertakes;
      _combo = overtakesThisTick > 0 ? _combo + overtakesThisTick : 0;
      _distance += nextSpeed * 5.6;
      _speed = nextSpeed;
      _heat = nextHeat;
      _roadOffset = (_roadOffset + nextSpeed * 1.6) % 54;
      _message = overtakesThisTick > 0
          ? _combo >= 4
                ? 'Hot streak. Traffic is breaking your way.'
                : 'Clean pass. Set up the next overtake.'
          : nextHeat > 72
          ? 'Heat is high. Release boost and cool the engine.'
          : _boostHeld
          ? 'Boosting hard. Watch for gaps in the next lane.'
          : 'Build speed, then burst past the next car.';
    });
  }

  _RivalCar _spawnRival({required double topY}) {
    return _RivalCar(
      lane: _random.nextInt(_laneCount),
      y: topY,
      pace: 1.8 + _random.nextDouble() * 2.6 + math.min(1.8, _overtakes * 0.04),
      color: _rivalColor(_random.nextInt(20)),
    );
  }

  Future<void> _finishRun({
    required bool playerWon,
    required String reason,
  }) async {
    _timer?.cancel();
    final isBest = _overtakes > _bestOvertakes;
    if (isBest) {
      await GameStatsStore.instance.recordOvertakeRushBestScore(_overtakes);
    }
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _boostHeld = false;
      if (isBest) {
        _bestOvertakes = _overtakes;
      }
      _message = playerWon
          ? '$reason ${_overtakes.toString()} overtakes in ${(_distance / 10).floor()} m.'
          : isBest
          ? '$reason New best: $_overtakes overtakes.'
          : reason;
    });
  }

  void _move(int delta) {
    if (!_running) return;
    setState(() {
      _playerLane = (_playerLane + delta).clamp(0, _laneCount - 1);
      _message = delta < 0
          ? 'Diving left for space.'
          : 'Moving right into the opening.';
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = [Color(0xffef4444), Color(0xfff59e0b)];
    return GameScaffold(
      title: 'Overtake Rush',
      subtitle:
          'Slice through traffic, time boost bursts, and chase the finish.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Passes',
            leftValue: '$_overtakes/$_targetOvertakes',
            rightLabel: 'Best',
            rightValue: '$_bestOvertakes',
            footer:
                'Speed ${_speed.toStringAsFixed(1)} • Heat ${_heat.round()}% • Combo $_combo',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xfff59e0b)),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final laneWidth = constraints.maxWidth / _laneCount;
                final playerY = _trackHeight - _playerCarHeight - 16;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: _trackHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xff111827), Color(0xff020617)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _RoadPainter(
                                laneCount: _laneCount,
                                dashOffset: _roadOffset,
                                heat: _heat,
                              ),
                            ),
                          ),
                          for (final rival in _rivals)
                            Positioned(
                              left:
                                  rival.lane * laneWidth + (laneWidth - 34) / 2,
                              top: rival.y,
                              child: _RaceCar(color: rival.color, scale: 0.92),
                            ),
                          Positioned(
                            left:
                                _playerLane * laneWidth + (laneWidth - 38) / 2,
                            top: playerY,
                            child: _RaceCar(
                              color: const Color(0xfff43f5e),
                              glow: _boostHeld
                                  ? const Color(0xfff59e0b)
                                  : const Color(0xfffb7185),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: _heat / 100,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _heat > 72
                            ? const Color(0xffef4444)
                            : const Color(0xfff59e0b),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Engine heat',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xff94a3b8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ControlButton(
                            icon: Icons.keyboard_double_arrow_left_rounded,
                            label: 'Left',
                            onTapDown: () => _move(-1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ControlButton(
                            icon: Icons.flash_on_rounded,
                            label: _running ? 'Boost' : 'Start',
                            accent: const Color(0xfff59e0b),
                            active: _boostHeld,
                            onTap: _running ? null : _startRun,
                            onPressChanged: (pressed) {
                              if (!_running) return;
                              setState(() {
                                _boostHeld = pressed;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ControlButton(
                            icon: Icons.keyboard_double_arrow_right_rounded,
                            label: 'Right',
                            onTapDown: () => _move(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _running ? null : _startRun,
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
}

class _RivalCar {
  const _RivalCar({
    required this.lane,
    required this.y,
    required this.pace,
    required this.color,
  });

  final int lane;
  final double y;
  final double pace;
  final Color color;

  _RivalCar copyWith({int? lane, double? y, double? pace, Color? color}) {
    return _RivalCar(
      lane: lane ?? this.lane,
      y: y ?? this.y,
      pace: pace ?? this.pace,
      color: color ?? this.color,
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    this.accent = const Color(0xff38bdf8),
    this.active = false,
    this.onTap,
    this.onTapDown,
    this.onPressChanged,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final ValueChanged<bool>? onPressChanged;

  @override
  Widget build(BuildContext context) {
    final enabled =
        onTap != null || onTapDown != null || onPressChanged != null;
    return GestureDetector(
      onTap: onTap,
      onTapDown: (_) {
        onTapDown?.call();
        onPressChanged?.call(true);
      },
      onTapUp: (_) => onPressChanged?.call(false),
      onTapCancel: () => onPressChanged?.call(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: enabled
              ? accent.withValues(alpha: active ? 0.28 : 0.14)
              : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: enabled
                ? accent.withValues(alpha: active ? 0.75 : 0.32)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: enabled ? Colors.white : const Color(0xff64748b)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : const Color(0xff64748b),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RaceCar extends StatelessWidget {
  const _RaceCar({
    required this.color,
    this.glow = const Color(0x00000000),
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
        width: 38,
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: glow.a == 0.0
              ? const []
              : [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.42),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 4,
              right: 4,
              top: 4,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.22), color],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 11,
              right: 11,
              top: 10,
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xffdbeafe).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              left: 9,
              right: 9,
              bottom: 12,
              height: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xff0f172a).withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              left: 2,
              top: 10,
              bottom: 10,
              width: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xff020617),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Positioned(
              right: 2,
              top: 10,
              bottom: 10,
              width: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xff020617),
                  borderRadius: BorderRadius.circular(4),
                ),
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
    required this.laneCount,
    required this.dashOffset,
    required this.heat,
  });

  final int laneCount;
  final double dashOffset;
  final double heat;

  @override
  void paint(Canvas canvas, Size size) {
    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.26)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final shoulderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xffef4444).withValues(alpha: 0.18 + (heat / 600)),
          const Color(0xfff97316).withValues(alpha: 0.30 + (heat / 280)),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Rect.fromLTWH(0, 0, 10, size.height), shoulderPaint);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 10, 0, 10, size.height),
      shoulderPaint,
    );

    final laneWidth = size.width / laneCount;
    for (var lane = 1; lane < laneCount; lane++) {
      final x = laneWidth * lane;
      for (double y = -54 + dashOffset; y < size.height + 54; y += 54) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 26), lanePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) {
    return oldDelegate.dashOffset != dashOffset || oldDelegate.heat != heat;
  }
}
