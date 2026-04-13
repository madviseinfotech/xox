import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class HighwayHeatScreen extends StatefulWidget {
  const HighwayHeatScreen({super.key});

  @override
  State<HighwayHeatScreen> createState() => _HighwayHeatScreenState();
}

class _HighwayHeatScreenState extends State<HighwayHeatScreen> {
  static const int _laneCount = 3;
  static const double _trackHeight = 340;
  static const double _playerHeight = 66;
  static const double _trafficHeight = 60;

  final math.Random _random = math.Random();
  final List<_LaneCar> _traffic = [];
  Timer? _timer;

  int _lane = 1;
  int _distance = 0;
  int _nearMisses = 0;
  double _speed = 5.4;
  double _dashOffset = 0;
  bool _running = false;
  bool _finished = false;
  String _message =
      'Switch lanes, miss traffic by inches, and hold the highway.';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    _traffic
      ..clear()
      ..addAll(
        List<_LaneCar>.generate(4, (index) {
          return _LaneCar(
            lane: index % _laneCount,
            y: -80.0 - (index * 120),
            color: _palette[index % _palette.length],
          );
        }),
      );
    setState(() {
      _lane = 1;
      _distance = 0;
      _nearMisses = 0;
      _speed = 5.4;
      _dashOffset = 0;
      _running = false;
      _finished = false;
      _message = 'Switch lanes, miss traffic by inches, and hold the highway.';
    });
  }

  void _start() {
    _reset();
    setState(() {
      _running = true;
      _message = 'Highway is live. Keep calm and slide through the gaps.';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!_running || !mounted) return;
    final playerTop = _trackHeight - _playerHeight - 16;
    final updated = <_LaneCar>[];
    var crash = false;
    var nearMissGain = 0;

    for (final car in _traffic) {
      final nextY = car.y + _speed;
      final overlaps =
          car.lane == _lane &&
          nextY < playerTop + _playerHeight - 6 &&
          nextY + _trafficHeight > playerTop + 6;
      if (overlaps) {
        crash = true;
        break;
      }
      final passedNear =
          nextY + _trafficHeight > playerTop - 6 &&
          nextY + _trafficHeight < playerTop + 14 &&
          (car.lane - _lane).abs() == 1;
      if (passedNear) {
        nearMissGain += 1;
      }
      if (nextY > _trackHeight + 80) {
        updated.add(
          _LaneCar(
            lane: _random.nextInt(_laneCount),
            y: -_trafficHeight - _random.nextInt(100),
            color: _palette[_random.nextInt(_palette.length)],
          ),
        );
      } else {
        updated.add(car.copyWith(y: nextY));
      }
    }

    if (crash) {
      await _finish('Traffic hit. Read the gap earlier and try again.');
      return;
    }

    setState(() {
      _traffic
        ..clear()
        ..addAll(updated);
      _distance += (_speed * 2.2).round();
      _nearMisses += nearMissGain;
      _speed = math.min(10.8, _speed + 0.015);
      _dashOffset = (_dashOffset + _speed) % 48;
      _message = nearMissGain > 0
          ? 'Near miss. That was close.'
          : _distance > 800
          ? 'Road is getting faster. Stay centered before each move.'
          : 'Open road for a moment. Plan your next switch.';
    });
  }

  Future<void> _finish(String reason) async {
    _timer?.cancel();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _message = '$reason Distance $_distance m • Near misses $_nearMisses';
    });
  }

  void _move(int delta) {
    if (!_running) return;
    setState(() {
      _lane = (_lane + delta).clamp(0, _laneCount - 1);
      _message = delta < 0 ? 'Changing left.' : 'Changing right.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _LaneRaceShell(
      title: 'Highway Heat',
      subtitle:
          'Dodge civilian traffic and keep the car alive at rising speed.',
      accent: const [Color(0xffef4444), Color(0xfff97316)],
      leftLabel: 'Distance',
      leftValue: '$_distance m',
      rightLabel: 'Near',
      rightValue: '$_nearMisses',
      footer: 'Speed ${_speed.toStringAsFixed(1)} • Highway run',
      message: _message,
      running: _running,
      finished: _finished,
      dashOffset: _dashOffset,
      laneCount: _laneCount,
      trackHeight: _trackHeight,
      playerLane: _lane,
      rivals: _traffic,
      playerCar: const _CarVisual(
        color: Color(0xfff43f5e),
        glow: Color(0xfffb7185),
      ),
      onLeft: () => _move(-1),
      onRight: () => _move(1),
      onStart: _start,
    );
  }
}

class PoliceEscapeScreen extends StatefulWidget {
  const PoliceEscapeScreen({super.key});

  @override
  State<PoliceEscapeScreen> createState() => _PoliceEscapeScreenState();
}

class _PoliceEscapeScreenState extends State<PoliceEscapeScreen> {
  static const int _laneCount = 4;
  static const double _trackHeight = 340;
  static const double _playerHeight = 66;
  static const double _blockHeight = 54;

  final math.Random _random = math.Random();
  final List<_RoadBlock> _blocks = [];
  Timer? _timer;

