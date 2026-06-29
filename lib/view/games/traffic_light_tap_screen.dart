import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class TrafficLightTapScreen extends StatefulWidget {
  const TrafficLightTapScreen({super.key});

  @override
  State<TrafficLightTapScreen> createState() => _TrafficLightTapScreenState();
}

class _TrafficLightTapScreenState extends State<TrafficLightTapScreen> {
  final Random _random = Random();
  Timer? _timer;

  int _round = 1;
  int _score = 0;
  int _lives = 3;
  bool _showGreen = false;
  String _message = 'Wait for green, then tap GO before the light changes.';

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

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _showGreen = false;
      _message = 'Round $nextRound: hold steady and tap only on green.';
    });

    final reduction = nextRound * 35;
    final waitMs = max(
      450,
      900 + _random.nextInt(1800) - (reduction > 500 ? 500 : reduction),
    );
    _timer = Timer(Duration(milliseconds: waitMs), () {
      if (!mounted || _lives == 0) return;
      setState(() {
        _showGreen = true;
        _message = 'GREEN! Tap GO now.';
      });
      _timer = Timer(const Duration(milliseconds: 850), () {
        if (!mounted || _lives == 0 || !_showGreen) return;
        _missGreen();
      });
    });
  }

  Future<void> _tapGo() async {
    if (_lives == 0) return;

    if (_showGreen) {
      _timer?.cancel();
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _showGreen = false;
        _message = 'Perfect launch. Next light is coming.';
      });
      _startRound();
      return;
    }

    await _loseLife('Jump start. You tapped before the green light.');
  }

  Future<void> _missGreen() async {
    await _loseLife('Too slow. The green light window is gone.');
  }

  Future<void> _loseLife(String message) async {
    _timer?.cancel();
    final nextLives = _lives - 1;
    if (nextLives <= 0) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _lives = 0;
        _showGreen = false;
        _message = '$message Tap reset to try again.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _showGreen = false;
      _message = '$message Lives left: $nextLives.';
    });
    _startRound();
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  Color _lightColor(bool active, Color color) =>
      active ? color : color.withValues(alpha: 0.18);

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xfff97316), Color(0xff22c55e)];
    return GameScaffold(
      title: 'Traffic Light Tap',
      subtitle: 'React to the green light fast, but never jump the start.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Reflex arcade challenge',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                Container(
                  width: 120,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      _TrafficLamp(
                        color: _lightColor(
                          !_showGreen,
                          const Color(0xffef4444),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TrafficLamp(
                        color: _lightColor(false, const Color(0xfffacc15)),
                      ),
                      const SizedBox(height: 12),
                      _TrafficLamp(
                        color: _lightColor(_showGreen, const Color(0xff22c55e)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _lives == 0 ? null : _tapGo,
                    icon: const Icon(Icons.touch_app_rounded),
                    label: const Text('GO'),
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

class _TrafficLamp extends StatelessWidget {
  const _TrafficLamp({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16),
        ],
      ),
    );
  }
}
