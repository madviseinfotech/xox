import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class BalloonPopScreen extends StatefulWidget {
  const BalloonPopScreen({super.key});

  @override
  State<BalloonPopScreen> createState() => _BalloonPopScreenState();
}

class _BalloonPopScreenState extends State<BalloonPopScreen> {
  static const int _roundSeconds = 20;
  static const int _cellCount = 9;

  final Random _random = Random();

  Timer? _timer;
  int _score = 0;
  int _bestScore = 0;
  int _timeLeft = _roundSeconds;
  String _message = 'Pop the bright balloons before time runs out.';
  bool _running = false;
  Set<int> _activeCells = {1, 5};

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestScore = snapshot.balloonPopBestScore;
    });
  }

  void _startRound() {
    _timer?.cancel();
    setState(() {
      _score = 0;
      _timeLeft = _roundSeconds;
      _running = true;
      _message = 'Go. Tap the balloons as fast as you can.';
      _activeCells = _randomCells();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      if (_timeLeft <= 1) {
        timer.cancel();
        final isBest = _score > _bestScore;
        if (isBest) {
          await GameStatsStore.instance.recordBalloonPopBestScore(_score);
        }
        if (!mounted) return;
        setState(() {
          _running = false;
          if (isBest) {
            _bestScore = _score;
          }
          _message = isBest
              ? 'New best. You popped $_score balloons.'
              : 'Round over. You popped $_score balloons.';
        });
        return;
      }
      setState(() {
        _timeLeft -= 1;
        _activeCells = _randomCells();
      });
    });
  }

  Set<int> _randomCells() {
    final count = _random.nextBool() ? 2 : 3;
    final selected = <int>{};
    while (selected.length < count) {
      selected.add(_random.nextInt(_cellCount));
    }
    return selected;
  }

  void _popBalloon(int index) {
    if (!_running || !_activeCells.contains(index)) return;
    setState(() {
      _score += 1;
      _activeCells = _randomCells();
      _message = 'Nice pop. Keep going.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Balloon Pop',
      subtitle: 'Bright balloons and quick taps for little arcade hands.',
      accent: const [Color(0xfffb7185), Color(0xfff59e0b)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Score',
            leftValue: _score.toString(),
            rightLabel: 'Best',
            rightValue: _bestScore.toString(),
            footer: 'Time left: ${_timeLeft}s',
          ),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final active = _activeCells.contains(index);
                return GestureDetector(
                  onTap: () => _popBalloon(index),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: active ? 1 : 0.92,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: active
                            ? (index.isEven
                                  ? const Color(0xffff8fab)
                                  : const Color(0xffffb703))
                            : Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: active
                              ? Colors.white.withValues(alpha: 0.28)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.celebration_rounded,
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xfffb7185)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _running ? null : _startRound,
              child: Text(_running ? 'Round running...' : 'Start round'),
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Play again', onPressed: _startRound),
        ],
      ),
    );
  }
}
