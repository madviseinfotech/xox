import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class ParkingDashScreen extends StatefulWidget {
  const ParkingDashScreen({super.key});

  @override
  State<ParkingDashScreen> createState() => _ParkingDashScreenState();
}

class _ParkingDashScreenState extends State<ParkingDashScreen> {
  static const int _laneCount = 3;
  static const double _boardHeight = 360;
  static const Duration _tick = Duration(milliseconds: 60);

  final math.Random _random = math.Random();
  Timer? _timer;

  int _lane = 1;
  int _round = 1;
  int _bestLevel = 0;
  int _timeLeft = 70;
  bool _running = false;
  bool _failed = false;
  double _approach = 0;
  double _steerNeedle = 0.18;
  bool _needleForward = true;
  late int _targetLane;
  late double _targetAngle;
  String _message = 'Line up the car and park inside the marked bay.';

  @override
  void initState() {
    super.initState();
    _loadBest();
    _prepareRound(reset: true);
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
      _bestLevel = snapshot.parkingDashBestLevel;
    });
  }

  void _prepareRound({bool reset = false}) {
    _timer?.cancel();
    final nextRound = reset ? 1 : _round;
    setState(() {
      if (reset) {
        _round = 1;
        _failed = false;
      }
      _lane = 1;
      _timeLeft = math.max(34, 70 - ((nextRound - 1) * 5));
      _approach = 0;
      _steerNeedle = 0.18;
      _needleForward = true;
      _running = false;
      _targetLane = _random.nextInt(_laneCount);
      _targetAngle = 0.36 + (_random.nextDouble() * 0.28);
      _message = 'Round $nextRound: match the lane and steer into the bay.';
    });
  }

  void _startRound() {
    _timer?.cancel();
    setState(() {
      _running = true;
      _failed = false;
      _message = 'Move to the target lane and tap Park at the right angle.';
    });
    _timer = Timer.periodic(_tick, (_) => _tickRound());
  }

  void _tickRound() {
    if (!_running || !mounted) return;
    final nextNeedle = _needleForward
        ? _steerNeedle + 0.045
        : _steerNeedle - 0.045;
    if (nextNeedle >= 1) {
      _steerNeedle = 1;
      _needleForward = false;
    } else if (nextNeedle <= 0) {
      _steerNeedle = 0;
      _needleForward = true;
    } else {
      _steerNeedle = nextNeedle;
    }

    setState(() {
      _approach = math.min(1, _approach + 0.022 + (_round * 0.0025));
      _timeLeft -= 1;
      if (_timeLeft <= 16) {
        _message = 'Hurry up. The bay is closing.';
      }
    });

    if (_timeLeft <= 0 || _approach >= 1) {
      _failRound('Too late. The car rolled past the parking bay.');
    }
  }

  bool _angleIsGood() => (_steerNeedle - _targetAngle).abs() <= 0.11;

  Future<void> _parkCar() async {
    if (!_running) return;
    final laneMatch = _lane == _targetLane;
    final angleMatch = _angleIsGood();

    if (laneMatch && angleMatch) {
      final clearedRound = _round;
      if (clearedRound > _bestLevel) {
        await GameStatsStore.instance.recordParkingDashBestLevel(clearedRound);
      }
      if (!mounted) return;
      setState(() {
        _running = false;
        if (clearedRound > _bestLevel) {
          _bestLevel = clearedRound;
        }
        _round = clearedRound + 1;
        _message = 'Perfect park. Next bay is tighter.';
      });
      _prepareRound();
      return;
    }

    if (!laneMatch && !angleMatch) {
      await _failRound('Wrong lane and bad angle. Parking failed.');
      return;
    }
    if (!laneMatch) {
      await _failRound('Wrong lane. Shift into the highlighted bay first.');
      return;
    }
    await _failRound('Angle was off. Tap Park near the green zone.');
  }

  Future<void> _failRound(String message) async {
    _timer?.cancel();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _failed = true;
      _message = message;
    });
  }

  void _moveLane(int delta) {
    if (!_running) return;
    setState(() {
      _lane = (_lane + delta).clamp(0, _laneCount - 1);
      _message = delta < 0
          ? 'Turning left into place.'
          : 'Turning right into place.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Parking Dash',
      subtitle: 'Move into the correct bay and tap Park at the right angle.',
      accent: const [Color(0xff22c55e), Color(0xff0ea5e9)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Best',
            rightValue: _bestLevel.toString(),
            footer:
                'Lane ${_lane + 1} • Target ${_targetLane + 1} • Time $_timeLeft',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xff22c55e)),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parking bay',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  height: _boardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xff0f172a), Color(0xff020617)],
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final laneWidth = constraints.maxWidth / _laneCount;
                      final carTop = (_boardHeight - 76) * _approach;
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Row(
                              children: List.generate(_laneCount, (index) {
                                final target = index == _targetLane;
                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: target
                                            ? const Color(0xff22c55e)
                                            : Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                      ),
                                      color: target
                                          ? const Color(
                                              0xff22c55e,
                                            ).withValues(alpha: 0.12)
                                          : Colors.white.withValues(
                                              alpha: 0.03,
                                            ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          Positioned(
                            top: 18,
                            left: (_targetLane * laneWidth) + 12,
                            width: laneWidth - 24,
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xff22c55e),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: _tick,
                            curve: Curves.linear,
                            top: carTop,
                            left: (_lane * laneWidth) + (laneWidth - 46) / 2,
                            child: Transform.rotate(
                              angle: (_steerNeedle - 0.5) * 0.9,
                              child: Container(
                                height: 72,
                                width: 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: _failed
                                      ? const Color(0xffef4444)
                                      : const Color(0xff0ea5e9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xff0ea5e9,
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
                          ),
                          if (!_running)
                            Positioned.fill(
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26),
                                  color: Colors.black.withValues(alpha: 0.22),
                                ),
                                child: Text(
                                  _failed
                                      ? 'Tap Start to try parking again'
                                      : 'Tap Start and park in the highlighted bay',
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
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Steer meter',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    children: [
                      LinearProgressIndicator(
                        minHeight: 14,
                        value: 1,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.22,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(color: Color(0xff22c55e)),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _steerNeedle.clamp(0.0, 1.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(width: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _moveLane(-1) : _startRound,
                  child: Text(_running ? 'Move left' : 'Start'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? _parkCar : null,
                  child: const Text('Park'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? () => _moveLane(1) : null,
                  child: const Text('Move right'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ResetActionButton(
            label: 'Reset game',
            onPressed: () => _prepareRound(reset: true),
          ),
        ],
      ),
    );
  }
}
