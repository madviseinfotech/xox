import 'dart:async';

import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class QuickTapScreen extends StatefulWidget {
  const QuickTapScreen({super.key});

  @override
  State<QuickTapScreen> createState() => _QuickTapScreenState();
}

class _QuickTapScreenState extends State<QuickTapScreen> {
  static const int _roundSeconds = 10;

  Timer? _timer;
  int _timeLeft = _roundSeconds;
  int _score = 0;
  int _bestScore = 0;
  bool _running = false;
  String _message = 'Tap start, then hit the pulse as fast as you can.';

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
    setState(() {
      _bestScore = snapshot.quickTapBestScore;
    });
  }

  void _startRound() {
    _timer?.cancel();
    setState(() {
      _running = true;
      _timeLeft = _roundSeconds;
      _score = 0;
      _message = 'Go. Tap fast before the timer ends.';
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      if (_timeLeft <= 1) {
        timer.cancel();
        final newBest = _score > _bestScore;
        if (newBest) {
          _bestScore = _score;
          await GameStatsStore.instance.recordQuickTapBestScore(_score);
        }
        setState(() {
          _running = false;
          _timeLeft = 0;
          _message = newBest
              ? 'New record. $_score taps in $_roundSeconds seconds.'
              : 'Round over. You landed $_score taps.';
        });
        return;
      }

      setState(() {
        _timeLeft -= 1;
      });
    });
  }

  void _tapPulse() {
    if (!_running) return;
    setState(() {
      _score += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Quick Tap',
      subtitle: 'A 10-second reflex sprint built for instant replay.',
      accent: const [Color(0xff14b8a6), Color(0xff0ea5e9)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Timer',
            leftValue: '${_timeLeft}s',
            rightLabel: 'Best',
            rightValue: _bestScore.toString(),
            footer: 'Tap the pulse as fast as possible while time is running.',
          ),
          StatusCard(message: _message, accent: const Color(0xff14b8a6)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _running ? null : _startRound,
              child: Text(_running ? 'Round running...' : 'Start round'),
            ),
          ),
          const SizedBox(height: 18),
          GamePanel(
            child: Center(
              child: GestureDetector(
                onTap: _tapPulse,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: _running ? 220 : 200,
                  width: _running ? 220 : 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xff67e8f9), Color(0xff0ea5e9)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff22d3ee).withValues(alpha: 0.34),
                        blurRadius: 28,
                        spreadRadius: _running ? 6 : 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Text(
                        _running ? _score.toString() : 'START',
                        key: ValueKey(_running ? 'score_$_score' : 'start'),
                        style: const TextStyle(
                          color: Color(0xff082f49),
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
