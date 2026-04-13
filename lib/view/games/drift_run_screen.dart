import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class DriftRunScreen extends StatefulWidget {
  const DriftRunScreen({super.key});

  @override
  State<DriftRunScreen> createState() => _DriftRunScreenState();
}

class _DriftRunScreenState extends State<DriftRunScreen> {
  static const int _laneCount = 4;
  static const double _trackHeight = 360;
  static const double _carHeight = 60;
  static const double _gateHeight = 44;

  final List<_Gate> _gates = [];
  final math.Random _random = math.Random();
  Timer? _timer;

  int _playerLane = 1;
  int _bestDistance = 0;
  int _distance = 0;
  int _combo = 0;
  int _lives = 3;
  double _roadOffset = 0;
  double _speed = 5.2;
  bool _running = false;
  bool _crashed = false;
  String _message = 'Drift left and right through open gates.';

  @override
  void initState() {
    super.initState();
    _loadBest();
    _resetRace();
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
      _bestDistance = snapshot.driftRunBestDistance;
    });
  }

  void _resetRace() {
    _timer?.cancel();
    setState(() {
      _playerLane = 1;
      _distance = 0;
      _combo = 0;
      _lives = 3;
      _roadOffset = 0;
      _speed = 5.2;
      _running = false;
      _crashed = false;
      _message = 'Drift left and right through open gates.';
      _gates
        ..clear()
        ..add(_spawnGate(-_gateHeight))
        ..add(_spawnGate(-180));
    });
  }

  _Gate _spawnGate(double y) {
    final safeLane = _random.nextInt(_laneCount);
    return _Gate(y: y, safeLane: safeLane);
  }

  void _startRun() {
    _resetRace();
    setState(() {
      _running = true;
      _message = 'Race on. Hit the open lane before each barrier.';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 45), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!_running || !mounted) return;

    final playerY = _trackHeight - _carHeight - 16;
    final passed = <_Gate>[];
    final updated = <_Gate>[];
    var lostLife = false;

    for (final gate in _gates) {
      final nextY = gate.y + _speed;
      final reachesCar =
          gate.y <= playerY && nextY >= playerY - (_gateHeight / 2);

      if (reachesCar) {
        if (_playerLane != gate.safeLane) {
          lostLife = true;
        } else {
          passed.add(gate);
        }
      }

      if (nextY < _trackHeight + 80) {
        updated.add(gate.copyWith(y: nextY));
      }
    }

    if (lostLife) {
      final nextLives = _lives - 1;
      if (nextLives <= 0) {
        await _finishRun();
        return;
      }
      setState(() {
        _lives = nextLives;
        _combo = 0;
        _message = 'Barrier hit. $nextLives lives left.';
      });
    }

    while (updated.length < 3) {
      final topY = updated.isEmpty ? -_gateHeight : updated.last.y - 150;
      updated.add(_spawnGate(topY));
    }

    final addedDistance = passed.length * 20;
    setState(() {
      _gates
        ..clear()
        ..addAll(updated);
      _distance += addedDistance;
      _roadOffset = (_roadOffset + _speed) % 52;
      if (passed.isNotEmpty) {
        _combo += passed.length;
        _speed = math.min(10.8, _speed + 0.18);
        _message = _combo >= 5
            ? 'Hot streak. Gates are coming faster.'
            : 'Clean drift. Line up for the next gate.';
      }
    });
  }

  Future<void> _finishRun() async {
    _timer?.cancel();
    if (_distance > _bestDistance) {
      await GameStatsStore.instance.recordDriftRunBestDistance(_distance);
    }
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _crashed = true;
      if (_distance > _bestDistance) {
        _bestDistance = _distance;
      }
      _message = _distance >= _bestDistance
          ? 'Crash, but new best: $_distance m.'
          : 'Crash at $_distance m. Reset and try again.';
    });
  }

  void _move(int delta) {
    if (!_running) return;
    setState(() {
      _playerLane = (_playerLane + delta).clamp(0, _laneCount - 1);
      _message = delta < 0 ? 'Cutting left.' : 'Cutting right.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Drift Run',
      subtitle: 'Slide the car through open gates and survive the rush.',
      accent: const [Color(0xfff97316), Color(0xff0ea5e9)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Distance',
            leftValue: '$_distance m',
            rightLabel: 'Best',
            rightValue: '$_bestDistance m',
            footer:
                'Lives $_lives • Combo $_combo • Speed ${_speed.toStringAsFixed(1)}',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xff0ea5e9)),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final laneWidth = constraints.maxWidth / _laneCount;
                final playerY = _trackHeight - _carHeight - 16;
                return GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity;
                    if (velocity == null) return;
                    if (velocity < 0) {
                      _move(-1);
                    } else if (velocity > 0) {
                      _move(1);
                    }
                  },
                  child: Container(
                    height: _trackHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xff111827), Color(0xff030712)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Row(
                            children: List.generate(_laneCount, (lane) {
                              return Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: lane == _laneCount - 1
                                          ? BorderSide.none
                                          : BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: 0.07,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        ...List.generate(9, (index) {
                          final top =
                              ((index * 58.0) + _roadOffset) %
                                  (_trackHeight + 42) -
                              42;
                          return Positioned(
                            top: top,
                            left: constraints.maxWidth / 2 - 3,
                            child: Container(
                              height: 28,
                              width: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: 0.48),
                              ),
                            ),
                          );
                        }),
                        ..._gates.map((gate) {
                          return Positioned(
                            top: gate.y,
                            left: 0,
                            right: 0,
                            child: _GateBar(
                              laneWidth: laneWidth,
                              laneCount: _laneCount,
                              safeLane: gate.safeLane,
                            ),
                          );
                        }),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          left:
                              (_playerLane * laneWidth) + (laneWidth - 42) / 2,
                          top: playerY,
                          child: Container(
                            height: _carHeight,
                            width: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: _crashed
                                  ? const Color(0xffef4444)
                                  : const Color(0xfff97316),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xfff97316,
                                  ).withValues(alpha: 0.34),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.directions_car_filled_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (!_running)
                          Positioned.fill(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                color: Colors.black.withValues(alpha: 0.28),
                              ),
                              child: Text(
                                _crashed
                                    ? 'Tap Start to run again'
                                    : 'Tap Start and drift through the open gaps',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _move(-1) : _startRun,
                  child: Text(_running ? 'Move left' : 'Start run'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _move(1) : null,
                  child: const Text('Move right'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset race', onPressed: _resetRace),
        ],
      ),
    );
  }
}

class _Gate {
  const _Gate({required this.y, required this.safeLane});

  final double y;
  final int safeLane;

  _Gate copyWith({double? y, int? safeLane}) {
    return _Gate(y: y ?? this.y, safeLane: safeLane ?? this.safeLane);
  }
}

class _GateBar extends StatelessWidget {
  const _GateBar({
    required this.laneWidth,
    required this.laneCount,
    required this.safeLane,
  });

  final double laneWidth;
  final int laneCount;
  final int safeLane;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _DriftRunScreenState._gateHeight,
      child: Row(
        children: List.generate(laneCount, (lane) {
          final open = lane == safeLane;
          return SizedBox(
            width: laneWidth,
            child: Center(
              child: open
                  ? Container(
                      height: 30,
                      width: laneWidth - 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xff22c55e).withValues(alpha: 0.28),
                        border: Border.all(color: const Color(0xff22c55e)),
                      ),
                    )
                  : Container(
                      height: 34,
                      width: laneWidth - 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xffef4444).withValues(alpha: 0.88),
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }
}
