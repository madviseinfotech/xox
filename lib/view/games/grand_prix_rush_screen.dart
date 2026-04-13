import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class GrandPrixRushScreen extends StatefulWidget {
  const GrandPrixRushScreen({super.key});

  @override
  State<GrandPrixRushScreen> createState() => _GrandPrixRushScreenState();
}

class _GrandPrixRushScreenState extends State<GrandPrixRushScreen> {
  static const int _laneCount = 4;
  static const int _totalLaps = 5;
  static const double _trackH = 380.0;
  static const double _carW = 36.0;
  static const double _carH = 64.0;
  static const double _lapDistance = 1200.0;
  static const Duration _tick = Duration(milliseconds: 40);

  final math.Random _rng = math.Random();
  Timer? _timer;

  // Player state
  int _playerLane = 1;
  double _playerSpeed = 0;
  double _playerDist = 0;
  double _tireWear = 0;
  int _lap = 1;
  bool _throttle = false;
  bool _brake = false;

  // Rivals
  final List<_Rival> _rivals = [];

  // Road scroll
  double _roadScroll = 0;
  double _dashScroll = 0;

  // Game state
  int _bestLaps = 0;
  int _position = 4;
  bool _running = false;
  bool _finished = false;
  String _message =
      'Hold Throttle to accelerate. Steer left/right to overtake rivals.';

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
    setState(() => _bestLaps = snapshot.grandPrixRushBestLaps);
  }

  void _startRace() {
    _timer?.cancel();
    _rivals.clear();
    // Spawn 3 rivals in different lanes ahead
    for (int i = 0; i < 3; i++) {
      _rivals.add(
        _Rival(
          lane: (i + 1) % _laneCount,
          y: -80.0 - (i * 110),
          speed: 3.8 + _rng.nextDouble() * 1.4,
          color: _rivalColors[i],
          dist: (i + 1) * 180.0,
          lap: 1,
        ),
      );
    }
    setState(() {
      _playerLane = 1;
      _playerSpeed = 0;
      _playerDist = 0;
      _tireWear = 0;
      _lap = 1;
      _throttle = false;
      _brake = false;
      _roadScroll = 0;
      _dashScroll = 0;
      _position = 4;
      _running = true;
      _finished = false;
      _message = 'Green light! Hold Throttle and find your racing line.';
    });
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  Future<void> _onTick() async {
    if (!_running || !mounted) return;

    // Player speed
    double spd = _playerSpeed;
    final tireGrip = 1.0 - (_tireWear / 160.0);
    if (_throttle) {
      spd += 0.55 * tireGrip;
    } else {
      spd -= 0.35;
    }
    if (_brake) spd -= 0.9;
    spd = spd.clamp(0.0, 9.5 * tireGrip);

    // Tire wear increases with speed
    final nextWear = (_tireWear + spd * 0.012).clamp(0.0, 100.0);

    // Distance
    final nextDist = _playerDist + spd * 5.2;

    // Lap counting
    int nextLap = _lap;
    if (nextDist >= _lapDistance * _lap) {
      nextLap = _lap + 1;
    }

    // Road scroll
    final nextRoadScroll = (_roadScroll + spd * 5.2) % 60.0;
    final nextDashScroll = (_dashScroll + spd * 5.2) % 48.0;

    // Update rivals
    final updatedRivals = <_Rival>[];
    for (final r in _rivals) {
      // Rival speed varies slightly
      final rSpd = r.speed + math.sin(nextDist * 0.001 + r.dist) * 0.3;
      final rNextDist = r.dist + rSpd * 5.2;
      int rNextLap = r.lap;
      if (rNextDist >= _lapDistance * r.lap) rNextLap = r.lap + 1;

      // Rival Y position on screen (relative to player)
      final distDiff = rNextDist - nextDist;
      final rivalY =
          (_trackH - _carH - 20) - (distDiff * 0.18).clamp(-300.0, 200.0);

      updatedRivals.add(
        r.copyWith(
          dist: rNextDist,
          lap: rNextLap,
          y: rivalY,
          speed: rSpd.clamp(2.5, 6.5),
        ),
      );
    }

    // Collision check
    final playerY = _trackH - _carH - 20;
    for (final r in updatedRivals) {
      final sameOrAdjacentLane = (r.lane - _playerLane).abs() == 0;
      final yOverlap = r.y < playerY + _carH - 8 && r.y + _carH > playerY + 8;
      if (sameOrAdjacentLane && yOverlap && r.y > 0 && r.y < _trackH) {
        await _finishRace(
          won: false,
          reason: 'Collision with rival. Race over.',
        );
        return;
      }
    }

    // Calculate position
    int pos = 1;
    for (final r in updatedRivals) {
      if (r.lap > nextLap || (r.lap == nextLap && r.dist > nextDist)) {
        pos++;
      }
    }

    // Check finish
    if (nextLap > _totalLaps) {
      _playerDist = nextDist;
      _lap = _totalLaps;
      await _finishRace(
        won: pos == 1,
        reason: pos == 1
            ? 'Chequered flag! You won the Grand Prix!'
            : 'Race complete. You finished P$pos.',
      );
      return;
    }

    // Check if all rivals finished before player
    final allRivalsFinished = updatedRivals.every((r) => r.lap > _totalLaps);
    if (allRivalsFinished && nextLap <= _totalLaps) {
      await _finishRace(won: false, reason: 'Rivals finished first. P$pos.');
      return;
    }

    String msg = _message;
    if (_tireWear > 75) {
      msg = 'Tires are worn. Lap $_lap/$_totalLaps. Manage your speed.';
    } else if (spd > 7.5) {
      msg = 'Full speed! Lap $_lap/$_totalLaps. P$pos.';
    } else if (!_throttle) {
      msg = 'Hold Throttle to push harder. Lap $_lap/$_totalLaps.';
    }

    setState(() {
      _playerSpeed = spd;
      _playerDist = nextDist;
      _tireWear = nextWear;
      _lap = nextLap.clamp(1, _totalLaps);
      _roadScroll = nextRoadScroll;
      _dashScroll = nextDashScroll;
      _position = pos;
      _rivals
        ..clear()
        ..addAll(updatedRivals);
      _message = msg;
    });
  }

  Future<void> _finishRace({required bool won, required String reason}) async {
    _timer?.cancel();
    _timer = null;
    final lapsCompleted = math.min(_lap, _totalLaps);
    if (lapsCompleted > _bestLaps) {
      await GameStatsStore.instance.recordGrandPrixRushBestLaps(lapsCompleted);
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _throttle = false;
      _brake = false;
      if (lapsCompleted > _bestLaps) _bestLaps = lapsCompleted;
      _message = reason;
    });
    GameInterstitialService.instance.registerRoundCompletion();
    unawaited(GameInterstitialService.instance.maybeShow());
  }

  void _steer(int delta) {
    if (!_running) return;
    setState(() {
      _playerLane = (_playerLane + delta).clamp(0, _laneCount - 1);
    });
  }

  static const List<Color> _rivalColors = [
    Color(0xff38bdf8),
    Color(0xfffacc15),
    Color(0xff34d399),
  ];

  Color _tireColor() {
    if (_tireWear < 40) return const Color(0xff22c55e);
    if (_tireWear < 70) return const Color(0xfff59e0b);
    return const Color(0xffef4444);
  }

  @override
  Widget build(BuildContext context) {
    const accent = [Color(0xffef4444), Color(0xfff97316)];
    return GameScaffold(
      title: 'Grand Prix Rush',
      subtitle: 'Race $_totalLaps laps, manage tire wear, and beat 3 rivals.',
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
                  label: 'Lap',
                  value: '$_lap / $_totalLaps',
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CompactMetricCard(
                  label: 'Position',
                  value: 'P$_position',
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CompactMetricCard(
                  label: 'Best',
                  value: _bestLaps == 0 ? '--' : '$_bestLaps laps',
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InlineStatusStrip(
            message: _message,
            accent: _finished
                ? (_message.contains('won')
                      ? const Color(0xff22c55e)
                      : const Color(0xffef4444))
                : const Color(0xfff97316),
            compact: true,
            highlight: _finished,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GamePanel(
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final laneW = constraints.maxWidth / _laneCount;
                  final playerY = constraints.maxHeight - _carH - 12;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        // Road background
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GrandPrixRoadPainter(
                              laneCount: _laneCount,
                              roadScroll: _roadScroll,
                              dashScroll: _dashScroll,
                              speed: _playerSpeed,
                            ),
                          ),
                        ),
                        // Rival cars
                        for (final r in _rivals)
                          if (r.y > -_carH &&
                              r.y < constraints.maxHeight + _carH)
                            AnimatedPositioned(
                              duration: _tick,
                              curve: Curves.linear,
                              left: r.lane * laneW + (laneW - _carW) / 2,
                              top: r.y.clamp(-_carH, constraints.maxHeight),
                              child: _RaceCar(color: r.color, scale: 0.88),
                            ),
                        // Player car
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeOut,
                          left: _playerLane * laneW + (laneW - _carW) / 2,
                          top: playerY,
                          child: _RaceCar(
                            color: const Color(0xffef4444),
                            glow: _throttle
                                ? const Color(0xfff97316)
                                : const Color(0xfffb7185),
                          ),
                        ),
                        // Lap counter overlay
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'LAP $_lap/$_totalLaps',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        // Speed overlay
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(_playerSpeed * 28).round()} km/h',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        // Start overlay
                        if (!_running)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                              child: Center(
                                child: Text(
                                  _finished
                                      ? _message
                                      : 'Tap Start Race to begin',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
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
          // Tire wear bar
          Row(
            children: [
              const SizedBox(
                width: 60,
                child: Text(
                  'Tires',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: (1 - _tireWear / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(_tireColor()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(100 - _tireWear).round()}%',
                style: TextStyle(
                  color: _tireColor(),
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
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _throttle = true),
                  onTapUp: (_) => setState(() => _throttle = false),
                  onTapCancel: () => setState(() => _throttle = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _throttle
                          ? const Color(0xff22c55e).withValues(alpha: 0.3)
                          : const Color(0xff22c55e).withValues(alpha: 0.12),
                      border: Border.all(
                        color: const Color(
                          0xff22c55e,
                        ).withValues(alpha: _throttle ? 0.8 : 0.3),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '⚡ THROTTLE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTapDown: (_) => setState(() => _brake = true),
                onTapUp: (_) => setState(() => _brake = false),
                onTapCancel: () => setState(() => _brake = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  height: 52,
                  width: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _brake
                        ? const Color(0xffef4444).withValues(alpha: 0.3)
                        : const Color(0xffef4444).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(
                        0xffef4444,
                      ).withValues(alpha: _brake ? 0.8 : 0.3),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '🛑 BRAKE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _steer(-1) : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(
                      0xff38bdf8,
                    ).withValues(alpha: 0.18),
                  ),
                  child: const Text(
                    '◀ LEFT',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? null : _startRace,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _finished ? 'Race Again' : 'Start Race',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _steer(1) : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(
                      0xff38bdf8,
                    ).withValues(alpha: 0.18),
                  ),
                  child: const Text(
                    'RIGHT ▶',
                    style: TextStyle(fontWeight: FontWeight.w800),
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

class _Rival {
  const _Rival({
    required this.lane,
    required this.y,
    required this.speed,
    required this.color,
    required this.dist,
    required this.lap,
  });

  final int lane;
  final double y;
  final double speed;
  final Color color;
  final double dist;
  final int lap;

  _Rival copyWith({
    int? lane,
    double? y,
    double? speed,
    Color? color,
    double? dist,
    int? lap,
  }) {
    return _Rival(
      lane: lane ?? this.lane,
      y: y ?? this.y,
      speed: speed ?? this.speed,
      color: color ?? this.color,
      dist: dist ?? this.dist,
      lap: lap ?? this.lap,
    );
  }
}

class _RaceCar extends StatelessWidget {
  const _RaceCar({
    required this.color,
    this.glow = const Color(0x00000000),
    this.scale = 1.0,
  });

  final Color color;
  final Color glow;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: 36,
        height: 64,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.22), color],
                  ),
                  boxShadow: glow.a == 0.0
                      ? const []
                      : [
                          BoxShadow(
                            color: glow.withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              ),
            ),
            // Windshield
            Positioned(
              left: 8,
              right: 8,
              top: 8,
              height: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xffdbeafe).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            // Rear window
            Positioned(
              left: 9,
              right: 9,
              bottom: 10,
              height: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            // Left wheel
            Positioned(
              left: 1,
              top: 10,
              bottom: 10,
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
              top: 10,
              bottom: 10,
              width: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xff020617),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrandPrixRoadPainter extends CustomPainter {
  const _GrandPrixRoadPainter({
    required this.laneCount,
    required this.roadScroll,
    required this.dashScroll,
    required this.speed,
  });

  final int laneCount;
  final double roadScroll;
  final double dashScroll;
  final double speed;

  @override
  void paint(Canvas canvas, Size size) {
    // Asphalt
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xff1a2332),
    );

    // Road surface texture lines
    final texturePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double y = -60 + roadScroll % 60; y < size.height + 60; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), texturePaint);
    }

    // Red/white kerbs on edges
    final kerbPaint = Paint();
    const kerbW = 12.0;
    const kerbH = 24.0;
    for (
      double y = -kerbH + roadScroll % (kerbH * 2);
      y < size.height + kerbH;
      y += kerbH * 2
    ) {
      kerbPaint.color = const Color(0xffef4444);
      canvas.drawRect(Rect.fromLTWH(0, y, kerbW, kerbH), kerbPaint);
      canvas.drawRect(
        Rect.fromLTWH(size.width - kerbW, y, kerbW, kerbH),
        kerbPaint,
      );
      kerbPaint.color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, y + kerbH, kerbW, kerbH), kerbPaint);
      canvas.drawRect(
        Rect.fromLTWH(size.width - kerbW, y + kerbH, kerbW, kerbH),
        kerbPaint,
      );
    }

    // Lane dividers
    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 2.5;
    final laneW = size.width / laneCount;
    for (int lane = 1; lane < laneCount; lane++) {
      final x = laneW * lane;
      for (double y = -48 + dashScroll; y < size.height + 48; y += 48) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 22), lanePaint);
      }
    }

    // Speed blur lines at high speed
    if (speed > 6) {
      final blurPaint = Paint()
        ..color = Colors.white.withValues(alpha: (speed - 6) * 0.015)
        ..strokeWidth = 1.5;
      for (int i = 0; i < 6; i++) {
        final x = kerbW + (size.width - kerbW * 2) * (i / 5.0);
        canvas.drawLine(
          Offset(x, size.height * 0.3),
          Offset(x, size.height * 0.85),
          blurPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GrandPrixRoadPainter old) =>
      old.roadScroll != roadScroll ||
      old.dashScroll != dashScroll ||
      old.speed != speed;
}