  int _lane = 1;
  int _escapeMeter = 0;
  int _stars = 1;
  double _dashOffset = 0;
  bool _running = false;
  bool _finished = false;
  String _message =
      'Dodge police blocks and survive long enough to lose the tail.';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    _blocks
      ..clear()
      ..addAll(
        List<_RoadBlock>.generate(4, (index) {
          return _RoadBlock(
            lane: index % _laneCount,
            y: -60.0 - (index * 100),
            police: index.isEven,
          );
        }),
      );
    setState(() {
      _lane = 1;
      _escapeMeter = 0;
      _stars = 1;
      _dashOffset = 0;
      _running = false;
      _finished = false;
      _message =
          'Dodge police blocks and survive long enough to lose the tail.';
    });
  }

  void _start() {
    _reset();
    setState(() {
      _running = true;
      _message = 'Wanted level climbing. Keep moving and do not get boxed in.';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 45), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!_running || !mounted) return;
    final playerTop = _trackHeight - _playerHeight - 16;
    final updated = <_RoadBlock>[];
    final speed = 5.0 + (_stars * 0.9);
    var crash = false;

    for (final block in _blocks) {
      final nextY = block.y + speed;
      final overlaps =
          block.lane == _lane &&
          nextY < playerTop + _playerHeight - 8 &&
          nextY + _blockHeight > playerTop + 8;
      if (overlaps) {
        crash = true;
        break;
      }
      if (nextY > _trackHeight + 60) {
        updated.add(
          _RoadBlock(
            lane: _random.nextInt(_laneCount),
            y: -_blockHeight - _random.nextInt(90),
            police: _random.nextBool(),
          ),
        );
      } else {
        updated.add(block.copyWith(y: nextY));
      }
    }

    if (crash) {
      await _finish('Roadblock closed the lane. The chase is over.');
      return;
    }

    final nextEscape = _escapeMeter + 2;
    if (nextEscape >= 100) {
      await _win();
      return;
    }

    setState(() {
      _blocks
        ..clear()
        ..addAll(updated);
      _escapeMeter = nextEscape;
      _stars = 1 + (_escapeMeter ~/ 25);
      _dashOffset = (_dashOffset + speed) % 48;
      _message = _escapeMeter > 74
          ? 'Almost clear. One more stretch and you lose them.'
          : _stars >= 3
          ? 'More units ahead. Pick your lane early.'
          : 'Police still on you. Stay unpredictable.';
    });
  }

  Future<void> _win() async {
    _timer?.cancel();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _message =
          'Escape complete. You shook the pursuit with $_stars wanted stars.';
    });
  }

  Future<void> _finish(String reason) async {
    _timer?.cancel();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _message = '$reason Escape $_escapeMeter% complete.';
    });
  }

  void _move(int delta) {
    if (!_running) return;
    setState(() {
      _lane = (_lane + delta).clamp(0, _laneCount - 1);
      _message = delta < 0
          ? 'Cutting left through traffic.'
          : 'Cutting right through traffic.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final rivals = _blocks
        .map(
          (block) => _LaneCar(
            lane: block.lane,
            y: block.y,
            color: block.police
                ? const Color(0xff60a5fa)
                : const Color(0xfffbbf24),
          ),
        )
        .toList(growable: false);
    return _LaneRaceShell(
      title: 'Police Escape',
      subtitle:
          'Outlast the pursuit, dodge roadblocks, and lose the wanted level.',
      accent: const [Color(0xff2563eb), Color(0xff0ea5e9)],
      leftLabel: 'Escape',
      leftValue: '$_escapeMeter%',
      rightLabel: 'Stars',
      rightValue: '$_stars',
      footer: 'Roadblock speed ${(5.0 + (_stars * 0.9)).toStringAsFixed(1)}',
      message: _message,
      running: _running,
      finished: _finished,
      dashOffset: _dashOffset,
      laneCount: _laneCount,
      trackHeight: _trackHeight,
      playerLane: _lane,
      rivals: rivals,
      playerCar: const _CarVisual(
        color: Color(0xff0f172a),
        glow: Color(0xff38bdf8),
      ),
      onLeft: () => _move(-1),
      onRight: () => _move(1),
      onStart: _start,
    );
  }
}

class PitStopProScreen extends StatefulWidget {
  const PitStopProScreen({super.key});

  @override
  State<PitStopProScreen> createState() => _PitStopProScreenState();
}

class _PitStopProScreenState extends State<PitStopProScreen> {
  static const List<_PitAction> _actions = [
    _PitAction('Tyres', Icons.tire_repair_rounded, Color(0xfff97316)),
    _PitAction('Fuel', Icons.local_gas_station_rounded, Color(0xff22c55e)),
    _PitAction('Wing', Icons.settings_rounded, Color(0xff38bdf8)),
    _PitAction('Jack', Icons.build_rounded, Color(0xffa855f7)),
  ];

  final math.Random _random = math.Random();
  final List<int> _sequence = [];
  int _inputIndex = 0;
  int _round = 0;
  int _mistakes = 0;
  bool _showing = false;
  bool _running = false;
  bool _finished = false;
  String _message =
      'Memorize the pit sequence and finish service without mistakes.';

  void _start() {
    setState(() {
      _sequence
        ..clear()
        ..add(_random.nextInt(_actions.length));
      _inputIndex = 0;
      _round = 1;
      _mistakes = 0;
      _running = true;
      _finished = false;
      _message = 'Crew chief is calling the first service sequence.';
    });
    _revealSequence();
  }

  Future<void> _revealSequence() async {
    setState(() {
      _showing = true;
      _inputIndex = 0;
    });
    await Future<void>.delayed(
      Duration(milliseconds: 600 + (_sequence.length * 220)),
    );
    if (!mounted) return;
    setState(() {
      _showing = false;
      _message = 'Now tap the pit actions in the same order.';
    });
  }

  Future<void> _tapAction(int index) async {
    if (!_running || _showing) return;
    final expected = _sequence[_inputIndex];
    if (index != expected) {
      final nextMistakes = _mistakes + 1;
      if (nextMistakes >= 3) {
        await _finish(
          'Pit stop collapsed. Too many wrong calls from the crew.',
        );
        return;
      }
      setState(() {
        _mistakes = nextMistakes;
        _inputIndex = 0;
        _message = 'Wrong station. Reset the sequence and try again.';
      });
      return;
    }

    if (_inputIndex == _sequence.length - 1) {
      if (_round >= 5) {
        await _win();
        return;
      }
      setState(() {
        _round += 1;
        _sequence.add(_random.nextInt(_actions.length));
        _inputIndex = 0;
        _message = 'Clean stop. Next lap adds another service call.';
      });
      await _revealSequence();
      return;
    }

    setState(() {
      _inputIndex += 1;
      _message = 'Good. Keep the pit sequence flowing.';
    });
  }

  Future<void> _win() async {
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _message = 'Perfect pit work. You nailed all 5 pit sequences.';
    });
  }

  Future<void> _finish(String reason) async {
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _message = '$reason Completed rounds: $_round';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Pit Stop Pro',
      subtitle:
          'Remember the crew order and service the car like a live race team.',
      accent: const [Color(0xff22c55e), Color(0xff0ea5e9)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: '$_round/5',
            rightLabel: 'Mistakes',
            rightValue: '$_mistakes/3',
            footer: _showing
                ? 'Sequence is showing'
                : 'Input ${_inputIndex + 1}/${_sequence.isEmpty ? 1 : _sequence.length}',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xff0ea5e9)),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List<Widget>.generate(_actions.length, (index) {
                    final action = _actions[index];
                    final highlighted =
                        _showing &&
                        _sequence.take(_inputIndex + 1).contains(index);
                    return SizedBox(
                      width: 140,
                      child: _ActionTile(
                        icon: action.icon,
                        label: action.label,
                        color: action.color,
                        highlighted: highlighted,
                        onTap: () => _tapAction(index),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _running ? null : _start,
                    child: Text(_finished ? 'Run it again' : 'Start pit stop'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CheckpointDashScreen extends StatefulWidget {
  const CheckpointDashScreen({super.key});

  @override
  State<CheckpointDashScreen> createState() => _CheckpointDashScreenState();
}

class _CheckpointDashScreenState extends State<CheckpointDashScreen> {
  Timer? _timer;
  double _speed = 42;
  double _distance = 0;
  int _checkpoint = 1;
  double _targetMin = 70;
  double _targetMax = 90;
  bool _running = false;
  bool _finished = false;
  bool _throttleHeld = false;
  bool _brakeHeld = false;
  String _message = 'Hit each checkpoint inside the target speed window.';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _speed = 42;
      _distance = 0;
      _checkpoint = 1;
      _targetMin = 70;
      _targetMax = 90;
      _running = true;
      _finished = false;
      _throttleHeld = false;
      _brakeHeld = false;
      _message = 'Checkpoint one ahead. Build pace into the green window.';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 55), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!_running || !mounted) return;
    var nextSpeed = _speed;
    if (_throttleHeld) nextSpeed += 3.4;
    if (_brakeHeld) nextSpeed -= 4.6;
    if (!_throttleHeld && !_brakeHeld) nextSpeed -= 0.8;
    nextSpeed = nextSpeed.clamp(20.0, 140.0);
    final nextDistance = _distance + (nextSpeed * 0.22);

    if (nextDistance >= 100) {
      final inWindow = nextSpeed >= _targetMin && nextSpeed <= _targetMax;
      if (!inWindow) {
        await _finish(
          'Missed checkpoint speed. You crossed at ${nextSpeed.round()} km/h.',
        );
        return;
      }
      if (_checkpoint >= 5) {
        await _win(nextSpeed);
        return;
      }
      setState(() {
        _speed = nextSpeed;
        _distance = 0;
        _checkpoint += 1;
        _targetMin = math.min(112.0, _targetMin + 6);
        _targetMax = math.min(128.0, _targetMax + 6);
        _message = 'Checkpoint cleared. Reset for the next speed gate.';
      });
      return;
    }

    setState(() {
      _speed = nextSpeed;
      _distance = nextDistance;
      _message = nextSpeed < _targetMin
          ? 'Too slow. Feed in more throttle.'
          : nextSpeed > _targetMax
          ? 'Too hot. Brake for the gate.'
          : 'Perfect range. Hold this pace.';
    });
  }

  Future<void> _win(double speed) async {
    _timer?.cancel();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _throttleHeld = false;
      _brakeHeld = false;
      _message =
          'All 5 checkpoints cleared. Final gate at ${speed.round()} km/h.';
    });
  }

  Future<void> _finish(String reason) async {
    _timer?.cancel();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _throttleHeld = false;
      _brakeHeld = false;
      _message = reason;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_distance / 100).clamp(0.0, 1.0);
    return GameScaffold(
      title: 'Checkpoint Dash',
      subtitle:
          'Balance throttle and brake to cross every speed trap on target.',
      accent: const [Color(0xfff59e0b), Color(0xffef4444)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Gate',
            leftValue: '$_checkpoint/5',
            rightLabel: 'Speed',
            rightValue: '${_speed.round()} km/h',
            footer: 'Target ${_targetMin.round()}-${_targetMax.round()} km/h',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xffef4444)),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SpeedDial(speed: _speed, min: _targetMin, max: _targetMax),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xfff59e0b),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Distance to checkpoint',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xff94a3b8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HoldTile(
                        icon: Icons.speed_rounded,
                        label: 'Throttle',
                        color: const Color(0xff22c55e),
                        active: _throttleHeld,
                        onChanged: (value) {
                          if (!_running) return;
                          setState(() => _throttleHeld = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HoldTile(
                        icon: Icons.stop_circle_outlined,
                        label: 'Brake',
                        color: const Color(0xffef4444),
                        active: _brakeHeld,
                        onChanged: (value) {
                          if (!_running) return;
                          setState(() => _brakeHeld = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _running ? null : _start,
                    child: Text(
                      _finished ? 'Drive again' : 'Start checkpoint run',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConeSlalomScreen extends StatefulWidget {
  const ConeSlalomScreen({super.key});

  @override
  State<ConeSlalomScreen> createState() => _ConeSlalomScreenState();
}

class _ConeSlalomScreenState extends State<ConeSlalomScreen> {
  static const int _laneCount = 4;
  static const double _trackHeight = 340;
  static const double _gateHeight = 44;
  static const double _playerHeight = 64;

  final math.Random _random = math.Random();
  final List<_SlalomGate> _gates = [];
  Timer? _timer;

  int _lane = 1;
  int _clears = 0;
  int _lives = 3;
  double _speed = 5.0;
  double _dashOffset = 0;
  bool _running = false;
  bool _finished = false;
  String _message = 'Move into the open lane between cone walls.';

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    _gates
      ..clear()
      ..addAll(
        List<_SlalomGate>.generate(3, (index) {
          return _SlalomGate(
            y: -80.0 - (index * 120),
            safeLane: index % _laneCount,
          );
        }),
      );
    setState(() {
      _lane = 1;
      _clears = 0;
      _lives = 3;
      _speed = 5.0;
      _dashOffset = 0;
      _running = false;
      _finished = false;
      _message = 'Move into the open lane between cone walls.';
    });
  }

  void _start() {
    _reset();
    setState(() {
      _running = true;
      _message = 'Slalom starts now. Find the safe opening every time.';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 45), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!_running || !mounted) return;
    final playerY = _trackHeight - _playerHeight - 16;
    final updated = <_SlalomGate>[];
    var hitGate = false;
    var clearedNow = 0;

    for (final gate in _gates) {
      final nextY = gate.y + _speed;
      final reachesPlayer =
          gate.y <= playerY && nextY >= playerY - (_gateHeight / 2);
      if (reachesPlayer) {
        if (_lane != gate.safeLane) {
          hitGate = true;
        } else {
          clearedNow += 1;
        }
      }
      if (nextY > _trackHeight + 60) {
        updated.add(
          _SlalomGate(
            y: -_gateHeight - _random.nextInt(120),
            safeLane: _random.nextInt(_laneCount),
          ),
        );
      } else {
        updated.add(gate.copyWith(y: nextY));
      }
    }

    if (hitGate) {
      final nextLives = _lives - 1;
      if (nextLives <= 0) {
        await _finish('Cone wall hit. Slalom run is over.');
        return;
      }
      setState(() {
        _lives = nextLives;
        _message = 'Cone contact. $nextLives lives left.';
      });
    }

    setState(() {
      _gates
        ..clear()
        ..addAll(updated);
      _clears += clearedNow;
      _speed = math.min(9.8, _speed + (clearedNow > 0 ? 0.16 : 0.01));
      _dashOffset = (_dashOffset + _speed) % 48;
      _message = clearedNow > 0
          ? 'Clean slalom. Another cone gate ahead.'
          : _speed > 8
          ? 'Quick hands now. Gates are closing faster.'
          : _message;
    });
  }

  Future<void> _finish(String reason) async {
    _timer?.cancel();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _message = '$reason Clean gates $_clears';
    });
  }

  void _move(int delta) {
    if (!_running) return;
    setState(() {
      _lane = (_lane + delta).clamp(0, _laneCount - 1);
      _message = delta < 0 ? 'Darting left.' : 'Darting right.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final rivals = _gates
        .map(
          (gate) => _LaneCar(
            lane: gate.safeLane,
            y: gate.y,
            color: const Color(0xfff59e0b),
          ),
        )
        .toList(growable: false);
    return _LaneRaceShell(
      title: 'Cone Slalom',
      subtitle: 'Thread the car through cone walls and keep the rhythm alive.',
      accent: const [Color(0xfff59e0b), Color(0xfffb7185)],
      leftLabel: 'Clears',
      leftValue: '$_clears',
      rightLabel: 'Lives',
      rightValue: '$_lives',
      footer: 'Slalom speed ${_speed.toStringAsFixed(1)}',
      message: _message,
      running: _running,
      finished: _finished,
      dashOffset: _dashOffset,
      laneCount: _laneCount,
      trackHeight: _trackHeight,
      playerLane: _lane,
      rivals: rivals,
      playerCar: const _CarVisual(
        color: Color(0xffec4899),
        glow: Color(0xfffb7185),
      ),
      onLeft: () => _move(-1),
      onRight: () => _move(1),
      onStart: _start,
      drawGateWalls: true,
      gateSafeLanes: _gates,
    );
  }
}

class SlipstreamSurgeScreen extends StatefulWidget {
  const SlipstreamSurgeScreen({super.key});

  @override
  State<SlipstreamSurgeScreen> createState() => _SlipstreamSurgeScreenState();
}

class _SlipstreamSurgeScreenState extends State<SlipstreamSurgeScreen> {
  static const int _laneCount = 3;
  static const int _targetPasses = 6;
  static const double _trackHeight = 340;

  final math.Random _random = math.Random();
  Timer? _timer;

  int _playerLane = 1;
  int _rivalLane = 1;
  int _passes = 0;
  double _draft = 18;
  double _gap = 88;
  double _pace = 1;
  double _dashOffset = 0;
  bool _running = false;
  bool _finished = false;
  String _message =
      'Sit in the slipstream, charge the draft meter, then pull out and pass.';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _playerLane = 1;
      _rivalLane = 1;
      _passes = 0;
      _draft = 18;
      _gap = 88;
      _pace = 1;
      _dashOffset = 0;
      _running = true;
      _finished = false;
      _message =
          'Tuck behind the rival first. Build draft before moving out to pass.';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!_running || !mounted) return;

    var nextGap = _gap;
    var nextDraft = _draft;

    if (_playerLane == _rivalLane) {
      nextGap = math.max(18, nextGap - (2.6 + (_pace * 0.3)));
      if (nextGap >= 34 && nextGap <= 92) {
        nextDraft = math.min(100, nextDraft + 2.8 + (_pace * 0.2));
      } else {
        nextDraft = math.max(0, nextDraft - 1.4);
      }
    } else {
      nextGap = math.min(110, nextGap + 0.9);
      nextDraft = math.max(0, nextDraft - 1.2);
    }

    if (nextGap <= 18 && _playerLane == _rivalLane) {
      await _finish('You stayed in the draft too long and hit the rival car.');
      return;
    }

    if (_random.nextDouble() < 0.045) {
      final shift = _random.nextBool() ? -1 : 1;
      _rivalLane = (_rivalLane + shift).clamp(0, _laneCount - 1);
    }

    setState(() {
      _gap = nextGap;
      _draft = nextDraft;
      _dashOffset = (_dashOffset + 6 + _pace) % 48;
      _message = _playerLane == _rivalLane
          ? nextGap < 28
                ? 'Too close. Pull out now before contact.'
                : 'Draft building. Stay tucked in a bit longer.'
          : nextDraft >= 45
          ? 'Charge is ready. Hit PASS while you are alongside.'
          : 'Outside lane, but not enough draft yet. Tuck back in.';
    });
  }

  Future<void> _finish(String reason) async {
    _timer?.cancel();
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _message = reason;
    });
  }

  void _move(int delta) {
    if (!_running) return;
    setState(() {
      _playerLane = (_playerLane + delta).clamp(0, _laneCount - 1);
      _message = delta < 0
          ? 'Sliding left for clean air.'
          : 'Sliding right for the run.';
    });
  }

  Future<void> _attemptPass() async {
    if (!_running) return;
    final sideBySide = (_playerLane - _rivalLane).abs() == 1;
    final goodGap = _gap >= 24 && _gap <= 72;
    final enoughDraft = _draft >= 45;

    if (sideBySide && goodGap && enoughDraft) {
      final nextPasses = _passes + 1;
      if (nextPasses >= _targetPasses) {
        _passes = nextPasses;
        await _finish(
          'Perfect timing. You completed all $_targetPasses overtakes.',
        );
        return;
      }
      setState(() {
        _passes = nextPasses;
        _draft = math.max(0, _draft - 38);
        _gap = 94;
        _pace += 0.7;
        _rivalLane = _random.nextInt(_laneCount);
        _message = 'Clean overtake. Reset and build another draft run.';
      });
      return;
    }

    setState(() {
      _draft = math.max(0, _draft - 16);
      _gap = math.min(110, _gap + 10);
      _message = 'Bad pass attempt. You lost momentum and dropped back.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Slipstream Surge',
      subtitle:
          'Use drafting tactics, pull out at the right time, and complete clean overtakes.',
      accent: const [Color(0xff06b6d4), Color(0xff8b5cf6)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Passes',
            leftValue: '$_passes/$_targetPasses',
            rightLabel: 'Draft',
            rightValue: '${_draft.round()}%',
            footer: 'Gap ${_gap.round()} m • Pace ${_pace.toStringAsFixed(1)}',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xff8b5cf6)),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final laneWidth = constraints.maxWidth / _laneCount;
                final rivalTop = 70.0 + (_gap * 0.7);
                return Column(
                  children: [
                    Container(
                      height: _trackHeight,
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
                            child: CustomPaint(
                              painter: _LaneRoadPainter(
                                laneCount: _laneCount,
                                dashOffset: _dashOffset,
                              ),
                            ),
                          ),
                          Positioned(
                            left: _rivalLane * laneWidth + (laneWidth - 38) / 2,
                            top: rivalTop.clamp(46, 210),
                            child: const _CarVisual(
                              color: Color(0xff38bdf8),
                              glow: Color(0xff60a5fa),
                            ),
                          ),
                          Positioned(
                            left:
                                _playerLane * laneWidth + (laneWidth - 38) / 2,
                            bottom: 18,
                            child: const _CarVisual(
                              color: Color(0xffa855f7),
                              glow: Color(0xffc084fc),
                            ),
                          ),
                          if (_playerLane == _rivalLane &&
                              _gap >= 30 &&
                              _gap <= 95)
                            Positioned(
                              left:
                                  _playerLane * laneWidth +
                                  (laneWidth - 12) / 2,
                              top: rivalTop.clamp(46, 210) + 62,
                              bottom: 86,
                              child: Container(
                                width: 12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x0006b6d4),
                                      Color(0x7706b6d4),
                                      Color(0x0006b6d4),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: _draft / 100,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xff8b5cf6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Slipstream charge',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xff94a3b8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TapTile(
                            icon: Icons.keyboard_double_arrow_left_rounded,
                            label: 'Left',
                            onTap: () => _move(-1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TapTile(
                            icon: Icons.outbond_rounded,
                            label: 'Pass',
                            onTap: _running ? _attemptPass : _start,
                            accent: const Color(0xff8b5cf6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TapTile(
                            icon: Icons.keyboard_double_arrow_right_rounded,
                            label: 'Right',
                            onTap: () => _move(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _running ? null : _start,
                        child: Text(_finished ? 'Run again' : 'Start duel'),
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

class RaceStrategistScreen extends StatefulWidget {
  const RaceStrategistScreen({super.key});

  @override
  State<RaceStrategistScreen> createState() => _RaceStrategistScreenState();
}

class _RaceStrategistScreenState extends State<RaceStrategistScreen> {
  final math.Random _random = math.Random();

  static const int _totalLaps = 6;

  int _lap = 1;
  int _position = 6;
  double _tireWear = 18;
  double _fuel = 100;
  double _weatherRisk = 12;
  bool _running = false;
  bool _finished = false;
  _StrategyScenario _scenario = const _StrategyScenario(
    label: 'Formation Lap',
    detail: 'Warm the tires and get ready for the first call.',
    pressure: 0,
    rainChance: 0,
  );
  String _message =
      'Read the lap conditions and choose the smartest race strategy call.';

  void _start() {
    setState(() {
      _lap = 1;
      _position = 6;
      _tireWear = 18;
      _fuel = 100;
      _weatherRisk = 12;
      _running = true;
      _finished = false;
      _scenario = _nextScenario();
      _message = 'Lap 1 is live. Make the first pit wall decision.';
    });
  }

  _StrategyScenario _nextScenario() {
    final templates = <_StrategyScenario>[
      _StrategyScenario(
        label: 'Clean Air',
        detail: 'Track is open and tire temp is in the window.',
        pressure: (18 + _random.nextInt(18)).toDouble(),
        rainChance: (4 + _random.nextInt(12)).toDouble(),
      ),
      _StrategyScenario(
        label: 'Traffic Train',
        detail: 'Cars ahead are bunched together through sector two.',
        pressure: (28 + _random.nextInt(18)).toDouble(),
        rainChance: (8 + _random.nextInt(14)).toDouble(),
      ),
      _StrategyScenario(
        label: 'Rain Threat',
        detail: 'Clouds are building and grip may drop this lap.',
        pressure: (16 + _random.nextInt(16)).toDouble(),
        rainChance: (42 + _random.nextInt(32)).toDouble(),
      ),
      _StrategyScenario(
        label: 'Safety Car Window',
        detail: 'Pace is slower and a cheap pit stop is possible.',
        pressure: (10 + _random.nextInt(14)).toDouble(),
        rainChance: (6 + _random.nextInt(18)).toDouble(),
      ),
      _StrategyScenario(
        label: 'Tire Fade',
        detail: 'Rear grip is falling away under power.',
        pressure: (26 + _random.nextInt(18)).toDouble(),
        rainChance: (10 + _random.nextInt(16)).toDouble(),
      ),
      _StrategyScenario(
        label: 'Qualifying Pace',
        detail: 'Front runners are pushing and the undercut is on.',
        pressure: (32 + _random.nextInt(22)).toDouble(),
        rainChance: (4 + _random.nextInt(12)).toDouble(),
      ),
    ];
    return templates[_random.nextInt(templates.length)];
  }

  Future<void> _choose(_StrategyChoice choice) async {
    if (!_running) return;

    var positionChange = 0;
    var nextWear = _tireWear;
    var nextFuel = _fuel;
    var nextWeather = _weatherRisk;
    String nextMessage;

    switch (choice) {
      case _StrategyChoice.push:
        nextWear += 22 + (_scenario.pressure * 0.22);
        nextFuel -= 18;
        if (_scenario.rainChance > 52 || _tireWear > 74) {
          positionChange = -2;
          nextMessage =
              'Push was too aggressive. Grip fell away and you lost places.';
        } else if (_scenario.pressure > 24) {
          positionChange = 2;
          nextMessage = 'Attack worked. You jumped rivals with strong pace.';
        } else {
          positionChange = 1;
          nextMessage = 'Good push. You gained track position.';
        }
      case _StrategyChoice.pit:
        nextWear = math.max(8, _tireWear - 48);
        nextFuel = math.min(100, _fuel + 24);
        if (_scenario.label == 'Safety Car Window' ||
            _scenario.rainChance > 58) {
          positionChange = 1;
          nextMessage = 'Perfect pit call. Cheap stop and fresh grip paid off.';
        } else {
          positionChange = -1;
          nextMessage =
              'Pit stop cost track position, but the car feels fresh.';
        }
      case _StrategyChoice.conserve:
        nextWear = math.max(0, _tireWear - 6);
        nextFuel -= 10;
        if (_scenario.label == 'Rain Threat' || _tireWear > 70 || _fuel < 24) {
          positionChange = 1;
          nextMessage =
              'Smart management. Others faded while you stayed clean.';
        } else if (_scenario.pressure > 36) {
          positionChange = -1;
          nextMessage = 'Too cautious. Rivals attacked while you held back.';
        } else {
          positionChange = 0;
          nextMessage = 'Steady lap. You kept the race under control.';
        }
    }

    nextWear = nextWear.clamp(0.0, 100.0);
    nextFuel = nextFuel.clamp(0.0, 100.0);
    nextWeather = (nextWeather * 0.4) + (_scenario.rainChance * 0.6);

    if (nextFuel <= 0) {
      await _finish('You ran out of fuel before the final laps.');
      return;
    }
    if (nextWear >= 100) {
      await _finish('Tires were finished. The car dropped off completely.');
      return;
    }

    final nextPosition = (_position - positionChange).clamp(1, 12);
    if (_lap >= _totalLaps) {
      await _finish(
        nextPosition <= 3
            ? 'Race complete. Brilliant strategy call sequence brought home P$nextPosition.'
            : 'Race complete. You finished P$nextPosition after a mixed strategy run.',
      );
      return;
    }

    setState(() {
      _lap += 1;
      _position = nextPosition;
      _tireWear = nextWear;
      _fuel = nextFuel;
      _weatherRisk = nextWeather;
      _scenario = _nextScenario();
      _message = nextMessage;
    });
  }

  Future<void> _finish(String reason) async {
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _message = reason;
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = [Color(0xff14b8a6), Color(0xff0ea5e9)];
    return GameScaffold(
      title: 'Race Strategist',
      subtitle:
          'Call the race from the pit wall and beat rivals with smarter decisions.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Lap',
            leftValue: '$_lap/$_totalLaps',
            rightLabel: 'Position',
            rightValue: 'P$_position',
            footer:
                'Tires ${_tireWear.round()}% • Fuel ${_fuel.round()}% • Rain ${_weatherRisk.round()}%',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(
                                0xff0ea5e9,
                              ).withValues(alpha: 0.18),
                            ),
                            child: Text(
                              _scenario.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Pressure ${_scenario.pressure.round()}',
                            style: const TextStyle(color: Color(0xffcbd5e1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _scenario.detail,
                        style: const TextStyle(
                          color: Color(0xffe2e8f0),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MetricBar(
                        label: 'Tire Wear',
                        value: _tireWear / 100,
                        color: const Color(0xfff97316),
                      ),
                      const SizedBox(height: 10),
                      _MetricBar(
                        label: 'Fuel Load',
                        value: _fuel / 100,
                        color: const Color(0xff22c55e),
                      ),
                      const SizedBox(height: 10),
                      _MetricBar(
                        label: 'Rain Risk',
                        value: _scenario.rainChance / 100,
                        color: const Color(0xff38bdf8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 150,
                      child: _StrategyTile(
                        title: 'Push',
                        subtitle: 'Attack hard for position',
                        icon: Icons.rocket_launch_rounded,
                        color: const Color(0xffef4444),
                        onTap: _running
                            ? () => _choose(_StrategyChoice.push)
                            : null,
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _StrategyTile(
                        title: 'Pit',
                        subtitle: 'Fresh tires and fuel',
                        icon: Icons.build_rounded,
                        color: const Color(0xfff59e0b),
                        onTap: _running
                            ? () => _choose(_StrategyChoice.pit)
                            : null,
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _StrategyTile(
                        title: 'Conserve',
                        subtitle: 'Protect tires and fuel',
                        icon: Icons.tune_rounded,
                        color: const Color(0xff22c55e),
                        onTap: _running
                            ? () => _choose(_StrategyChoice.conserve)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _running ? null : _start,
                    child: Text(
                      _finished ? 'Plan another race' : 'Start strategy race',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _palette = <Color>[
  Color(0xff38bdf8),
  Color(0xfff97316),
  Color(0xfffacc15),
  Color(0xff34d399),
  Color(0xffa855f7),
];

class _LaneRaceShell extends StatelessWidget {
  const _LaneRaceShell({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.footer,
    required this.message,
    required this.running,
    required this.finished,
    required this.dashOffset,
    required this.laneCount,
    required this.trackHeight,
    required this.playerLane,
    required this.rivals,
    required this.playerCar,
    required this.onLeft,
    required this.onRight,
    required this.onStart,
    this.drawGateWalls = false,
    this.gateSafeLanes = const <_SlalomGate>[],
  });

  final String title;
  final String subtitle;
  final List<Color> accent;
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final String footer;
  final String message;
  final bool running;
  final bool finished;
  final double dashOffset;
  final int laneCount;
  final double trackHeight;
  final int playerLane;
  final List<_LaneCar> rivals;
  final Widget playerCar;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onStart;
  final bool drawGateWalls;
  final List<_SlalomGate> gateSafeLanes;

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: title,
      subtitle: subtitle,
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: leftLabel,
            leftValue: leftValue,
            rightLabel: rightLabel,
            rightValue: rightValue,
            footer: footer,
          ),
          const SizedBox(height: 18),
          StatusCard(message: message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final laneWidth = constraints.maxWidth / laneCount;
                final playerTop = trackHeight - 66 - 16;
                return Column(
                  children: [
                    Container(
                      height: trackHeight,
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
                              painter: _LaneRoadPainter(
                                laneCount: laneCount,
                                dashOffset: dashOffset,
                              ),
                            ),
                          ),
                          if (drawGateWalls)
                            for (final gate in gateSafeLanes)
                              for (var lane = 0; lane < laneCount; lane++)
                                if (lane != gate.safeLane)
                                  Positioned(
                                    left:
                                        lane * laneWidth + (laneWidth - 24) / 2,
                                    top: gate.y,
                                    child: Container(
                                      width: 24,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xfff59e0b),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                          for (final rival in rivals)
                            Positioned(
                              left:
                                  rival.lane * laneWidth + (laneWidth - 34) / 2,
                              top: rival.y,
                              child: _CarVisual(color: rival.color),
                            ),
                          Positioned(
                            left: playerLane * laneWidth + (laneWidth - 38) / 2,
                            top: playerTop,
                            child: playerCar,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _TapTile(
                            icon: Icons.keyboard_double_arrow_left_rounded,
                            label: 'Left',
                            onTap: onLeft,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TapTile(
                            icon: Icons.play_arrow_rounded,
                            label: running
                                ? 'Live'
                                : finished
                                ? 'Again'
                                : 'Start',
                            onTap: running ? null : onStart,
                            accent: accent.last,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TapTile(
                            icon: Icons.keyboard_double_arrow_right_rounded,
                            label: 'Right',
                            onTap: onRight,
                          ),
                        ),
                      ],
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

class _LaneCar {
  const _LaneCar({required this.lane, required this.y, required this.color});

  final int lane;
  final double y;
  final Color color;

  _LaneCar copyWith({int? lane, double? y, Color? color}) {
    return _LaneCar(
      lane: lane ?? this.lane,
      y: y ?? this.y,
      color: color ?? this.color,
    );
  }
}

class _RoadBlock {
  const _RoadBlock({required this.lane, required this.y, required this.police});

  final int lane;
  final double y;
  final bool police;

  _RoadBlock copyWith({int? lane, double? y, bool? police}) {
    return _RoadBlock(
      lane: lane ?? this.lane,
      y: y ?? this.y,
      police: police ?? this.police,
    );
  }
}

class _SlalomGate {
  const _SlalomGate({required this.y, required this.safeLane});

  final double y;
  final int safeLane;

  _SlalomGate copyWith({double? y, int? safeLane}) {
    return _SlalomGate(y: y ?? this.y, safeLane: safeLane ?? this.safeLane);
  }
}

class _PitAction {
  const _PitAction(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class _StrategyScenario {
  const _StrategyScenario({
    required this.label,
    required this.detail,
    required this.pressure,
    required this.rainChance,
  });

  final String label;
  final String detail;
  final double pressure;
  final double rainChance;
}

enum _StrategyChoice { push, pit, conserve }

class _TapTile extends StatelessWidget {
  const _TapTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = const Color(0xff38bdf8),
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: enabled
              ? accent.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: enabled
                ? accent.withValues(alpha: 0.34)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
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

class _HoldTile extends StatelessWidget {
  const _HoldTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onChanged(true),
      onTapUp: (_) => onChanged(false),
      onTapCancel: () => onChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withValues(alpha: active ? 0.24 : 0.14),
          border: Border.all(
            color: color.withValues(alpha: active ? 0.7 : 0.34),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.highlighted,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withValues(alpha: highlighted ? 0.28 : 0.14),
          border: Border.all(
            color: color.withValues(alpha: highlighted ? 0.78 : 0.34),
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
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

class _StrategyTile extends StatelessWidget {
  const _StrategyTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: enabled
              ? color.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.34)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: enabled ? Colors.white : const Color(0xff64748b)),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: enabled ? Colors.white : const Color(0xff64748b),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: enabled
                    ? const Color(0xffcbd5e1)
                    : const Color(0xff64748b),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xffcbd5e1),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SpeedDial extends StatelessWidget {
  const _SpeedDial({required this.speed, required this.min, required this.max});

  final double speed;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final safeCenter = ((min + max) / 2) / 140;
    final needle = (speed / 140).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 12,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: (safeCenter * 2.2) - 1.1,
                  child: Container(
                    width: 8,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xff22c55e).withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: (needle * 2.2) - 1.1,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 4,
                      height: 82,
                      decoration: BoxDecoration(
                        color: const Color(0xfff97316),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${speed.round()} km/h',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarVisual extends StatelessWidget {
  const _CarVisual({required this.color, this.glow = const Color(0x00000000)});

  final Color color;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: glow.a == 0.0
            ? const []
            : [
                BoxShadow(
                  color: glow.withValues(alpha: 0.42),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.2), color],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            top: 10,
            height: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xffdbeafe).withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(8),
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
    );
  }
}

class _LaneRoadPainter extends CustomPainter {
  const _LaneRoadPainter({required this.laneCount, required this.dashOffset});

  final int laneCount;
  final double dashOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final shoulderPaint = Paint()
      ..color = const Color(0xffef4444).withValues(alpha: 0.22);
    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..strokeWidth = 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, 10, size.height), shoulderPaint);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 10, 0, 10, size.height),
      shoulderPaint,
    );
    final laneWidth = size.width / laneCount;
    for (var lane = 1; lane < laneCount; lane++) {
      final x = laneWidth * lane;
      for (double y = -48 + dashOffset; y < size.height + 48; y += 48) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 22), lanePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LaneRoadPainter oldDelegate) {
    return oldDelegate.dashOffset != dashOffset ||
        oldDelegate.laneCount != laneCount;
  }
}
