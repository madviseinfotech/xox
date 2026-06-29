import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class NitroSprintScreen extends StatefulWidget {
  const NitroSprintScreen({super.key});

  @override
  State<NitroSprintScreen> createState() => _NitroSprintScreenState();
}

class _NitroSprintScreenState extends State<NitroSprintScreen> {
  static const double _finishDistance = 400;
  static const Duration _tick = Duration(milliseconds: 50);

  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();

  double _playerDistance = 0;
  double _rivalDistance = 0;
  double _playerSpeed = 0;
  double _rivalSpeed = 0;
  double _needle = 0.12;
  double _nitro = 0;
  int _gear = 1;
  int _perfectShifts = 0;
  int _bestTimeMs = 0;
  bool _needleForward = true;
  bool _raceRunning = false;
  bool _countdownActive = false;
  bool _finished = false;
  bool _launched = false;
  bool _nitroUsed = false;
  String _message =
      'Tap Start Race, launch in the green zone, then shift gears.';

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestTimeMs = snapshot.nitroSprintBestTimeMs;
    });
  }

  String _formatTimeMs(int milliseconds) {
    final seconds = milliseconds / 1000;
    return '${seconds.toStringAsFixed(2)}s';
  }

  void _resetRace({bool keepMessage = false}) {
    _timer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _playerDistance = 0;
      _rivalDistance = 0;
      _playerSpeed = 0;
      _rivalSpeed = 0;
      _needle = 0.12;
      _nitro = 0;
      _gear = 1;
      _perfectShifts = 0;
      _needleForward = true;
      _raceRunning = false;
      _countdownActive = false;
      _finished = false;
      _launched = false;
      _nitroUsed = false;
      if (!keepMessage) {
        _message =
            'Tap Start Race, launch in the green zone, then shift gears.';
      }
    });
  }

  Future<void> _startRace() async {
    _resetRace(keepMessage: true);
    setState(() {
      _countdownActive = true;
      _message = 'Get ready... launch when the meter hits green.';
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _countdownActive = false;
      _raceRunning = true;
      _message = 'Launch now. Perfect start gives extra speed.';
    });
    _stopwatch.start();
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  void _onTick() {
    if (!_raceRunning || !mounted) return;

    final nextNeedle = _needleForward ? _needle + 0.055 : _needle - 0.055;
    if (nextNeedle >= 1) {
      _needle = 1;
      _needleForward = false;
    } else if (nextNeedle <= 0) {
      _needle = 0;
      _needleForward = true;
    } else {
      _needle = nextNeedle;
    }

    final gearCap = 44 + (_gear * 18);
    final baseAcceleration = _launched ? (1.2 + (_gear * 0.42)) : 0.0;
    final drag = _launched ? 0.42 : 0.0;
    _playerSpeed = math.max(
      0,
      math.min(gearCap.toDouble(), _playerSpeed + baseAcceleration - drag),
    );
    _rivalSpeed = math.min(102, _rivalSpeed + 1.38 - (_rivalSpeed * 0.012));
    _playerDistance += _playerSpeed * 0.16;
    _rivalDistance += _rivalSpeed * 0.16;
    _nitro = math.min(100, _nitro + (_launched ? 0.55 : 0.12));

    if (_playerDistance >= _finishDistance ||
        _rivalDistance >= _finishDistance) {
      _finishRace();
      return;
    }

    setState(() {
      if (!_launched) {
        _message = 'Launch in the green band for a perfect getaway.';
      } else if (_nitro >= 100 && !_nitroUsed) {
        _message = 'Nitro ready. Smash BOOST on the straight.';
      } else {
        _message = 'Shift cleanly to stay ahead of the rival car.';
      }
    });
  }

  bool _inPerfectZone() => _needle >= 0.44 && _needle <= 0.64;

  bool _inGoodZone() => _needle >= 0.34 && _needle <= 0.74;

  void _launchCar() {
    if (!_raceRunning || _launched || _finished) return;

    if (_inPerfectZone()) {
      setState(() {
        _launched = true;
        _playerSpeed = 34;
        _rivalSpeed = 22;
        _message = 'Perfect launch. You jumped the rival.';
      });
      return;
    }

    if (_inGoodZone()) {
      setState(() {
        _launched = true;
        _playerSpeed = 26;
        _rivalSpeed = 22;
        _message = 'Good launch. Keep the shifts tidy.';
      });
      return;
    }

    setState(() {
      _launched = true;
      _playerSpeed = 16;
      _rivalSpeed = 24;
      _message = 'Late launch. Recover with perfect shifts.';
    });
  }

  void _shiftGear() {
    if (!_raceRunning || !_launched || _finished || _gear >= 6) return;

    if (_inPerfectZone()) {
      setState(() {
        _gear += 1;
        _playerSpeed += 12;
        _perfectShifts += 1;
        _nitro = math.min(100, _nitro + 22);
        _message = 'Perfect shift. Car stays in the power band.';
      });
      return;
    }

    if (_inGoodZone()) {
      setState(() {
        _gear += 1;
        _playerSpeed += 6;
        _nitro = math.min(100, _nitro + 10);
        _message = 'Clean shift. Keep building speed.';
      });
      return;
    }

    setState(() {
      _gear += 1;
      _playerSpeed = math.max(10, _playerSpeed - 10);
      _message = 'Missed shift. You lost momentum.';
    });
  }

  void _useNitro() {
    if (!_raceRunning ||
        !_launched ||
        _finished ||
        _nitro < 100 ||
        _nitroUsed) {
      return;
    }
    setState(() {
      _nitroUsed = true;
      _nitro = 0;
      _playerSpeed += 24;
      _message = 'Nitro fired. Hold the lead to the line.';
    });
  }

  Future<void> _finishRace() async {
    _timer?.cancel();
    _stopwatch.stop();
    final playerWon =
        _playerDistance >= _finishDistance && _playerDistance >= _rivalDistance;
    final elapsedMs = _stopwatch.elapsedMilliseconds;

    if (playerWon) {
      await GameStatsStore.instance.recordNitroSprintBestTime(elapsedMs);
    }
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;

    setState(() {
      _raceRunning = false;
      _finished = true;
      if (playerWon && (_bestTimeMs == 0 || elapsedMs < _bestTimeMs)) {
        _bestTimeMs = elapsedMs;
      }
      _message = playerWon
          ? (_bestTimeMs == elapsedMs
                ? 'Win and new best time: ${_formatTimeMs(elapsedMs)}.'
                : 'Win in ${_formatTimeMs(elapsedMs)}. Strong run.')
          : 'Rival won this race. Reset and go again.';
    });
  }

  Widget _buildMeter({
    required String label,
    required double value,
    required Color color,
    String? trailing,
  }) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
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
            const Spacer(),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: clamped,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerProgress = (_playerDistance / _finishDistance).clamp(0.0, 1.0);
    final rivalProgress = (_rivalDistance / _finishDistance).clamp(0.0, 1.0);
    final needleLeft = (_needle * 100).clamp(0, 100).toDouble();

    return GameScaffold(
      title: 'Nitro Sprint',
      subtitle: 'Launch, shift, and boost your car to the finish line first.',
      accent: const [Color(0xfff97316), Color(0xffef4444)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Gear',
            leftValue: '$_gear/6',
            rightLabel: 'Best',
            rightValue: _bestTimeMs == 0 ? '--' : _formatTimeMs(_bestTimeMs),
            footer:
                'Perfect shifts $_perfectShifts • Nitro ${_nitro.floor()}% • Race ${_stopwatch.isRunning ? _formatTimeMs(_stopwatch.elapsedMilliseconds) : '--'}',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xffef4444)),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '400 m drag race',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _RaceLane(
                  label: 'Your car',
                  color: const Color(0xfff97316),
                  progress: playerProgress,
                  icon: Icons.directions_car_filled_rounded,
                  distanceLabel: '${_playerDistance.floor()} m',
                ),
                const SizedBox(height: 12),
                _RaceLane(
                  label: 'Rival',
                  color: const Color(0xff38bdf8),
                  progress: rivalProgress,
                  icon: Icons.local_fire_department_rounded,
                  distanceLabel: '${_rivalDistance.floor()} m',
                ),
                const SizedBox(height: 18),
                _buildMeter(
                  label: 'Shift meter',
                  value: _needle,
                  color: _inPerfectZone()
                      ? const Color(0xff22c55e)
                      : _inGoodZone()
                      ? const Color(0xfff59e0b)
                      : const Color(0xffef4444),
                  trailing: _launched ? 'Tap Shift in green' : 'Tap Launch',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 24,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        left: MediaQuery.of(context).size.width * 0.11,
                        right: MediaQuery.of(context).size.width * 0.11,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(
                              0xff22c55e,
                            ).withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: _tick,
                        curve: Curves.linear,
                        left: needleLeft * 2.4,
                        top: 2,
                        child: Container(
                          height: 20,
                          width: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildMeter(
                  label: 'Nitro',
                  value: _nitro / 100,
                  color: const Color(0xff38bdf8),
                  trailing: _nitroUsed ? 'Used' : 'Ready at 100%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _raceRunning
                      ? (_launched ? _shiftGear : _launchCar)
                      : (_countdownActive ? null : _startRace),
                  child: Text(
                    _raceRunning
                        ? (_launched ? 'Shift Gear' : 'Launch')
                        : (_countdownActive ? 'Ready...' : 'Start Race'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _raceRunning && !_countdownActive
                      ? _useNitro
                      : null,
                  child: const Text('Boost'),
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

class _RaceLane extends StatelessWidget {
  const _RaceLane({
    required this.label,
    required this.color,
    required this.progress,
    required this.icon,
    required this.distanceLabel,
  });

  final String label;
  final Color color;
  final double progress;
  final IconData icon;
  final String distanceLabel;

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
            const Spacer(),
            Text(
              distanceLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 12,
                top: 10,
                bottom: 10,
                child: Container(
                  width: 2,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final left = 8 + ((constraints.maxWidth - 52) * progress);
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 80),
                    curve: Curves.linear,
                    left: left,
                    top: 8,
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
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
