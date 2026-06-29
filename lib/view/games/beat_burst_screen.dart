import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class BeatBurstScreen extends StatefulWidget {
  const BeatBurstScreen({super.key});

  @override
  State<BeatBurstScreen> createState() => _BeatBurstScreenState();
}

class _BeatBurstScreenState extends State<BeatBurstScreen> {
  final Random _random = Random();
  Timer? _timer;

  int _activePad = 0;
  int _score = 0;
  int _lives = 3;
  double _timeLeft = 1.0;
  bool _running = false;
  String _message = 'Tap the glowing pad before the beat fades.';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _timer?.cancel();
    setState(() {
      _activePad = _random.nextInt(4);
      _score = 0;
      _lives = 3;
      _timeLeft = 1.0;
      _running = true;
      _message = 'Beat live. Hit the glowing pad fast.';
    });
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!_running || !mounted) return;
    final nextTime = _timeLeft - 0.06;
    if (nextTime > 0) {
      setState(() => _timeLeft = nextTime);
      return;
    }
    await _missBeat('Missed the beat.');
  }

  Future<void> _missBeat(String reason) async {
    final nextLives = _lives - 1;
    if (nextLives <= 0) {
      _timer?.cancel();
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _lives = 0;
        _running = false;
        _message = '$reason Game over with $_score clean hits.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _activePad = _random.nextInt(4);
      _timeLeft = 1.0;
      _message = '$reason Lives left: $nextLives.';
    });
  }

  void _tapPad(int index) {
    if (!_running) return;
    if (index != _activePad) {
      _missBeat('Wrong pad.');
      return;
    }

    setState(() {
      _score += 1;
      _activePad = _random.nextInt(4);
      _timeLeft = max(0.35, 1.0 - (_score * 0.03));
      _message = 'Nice hit. Tempo rising.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xfff97316), Color(0xffef4444)];
    return GameScaffold(
      title: 'Beat Burst',
      subtitle:
          'A fast offline reflex game built around one glowing target beat.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Hits',
            leftValue: _score.toString(),
            rightLabel: 'Lives',
            rightValue: _lives.toString(),
            footer: _running
                ? 'Beat meter: ${(_timeLeft * 100).round()}%'
                : 'Tap start to play',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _timeLeft,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(accent.last),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final active = _running && index == _activePad;
                    return ElevatedButton(
                      onPressed: _running ? () => _tapPad(index) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: active
                            ? accent.last
                            : Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: 0.08,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Icon(
                        Icons.music_note_rounded,
                        size: active ? 42 : 34,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _running ? null : _startGame,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start beat'),
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
