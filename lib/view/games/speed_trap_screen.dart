import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class SpeedTrapScreen extends StatefulWidget {
  const SpeedTrapScreen({super.key});

  @override
  State<SpeedTrapScreen> createState() => _SpeedTrapScreenState();
}

class _SpeedTrapScreenState extends State<SpeedTrapScreen> {
  final Random _random = Random();
  Timer? _timer;

  double _speed = 0;
  double _direction = 1;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  int _targetMin = 70;
  int _targetMax = 95;
  String _message = 'Brake at the right moment and stop inside the safe zone.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound({bool resetGame = false}) {
    _timer?.cancel();
    final nextRound = resetGame ? 1 : _round;
    final minTarget = 55 + _random.nextInt(55);
    final width = max(14, 28 - nextRound);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _targetMin = minTarget;
      _targetMax = min(160, minTarget + width);
      _speed = 0;
      _direction = 1;
      _message = 'Round $nextRound: brake inside $_targetMin-$_targetMax km/h.';
    });

    _timer = Timer.periodic(const Duration(milliseconds: 28), (timer) {
      if (!mounted || _lives == 0) return;
      setState(() {
        _speed += _direction * (2.8 + (nextRound * 0.15));
        if (_speed >= 180) {
          _speed = 180;
          _direction = -1;
        } else if (_speed <= 0) {
          _speed = 0;
          _direction = 1;
        }
      });
    });
  }

  Future<void> _brake() async {
    if (_lives == 0) return;
    _timer?.cancel();
    final currentSpeed = _speed.round();
    final inZone = currentSpeed >= _targetMin && currentSpeed <= _targetMax;

    if (inZone) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = 'Perfect stop at $currentSpeed km/h.';
      });
      _startRound();
      return;
    }

    final nextLives = _lives - 1;
    if (nextLives <= 0) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _lives = 0;
        _message =
            'Stopped at $currentSpeed km/h. Game over. Tap reset to race again.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          'Stopped at $currentSpeed km/h. Safe zone was $_targetMin-$_targetMax. Lives left: $nextLives.';
    });
    _startRound();
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xfffb7185), Color(0xfff97316)];
    final progress = (_speed / 180).clamp(0.0, 1.0);
    final safeStart = (_targetMin / 180).clamp(0.0, 1.0);
    final safeEnd = (_targetMax / 180).clamp(0.0, 1.0);

    return GameScaffold(
      title: 'Speed Trap',
      subtitle:
          'Brake at the right moment and stop inside the safe speed zone.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Speed: ${_speed.round()} km/h',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speed meter',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return Stack(
                      children: [
                        Container(
                          height: 26,
                          width: width,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Positioned(
                          left: width * safeStart,
                          child: Container(
                            height: 26,
                            width: width * (safeEnd - safeStart),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xff22c55e,
                              ).withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        Positioned(
                          left: max(0, (width * progress) - 8),
                          top: -7,
                          child: Container(
                            height: 40,
                            width: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Safe zone: $_targetMin-$_targetMax km/h',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xffcbd5e1),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _lives == 0 ? null : _brake,
                    icon: const Icon(Icons.directions_car_filled_rounded),
                    label: const Text('Brake Now'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset game', onPressed: _resetGame),
        ],
      ),
    );
  }
}
