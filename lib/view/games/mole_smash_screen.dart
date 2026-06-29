import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class MoleSmashScreen extends StatefulWidget {
  const MoleSmashScreen({super.key});

  @override
  State<MoleSmashScreen> createState() => _MoleSmashScreenState();
}

class _MoleSmashScreenState extends State<MoleSmashScreen> {
  static const int _gridSize = 9;
  static const int _maxMisses = 5;

  final Random _random = Random();
  Timer? _timer;

  int _activeIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _misses = 0;
  int _bestScore = 0;
  bool _moleVisible = true;
  String _message = 'Tap the mole before it disappears.';

  @override
  void initState() {
    super.initState();
    _startGame(resetScore: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _gameOver => _misses >= _maxMisses;

  Duration get _roundDelay {
    final ms = max(380, 900 - (_score * 22));
    return Duration(milliseconds: ms);
  }

  void _startGame({bool resetScore = false}) {
    _timer?.cancel();
    setState(() {
      if (resetScore) {
        _score = 0;
        _streak = 0;
        _misses = 0;
        _message = 'Tap the mole before it disappears.';
      } else {
        _message = 'Stay sharp. The mole is speeding up.';
      }
      _spawnMole();
    });
    _timer = Timer.periodic(_roundDelay, (_) => _advanceRound());
  }

  void _spawnMole() {
    int nextIndex = _random.nextInt(_gridSize);
    if (_gridSize > 1 && nextIndex == _activeIndex) {
      nextIndex = (nextIndex + 1 + _random.nextInt(_gridSize - 1)) % _gridSize;
    }
    _activeIndex = nextIndex;
    _moleVisible = true;
  }

  Future<void> _advanceRound() async {
    if (!mounted || _gameOver) return;

    if (_moleVisible) {
      final nextMisses = _misses + 1;
      if (nextMisses >= _maxMisses) {
        _timer?.cancel();
        setState(() {
          _misses = nextMisses;
          _moleVisible = false;
          _streak = 0;
          _message =
              'Too slow. Final score: $_score. Tap reset to chase a better run.';
        });
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        return;
      }

      setState(() {
        _misses = nextMisses;
        _streak = 0;
        _message = 'Missed it. ${_maxMisses - nextMisses} misses left.';
        _spawnMole();
      });
      _restartTimer();
      return;
    }

    setState(() {
      _spawnMole();
      _message = 'New mole up. Tap fast.';
    });
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_gameOver) return;
    _timer = Timer.periodic(_roundDelay, (_) => _advanceRound());
  }

  Future<void> _tapHole(int index) async {
    if (_gameOver || !_moleVisible) return;

    if (index != _activeIndex) {
      final nextMisses = _misses + 1;
      if (nextMisses >= _maxMisses) {
        _timer?.cancel();
        setState(() {
          _misses = nextMisses;
          _moleVisible = false;
          _streak = 0;
          _message =
              'Wrong hole. Final score: $_score. Tap reset to play again.';
        });
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        return;
      }

      setState(() {
        _misses = nextMisses;
        _streak = 0;
        _message = 'Wrong hole. ${_maxMisses - nextMisses} misses left.';
      });
      return;
    }

    final nextScore = _score + 1;
    final nextStreak = _streak + 1;
    setState(() {
      _score = nextScore;
      _streak = nextStreak;
      _bestScore = max(_bestScore, nextScore);
      _moleVisible = false;
      _message = nextStreak >= 5
          ? 'Hot streak. $nextStreak hits in a row.'
          : 'Nice hit. Keep going.';
    });
    _restartTimer();
  }

  void _resetGame() {
    _startGame(resetScore: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff84cc16), Color(0xff22c55e)];
    return GameScaffold(
      title: 'Mole Smash',
      subtitle: 'Tap the mole before it disappears and avoid the wrong holes.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Score',
            leftValue: _score.toString(),
            rightLabel: 'Best',
            rightValue: _bestScore.toString(),
            footer: 'Streak: $_streak • Misses: $_misses/$_maxMisses',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _gridSize,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final isActive = _moleVisible && index == _activeIndex;
                return ElevatedButton(
                  onPressed: _gameOver ? null : () => _tapHole(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? const Color(0xffa3e635)
                        : const Color(0xff3f3f46),
                    foregroundColor: isActive
                        ? const Color(0xff14532d)
                        : const Color(0xffd4d4d8),
                    disabledBackgroundColor: isActive
                        ? const Color(0xffa3e635)
                        : const Color(0xff3f3f46),
                    disabledForegroundColor: const Color(0xffd4d4d8),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(
                        color: isActive
                            ? const Color(0xffdcfce7)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      isActive ? 'MOLE' : 'HOLE',
                      key: ValueKey('$index-$isActive'),
                      style: TextStyle(
                        fontSize: isActive ? 20 : 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset game', onPressed: _resetGame),
        ],
      ),
    );
  }
}
