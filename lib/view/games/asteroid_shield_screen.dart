import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class AsteroidShieldScreen extends StatefulWidget {
  const AsteroidShieldScreen({super.key});

  @override
  State<AsteroidShieldScreen> createState() => _AsteroidShieldScreenState();
}

class _AsteroidShieldScreenState extends State<AsteroidShieldScreen> {
  final Random _random = Random();
  final List<_Asteroid> _asteroids = <_Asteroid>[];
  Timer? _timer;

  static const int _maxLives = 3;
  static const List<Alignment> _laneAlignments = <Alignment>[
    Alignment.topCenter,
    Alignment.centerRight,
    Alignment.bottomCenter,
    Alignment.centerLeft,
  ];

  int _shieldLane = 0;
  int _score = 0;
  int _lives = _maxLives;
  int _wave = 1;
  double _speed = 0.06;
  bool _running = false;
  String _message = 'Rotate the shield and block the incoming asteroids.';

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetGame() {
    _timer?.cancel();
    setState(() {
      _asteroids
        ..clear()
        ..add(_spawnAsteroid());
      _shieldLane = 0;
      _score = 0;
      _lives = _maxLives;
      _wave = 1;
      _speed = 0.06;
      _running = false;
      _message = 'Rotate the shield and block the incoming asteroids.';
    });
  }

  void _startGame() {
    _resetGame();
    setState(() {
      _running = true;
      _message = 'Defense online. Watch every edge of the station.';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 220), (_) => _tick());
  }

  _Asteroid _spawnAsteroid() {
    return _Asteroid(lane: _random.nextInt(4), progress: 0);
  }

  Future<void> _tick() async {
    if (!_running || !mounted) return;

    final updated = <_Asteroid>[];
    var blocked = 0;
    var hit = false;

    for (final asteroid in _asteroids) {
      final nextProgress = asteroid.progress + _speed;
      if (nextProgress >= 1) {
        if (asteroid.lane == _shieldLane) {
          blocked += 1;
          continue;
        }
        hit = true;
        break;
      }
      updated.add(asteroid.copyWith(progress: nextProgress));
    }

    if (hit) {
      final nextLives = _lives - 1;
      if (nextLives <= 0) {
        await _finishGame('Station breach. You blocked $_score asteroids.');
        return;
      }
      setState(() {
        _lives = nextLives;
        _asteroids
          ..clear()
          ..add(_spawnAsteroid());
        _message = 'Impact taken. Restore the shield. Lives left: $nextLives.';
      });
      return;
    }

    if (updated.length < min(3, 1 + (_wave ~/ 2)) &&
        _random.nextDouble() < 0.42) {
      updated.add(_spawnAsteroid());
    }

    final nextScore = _score + blocked;
    final nextWave = 1 + (nextScore ~/ 5);

    setState(() {
      _score = nextScore;
      _wave = nextWave;
      _speed = min(0.14, 0.06 + (nextWave - 1) * 0.008);
      _asteroids
        ..clear()
        ..addAll(updated);
      _message = blocked > 0
          ? 'Clean block. The field is getting faster.'
          : 'Track the gaps and keep the station covered.';
    });
  }

  Future<void> _finishGame(String reason) async {
    _timer?.cancel();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _message = reason;
    });
  }

  void _rotateLeft() {
    if (!_running) return;
    setState(() {
      _shieldLane = (_shieldLane + 3) % 4;
    });
  }

  void _rotateRight() {
    if (!_running) return;
    setState(() {
      _shieldLane = (_shieldLane + 1) % 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff8b5cf6), Color(0xffec4899)];
    return GameScaffold(
      title: 'Asteroid Shield',
      subtitle:
          'Spin the defense ring and protect the station from every side.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Wave',
            leftValue: _wave.toString(),
            rightLabel: 'Blocks',
            rightValue: _score.toString(),
            footer:
                'Lives: $_lives/$_maxLives • Shield: ${_laneName(_shieldLane)}',
          ),
          const SizedBox(height: 18),
          StatusCard(
            headline: 'Defense rules',
            message:
                'Use left and right to rotate the shield ring. Asteroids hitting the covered lane are blocked. Any uncovered hit costs a life.',
            accent: accent.last,
            highlight: true,
          ),
          const SizedBox(height: 14),
          StatusCard(message: _message, accent: accent.first),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                SizedBox(
                  height: 280,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = min(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return Center(
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Container(
                                  width: size * 0.38,
                                  height: size * 0.38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.08),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.satellite_alt_rounded,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: _laneAlignments[_shieldLane],
                                child: Container(
                                  width: _shieldLane.isEven ? size * 0.32 : 18,
                                  height: _shieldLane.isEven ? 18 : size * 0.32,
                                  decoration: BoxDecoration(
                                    color: accent.last,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.last.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ..._asteroids.map((asteroid) {
                                final lane = _laneAlignments[asteroid.lane];
                                final distance = (1 - asteroid.progress) * 0.42;
                                return Align(
                                  alignment: Alignment(
                                    lane.x * (0.18 + distance * 2),
                                    lane.y * (0.18 + distance * 2),
                                  ),
                                  child: Transform.rotate(
                                    angle: asteroid.progress * pi,
                                    child: Icon(
                                      Icons.brightness_1_rounded,
                                      color: Colors.orange.shade300,
                                      size: 18 + asteroid.progress * 18,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (_running)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _rotateLeft,
                          icon: const Icon(Icons.rotate_left_rounded),
                          label: const Text('Left'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _rotateRight,
                          icon: const Icon(Icons.rotate_right_rounded),
                          label: const Text('Right'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startGame,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start defense'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset defense', onPressed: _resetGame),
        ],
      ),
    );
  }

  String _laneName(int lane) {
    switch (lane) {
      case 0:
        return 'Top';
      case 1:
        return 'Right';
      case 2:
        return 'Bottom';
      case 3:
      default:
        return 'Left';
    }
  }
}

class _Asteroid {
  const _Asteroid({required this.lane, required this.progress});

  final int lane;
  final double progress;

  _Asteroid copyWith({int? lane, double? progress}) {
    return _Asteroid(
      lane: lane ?? this.lane,
      progress: progress ?? this.progress,
    );
  }
}
