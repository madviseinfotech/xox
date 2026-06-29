import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class TurboOvertakeScreen extends StatefulWidget {
  const TurboOvertakeScreen({super.key});

  @override
  State<TurboOvertakeScreen> createState() => _TurboOvertakeScreenState();
}

class _TurboOvertakeScreenState extends State<TurboOvertakeScreen> {
  static const int _laneCount = 3;
  static const double _trackH = 360.0;
  static const double _playerCarH = 64.0;
  static const double _playerCarW = 38.0;
  static const double _trafficCarH = 60.0;
  static const double _trafficCarW = 36.0;
  static const Duration _tick = Duration(milliseconds: 35);

  final math.Random _rng = math.Random();
  Timer? _timer;

  int _playerLane = 1;
  double _roadScroll = 0;
  double _dashScroll = 0;
  double _speed = 4.5;
  double _nitro = 0;
  int _distance = 0;
  int _overtakes = 0;
  int _bestDistance = 0;
  bool _nitroActive = false;
  bool _running = false;
  bool _finished = false;
  String _message = 'Dodge traffic, overtake cars, and use Nitro for a speed burst.';

  final List<_TrafficCar> _traffic = [];

  static const List<Color> _trafficColors = [
    Color(0xff38bdf8),
    Color(0xfffacc15),
    Color(0xff34d399),
    Color(0xffa855f7),
    Color(0xfffb7185),
    Color(0xfff97316),
  ];

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() => _bestDistance = snapshot.turboOvertakeBestDistance);
  }

  void _startRace() {
    _timer?.cancel();
    _traffic.clear();
    for (int i = 0; i < 4; i++) {
      _traffic.add(_spawnCar(startY: -80.0 - i * 120));
    }
    setState(() {
      _playerLane = 1;
      _roadScroll = 0;
      _dashScroll = 0;
      _speed = 4.5;
      _nitro = 0;
      _distance = 0;
      _overtakes = 0;
      _nitroActive = false;
      _running = true;
      _finished = false;
      _message = 'Go! Dodge traffic and hit Nitro for a speed burst.';
    });
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  _TrafficCar _spawnCar({double? startY}) {
    return _TrafficCar(
      lane: _rng.nextInt(_laneCount),
      y: startY ?? (-_trafficCarH - _rng.nextDouble() * 100),
      speed: 1.2 + _rng.nextDouble() * 1.6,
      color: _trafficColors[_rng.nextInt(_trafficColors.length)],
    );
  }

  Future<void> _onTick() async {
    if (!_running || !mounted) return;

    final currentSpeed = _nitroActive ? _speed * 1.55 : _speed;
    final playerY = _trackH - _playerCarH - 14;

    // Update traffic
    final updated = <_TrafficCar>[];
    var crashed = false;
    var overtakesThisTick = 0;

    for (final car in _traffic) {
      final relSpeed = currentSpeed - car.speed;
      final nextY = car.y + relSpeed;

      // Collision
      if (car.lane == _playerLane) {
        final carBottom = nextY + _trafficCarH;
        final carTop = nextY;
        final playerBottom = playerY + _playerCarH;
        final playerTop = playerY;
        if (carBottom > playerTop + 6 && carTop < playerBottom - 6) {
          crashed = true;
          break;
        }
      }

      // Overtake count
      if (car.lane == _playerLane &&
          car.y + _trafficCarH <= playerY + 6 &&
          nextY + _trafficCarH > playerY + 6) {
        overtakesThisTick++;
      }

      if (nextY > _trackH + 80) {
        updated.add(_spawnCar());
      } else {
        updated.add(car.copyWith(y: nextY));
      }
    }

    if (crashed) {
      await _endRace();
      return;
    }

    // Ensure enough traffic
    while (updated.length < 5) {
      updated.add(_spawnCar(startY: -_trafficCarH - _rng.nextDouble() * 80));
    }

    // Nitro drain
    double nextNitro = _nitro;
    if (_nitroActive) {
      nextNitro -= 3.5;
      if (nextNitro <= 0) {
        nextNitro = 0;
        _nitroActive = false;
      }
    } else {
      nextNitro = math.min(100, nextNitro + 0.4);
    }

    // Speed increase over time
    final nextSpeed = math.min(9.0, _speed + 0.003);
    final nextDist = _distance + (currentSpeed * 3.5).round();
    final nextOvertakes = _overtakes + overtakesThisTick;

    setState(() {
      _traffic
        ..clear()
        ..addAll(updated);
      _roadScroll = (_roadScroll + currentSpeed * 5) % 60;
      _dashScroll = (_dashScroll + currentSpeed * 5) % 48;
      _speed = nextSpeed;
      _nitro = nextNitro;
      _distance = nextDist;
      _overtakes = nextOvertakes;
      if (overtakesThisTick > 0) {
        _message = 'Overtake! $_overtakes passes. Keep pushing.';
      } else if (_nitroActive) {
        _message = 'NITRO ACTIVE! Burning through traffic!';
      } else if (nextNitro >= 100) {
        _message = 'Nitro ready! Tap NITRO for a speed burst.';
      } else {
        _message = '${nextDist}m • $_overtakes overtakes • ${(_speed * 28).round()} km/h';
      }
    });
  }

  Future<void> _endRace() async {
    _timer?.cancel();
    if (_distance > _bestDistance) {
      await GameStatsStore.instance.recordTurboOvertakeBestDistance(_distance);
    }
    GameInterstitialService.instance.registerRoundCompletion();
    unawaited(GameInterstitialService.instance.maybeShow());
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _nitroActive = false;
      if (_distance > _bestDistance) _bestDistance = _distance;
      _message = 'Crash! ${_distance}m • $_overtakes overtakes.';
    });
  }

  void _steer(int delta) {
    if (!_running) return;
    setState(() {
      _playerLane = (_playerLane + delta).clamp(0, _laneCount - 1);
    });
  }

  void _activateNitro() {
    if (!_running || _nitro < 100 || _nitroActive) return;
    setState(() {
      _nitroActive = true;
      _message = 'NITRO ACTIVE!';
    });
  }

  Color _nitroColor() {
    if (_nitro >= 100) return const Color(0xff22c55e);
    if (_nitro > 50) return const Color(0xfff59e0b);
    return const Color(0xff38bdf8);
  }

  @override
  Widget build(BuildContext context) {
    const accent = [Color(0xfff97316), Color(0xffef4444)];
    return GameScaffold(
      title: 'Turbo Overtake',
      subtitle: 'Dodge traffic, rack up overtakes, and blast nitro to survive.',
      accent: accent,
      scrollable: false,
      compactHeader: true,
      minimalHeader: true,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CompactMetricCard(
                  label: 'Distance',
                  value: '${_distance}m',
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CompactMetricCard(
                  label: 'Overtakes',
                  value: '$_overtakes',
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CompactMetricCard(
                  label: 'Best',
                  value: _bestDistance == 0 ? '--' : '${_bestDistance}m',
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InlineStatusStrip(
            message: _message,
            accent: _nitroActive
                ? const Color(0xff22c55e)
                : _finished
                ? const Color(0xffef4444)
                : const Color(0xfff97316),
            compact: true,
            highlight: _finished || _nitroActive,
          ),
          const SizedBox(height: 6),
          // Track
          Expanded(
            child: GamePanel(
              padding: const EdgeInsets.all(6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final laneW = constraints.maxWidth / _laneCount;
                  final playerY = constraints.maxHeight - _playerCarH - 10;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Road
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _TurboRoadPainter(
                              laneCount: _laneCount,
                              roadScroll: _roadScroll,
                              dashScroll: _dashScroll,
                              speed: _speed,
                              nitroActive: _nitroActive,
                            ),
                          ),
                        ),
                        // Traffic cars
                        for (final car in _traffic)
                          if (car.y > -_trafficCarH &&
                              car.y < constraints.maxHeight + _trafficCarH)
                            Positioned(
                              left: car.lane * laneW +
                                  (laneW - _trafficCarW) / 2,
                              top: car.y.clamp(
                                -_trafficCarH,
                                constraints.maxHeight,
                              ),
                              child: _CarSprite(
                                color: car.color,
                                width: _trafficCarW,
                                height: _trafficCarH,
                              ),
                            ),
                        // Player car
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          left: _playerLane * laneW +
                              (laneW - _playerCarW) / 2,
                          top: playerY,
                          child: _CarSprite(
                            color: const Color(0xffef4444),
                            width: _playerCarW,
                            height: _playerCarH,
                            glow: _nitroActive
                                ? const Color(0xff22c55e)
                                : const Color(0xfffb7185),
                            isPlayer: true,
                          ),
                        ),
                        // Speed overlay
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${(_speed * 28).round()} km/h',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        // Nitro flame effect
                        if (_nitroActive)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            left: _playerLane * laneW +
                                (laneW - _playerCarW) / 2 +
                                8,
                            top: playerY + _playerCarH,
                            child: Container(
                              width: _playerCarW - 16,
                              height: 18,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xfff97316),
                                    Color(0x0022c55e),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Start overlay
                        if (!_running)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                              child: Center(
                                child: Text(
                                  _finished
                                      ? '${_distance}m • $_overtakes overtakes\nTap Start to race again'
                                      : 'Tap Start to race',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Nitro bar
          Row(
            children: [
              const SizedBox(
                width: 48,
                child: Text(
                  'Nitro',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: (_nitro / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(_nitroColor()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_nitro.round()}%',
                style: TextStyle(
                  color: _nitroColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Controls
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _steer(-1) : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor:
                        const Color(0xff38bdf8).withValues(alpha: 0.18),
                  ),
                  child: const Text(
                    '◀ LEFT',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? _activateNitro : _startRace,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _running
                        ? (_nitro >= 100
                              ? const Color(0xff22c55e)
                              : const Color(0xff22c55e).withValues(alpha: 0.25))
                        : null,
                  ),
                  child: Text(
                    _running ? '⚡ NITRO' : (_finished ? 'Restart' : 'Start'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _steer(1) : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor:
                        const Color(0xff38bdf8).withValues(alpha: 0.18),
                  ),
                  child: const Text(
                    'RIGHT ▶',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrafficCar {
  const _TrafficCar({
    required this.lane,
    required this.y,
    required this.speed,
    required this.color,
  });

  final int lane;
  final double y;
  final double speed;
  final Color color;

  _TrafficCar copyWith({int? lane, double? y, double? speed, Color? color}) {
    return _TrafficCar(
      lane: lane ?? this.lane,
      y: y ?? this.y,
      speed: speed ?? this.speed,
      color: color ?? this.color,
    );
  }
}

class _CarSprite extends StatelessWidget {
  const _CarSprite({
    required this.color,
    required this.width,
    required this.height,
    this.glow = const Color(0x00000000),
    this.isPlayer = false,
  });

  final Color color;
  final double width;
  final double height;
  final Color glow;
  final bool isPlayer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Body
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.25), color],
                ),
                boxShadow: glow.a == 0.0
                    ? const []
                    : [
                        BoxShadow(
                          color: glow.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          // Windshield
          Positioned(
            left: 7,
            right: 7,
            top: 7,
            height: 11,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xffdbeafe).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          // Rear
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            height: 9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Left wheel
          Positioned(
            left: 1,
            top: 9,
            bottom: 9,
            width: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xff020617),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          // Right wheel
          Positioned(
            right: 1,
            top: 9,
            bottom: 9,
            width: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xff020617),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          // Player indicator stripe
          if (isPlayer)
            Positioned(
              left: 10,
              right: 10,
              top: height * 0.42,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TurboRoadPainter extends CustomPainter {
  const _TurboRoadPainter({
    required this.laneCount,
    required this.roadScroll,
    required this.dashScroll,
    required this.speed,
    required this.nitroActive,
  });

  final int laneCount;
  final double roadScroll;
  final double dashScroll;
  final double speed;
  final bool nitroActive;

  @override
  void paint(Canvas canvas, Size size) {
    // Asphalt
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xff151e2b),
    );

    // Subtle road texture
    final texPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (double y = roadScroll % 14 - 14; y < size.height + 14; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), texPaint);
    }

    // Kerbs
    const kerbW = 14.0;
    const kerbH = 22.0;
    final kerbPaint = Paint();
    for (double y = roadScroll % (kerbH * 2) - kerbH * 2;
        y < size.height + kerbH * 2;
        y += kerbH * 2) {
      kerbPaint.color = const Color(0xffef4444);
      canvas.drawRect(Rect.fromLTWH(0, y, kerbW, kerbH), kerbPaint);
      canvas.drawRect(
        Rect.fromLTWH(size.width - kerbW, y, kerbW, kerbH),
        kerbPaint,
      );
      kerbPaint.color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, y + kerbH, kerbW, kerbH),
        kerbPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(size.width - kerbW, y + kerbH, kerbW, kerbH),
        kerbPaint,
      );
    }

    // Lane dashes
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2.5;
    final laneW = size.width / laneCount;
    for (int i = 1; i < laneCount; i++) {
      final x = laneW * i;
      for (double y = dashScroll % 48 - 48; y < size.height + 48; y += 48) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 22), dashPaint);
      }
    }

    // Speed blur
    if (speed > 5.5 || nitroActive) {
      final alpha = nitroActive ? 0.06 : (speed - 5.5) * 0.012;
      final blurPaint = Paint()
        ..color = (nitroActive ? const Color(0xff22c55e) : Colors.white)
            .withValues(alpha: alpha)
        ..strokeWidth = 1.5;
      for (int i = 0; i < 8; i++) {
        final x = kerbW + (size.width - kerbW * 2) * (i / 7.0);
        canvas.drawLine(
          Offset(x, size.height * 0.2),
          Offset(x, size.height * 0.9),
          blurPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TurboRoadPainter old) =>
      old.roadScroll != roadScroll ||
      old.dashScroll != dashScroll ||
      old.speed != speed ||
      old.nitroActive != nitroActive;
}
