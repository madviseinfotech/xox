import 'dart:async';
import 'dart:math' as math;


import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class FuelRushScreen extends StatefulWidget {
  const FuelRushScreen({super.key});

  @override
  State<FuelRushScreen> createState() => _FuelRushScreenState();
}

class _FuelRushScreenState extends State<FuelRushScreen> {
  static const int _totalLaps = 5;
  static const double _lapLength = 100.0;
  static const Duration _tick = Duration(milliseconds: 60);

  static const double _fullThrottleFuel = 0.55;
  static const double _coastFuel = 0.18;
  static const double _pitFuelRefill = 60.0;
  static const double _pitTimePenalty = 3.0; // seconds added to rival

  Timer? _timer;
  final Stopwatch _clock = Stopwatch();

  double _playerPos = 0;
  double _rivalPos = 0;
  double _fuel = 80.0;
  double _rivalFuel = 80.0;
  int _playerLap = 1;
  int _rivalLap = 1;
  int _bestLaps = 0;
  bool _throttle = false;
  bool _inPit = false;
  bool _running = false;
  bool _finished = false;
  String _message =
      'Hold Throttle to accelerate. Pit Stop refills fuel but costs time.';

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock.stop();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() => _bestLaps = snapshot.fuelRushBestLaps);
  }

  void _startRace() {
    _timer?.cancel();
    _clock
      ..stop()
      ..reset()
      ..start();
    setState(() {
      _playerPos = 0;
      _rivalPos = 0;
      _fuel = 80.0;
      _rivalFuel = 80.0;
      _playerLap = 1;
      _rivalLap = 1;
      _throttle = false;
      _inPit = false;
      _running = true;
      _finished = false;
      _message = 'Race started. Hold Throttle and watch your fuel.';
    });
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  void _onTick() {
    if (!_running || !mounted) return;

    // Player movement
    double playerSpeed = 0;
    double fuelBurn = 0;
    if (_inPit) {
      playerSpeed = 0;
      fuelBurn = 0;
    } else if (_throttle && _fuel > 0) {
      playerSpeed = 3.2;
      fuelBurn = _fullThrottleFuel;
    } else if (_fuel > 0) {
      playerSpeed = 1.4;
      fuelBurn = _coastFuel;
    } else {
      playerSpeed = 0.4; // crawling on empty
      fuelBurn = 0;
    }

    // Rival AI - manages fuel automatically
    double rivalSpeed = 0;
    if (_rivalFuel > 12) {
      rivalSpeed = 2.6 + math.sin(_clock.elapsedMilliseconds * 0.001) * 0.4;
      _rivalFuel -= _coastFuel * 1.1;
    } else {
      rivalSpeed = 0.5; // rival crawling on empty
    }

    final newPlayerPos = _playerPos + playerSpeed;
    final newRivalPos = _rivalPos + rivalSpeed;
    final newFuel = (_fuel - fuelBurn).clamp(0.0, 100.0);

    // Lap counting
    int newPlayerLap = _playerLap;
    double wrappedPlayerPos = newPlayerPos;
    if (newPlayerPos >= _lapLength) {
      newPlayerLap = _playerLap + 1;
      wrappedPlayerPos = newPlayerPos - _lapLength;
    }

    int newRivalLap = _rivalLap;
    double wrappedRivalPos = newRivalPos;
    if (newRivalPos >= _lapLength) {
      newRivalLap = _rivalLap + 1;
      wrappedRivalPos = newRivalPos - _lapLength;
    }

    // Check finish
    if (newPlayerLap > _totalLaps || newRivalLap > _totalLaps) {
      _finishRace(
        playerWon: newPlayerLap > newRivalLap ||
            (newPlayerLap == newRivalLap &&
                wrappedPlayerPos >= wrappedRivalPos),
        playerLaps: math.min(newPlayerLap - 1, _totalLaps),
      );
      return;
    }

    String msg = _message;
    if (newFuel <= 0 && !_inPit) {
      msg = 'Out of fuel! Crawling. Pit Stop to refuel.';
    } else if (newFuel < 20 && !_inPit) {
      msg = 'Fuel critical. Pit Stop soon or you will stall.';
    } else if (_throttle) {
      msg = 'Full throttle. Lap $_playerLap/$_totalLaps.';
    } else {
      msg = 'Coasting. Hold Throttle to push harder.';
    }

    setState(() {
      _playerPos = wrappedPlayerPos;
      _rivalPos = wrappedRivalPos;
      _fuel = newFuel;
      _rivalFuel = _rivalFuel.clamp(0.0, 100.0);
      _playerLap = newPlayerLap;
      _rivalLap = newRivalLap;
      _message = msg;
    });
  }

  void _pitStop() {
    if (!_running || _inPit || _finished) return;
    setState(() {
      _inPit = true;
      _fuel = math.min(100.0, _fuel + _pitFuelRefill);
      _rivalPos += _pitTimePenalty * 2.6; // rival gains distance during pit
      _message = 'Pit stop! Fuel refilled. Rejoining track...';
    });
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted || !_running) return;
      setState(() {
        _inPit = false;
        _message = 'Back on track. Push hard to recover lost ground.';
      });
    });
  }

  Future<void> _finishRace({
    required bool playerWon,
    required int playerLaps,
  }) async {
    _timer?.cancel();
    _clock.stop();
    if (playerLaps > _bestLaps) {
      await GameStatsStore.instance.recordFuelRushBestLaps(playerLaps);
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _finished = true;
      _throttle = false;
      if (playerLaps > _bestLaps) _bestLaps = playerLaps;
      _message = playerWon
          ? 'You won the race! $_totalLaps laps complete.'
          : 'Rival finished first. Manage fuel better next time.';
    });
    GameInterstitialService.instance.registerRoundCompletion();
    unawaited(GameInterstitialService.instance.maybeShow());
  }

  String get _lapTime {
    final ms = _clock.elapsedMilliseconds;
    final m = ms ~/ 60000;
    final s = ((ms % 60000) / 1000).toStringAsFixed(1);
    return '$m:${s.padLeft(4, '0')}';
  }

  Color _fuelColor(double fuel) {
    if (fuel > 40) return const Color(0xff22c55e);
    if (fuel > 20) return const Color(0xfff59e0b);
    return const Color(0xffef4444);
  }

  @override
  Widget build(BuildContext context) {
    const accent = [Color(0xffef4444), Color(0xfff59e0b)];
    final playerTrackFraction =
        ((_playerLap - 1) * _lapLength + _playerPos) /
        (_totalLaps * _lapLength);
    final rivalTrackFraction =
        ((_rivalLap - 1) * _lapLength + _rivalPos) /
        (_totalLaps * _lapLength);

    return GameScaffold(
      title: 'Fuel Rush',
      subtitle:
          'Race $_totalLaps laps, manage your fuel, and beat the rival to the finish.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Lap',
            leftValue: '$_playerLap / $_totalLaps',
            rightLabel: 'Best',
            rightValue: _bestLaps == 0 ? '--' : '$_bestLaps laps',
            footer: 'Time $_lapTime  •  Rival lap $_rivalLap',
          ),
          const SizedBox(height: 14),
          StatusCard(
            message: _message,
            accent: _finished
                ? (_message.startsWith('You won')
                      ? const Color(0xff22c55e)
                      : const Color(0xffef4444))
                : const Color(0xfff59e0b),
            highlight: _finished,
          ),
          const SizedBox(height: 14),
          GamePanel(
            child: Column(
              children: [
                _TrackBar(
                  label: 'You',
                  progress: playerTrackFraction.clamp(0.0, 1.0),
                  color: const Color(0xffef4444),
                  icon: Icons.directions_car_filled_rounded,
                  inPit: _inPit,
                ),
                const SizedBox(height: 12),
                _TrackBar(
                  label: 'Rival',
                  progress: rivalTrackFraction.clamp(0.0, 1.0),
                  color: const Color(0xff38bdf8),
                  icon: Icons.local_fire_department_rounded,
                  inPit: false,
                ),
                const SizedBox(height: 16),
                _FuelBar(
                  label: 'Your Fuel',
                  fuel: _fuel,
                  color: _fuelColor(_fuel),
                ),
                const SizedBox(height: 8),
                _FuelBar(
                  label: 'Rival Fuel',
                  fuel: _rivalFuel,
                  color: _fuelColor(_rivalFuel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _throttle = true),
                  onTapUp: (_) => setState(() => _throttle = false),
                  onTapCancel: () => setState(() => _throttle = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: _throttle
                            ? [const Color(0xffef4444), const Color(0xfff97316)]
                            : [
                                const Color(0xffef4444).withValues(alpha: 0.5),
                                const Color(0xfff97316).withValues(alpha: 0.5),
                              ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _throttle ? '🔥 THROTTLE' : 'Hold Throttle',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _running && !_inPit && !_finished
                      ? _pitStop
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xff0ea5e9),
                  ),
                  child: Text(
                    _inPit ? 'In Pit...' : '⛽ Pit Stop',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _running ? null : _startRace,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_finished ? 'Race Again' : 'Start Race'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackBar extends StatelessWidget {
  const _TrackBar({
    required this.label,
    required this.progress,
    required this.color,
    required this.icon,
    required this.inPit,
  });

  final String label;
  final double progress;
  final Color color;
  final IconData icon;
  final bool inPit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (inPit) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xff0ea5e9).withValues(alpha: 0.22),
                  border: Border.all(color: const Color(0xff0ea5e9)),
                ),
                child: const Text(
                  'PIT',
                  style: TextStyle(
                    color: Color(0xff0ea5e9),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final left = 6 + ((constraints.maxWidth - 48) * progress);
                  return Stack(
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 80),
                        curve: Curves.linear,
                        left: left.clamp(6.0, constraints.maxWidth - 42.0),
                        top: 6,
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: color,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FuelBar extends StatelessWidget {
  const _FuelBar({
    required this.label,
    required this.fuel,
    required this.color,
  });

  final String label;
  final double fuel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: (fuel / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${fuel.floor()}%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
