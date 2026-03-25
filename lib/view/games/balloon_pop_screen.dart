import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class BalloonPopScreen extends StatefulWidget {
  const BalloonPopScreen({super.key});

  @override
  State<BalloonPopScreen> createState() => _BalloonPopScreenState();
}

class _BalloonPopScreenState extends State<BalloonPopScreen> {
  static const int _cellCount = 9;

  final Random _random = Random();

  Timer? _timer;
  int _level = 1;
  int _score = 0;
  int _bestScore = 0;
  int _timeLeft = 20;
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

  int get _levelSeconds => max(8, 20 - ((_level - 1) * 2));
  int get _targetScore => 8 + ((_level - 1) * 3);

  void _startRound() {
    _timer?.cancel();
    setState(() {
      _score = 0;
      _timeLeft = _levelSeconds;
      _running = true;
      _message = 'Level $_level: pop $_targetScore balloons.';
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
              : 'Time up. You popped $_score balloons.';
        });
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
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
    final nextScore = _score + 1;
    final isBest = nextScore > _bestScore;
    if (nextScore >= _targetScore) {
      _timer?.cancel();
      setState(() {
        _score = nextScore;
        _running = false;
        _level += 1;
        if (isBest) {
          _bestScore = nextScore;
        }
        _message = 'Level clear. Level $_level is ready.';
        _activeCells = _randomCells();
      });
      if (isBest) {
        GameStatsStore.instance.recordBalloonPopBestScore(nextScore);
      }
      GameInterstitialService.instance.registerRoundCompletion();
      GameInterstitialService.instance.maybeShow();
      return;
    }

    setState(() {
      _score = nextScore;
      _activeCells = _randomCells();
      _message = 'Nice pop. ${_targetScore - nextScore} to go.';
    });
  }

  void _resetGame() {
    _timer?.cancel();
    setState(() {
      _level = 1;
      _score = 0;
      _timeLeft = _levelSeconds;
      _running = false;
      _activeCells = _randomCells();
      _message = 'Pop the bright balloons before time runs out.';
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
            leftLabel: 'Level',
            leftValue: _level.toString(),
            rightLabel: 'Best',
            rightValue: _bestScore.toString(),
            footer: 'Score $_score/$_targetScore • Time left: ${_timeLeft}s',
          ),
          StatusCard(message: _message, accent: const Color(0xfffb7185)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _running ? null : _startRound,
              child: Text(_running ? 'Round running...' : 'Start level'),
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset levels', onPressed: _resetGame),
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
        ],
      ),
    );
  }
}
