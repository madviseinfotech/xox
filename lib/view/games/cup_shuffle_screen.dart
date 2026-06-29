import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class CupShuffleScreen extends StatefulWidget {
  const CupShuffleScreen({super.key});

  @override
  State<CupShuffleScreen> createState() => _CupShuffleScreenState();
}

class _CupShuffleScreenState extends State<CupShuffleScreen> {
  final Random _random = Random();

  List<int> _cups = [0, 1, 2];
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  bool _showBall = true;
  bool _isShuffling = false;
  String _message = 'Watch the glowing cup, then pick where the ball ends up.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  void _startRound({bool resetGame = false}) {
    if (resetGame) {
      _round = 1;
      _score = 0;
      _lives = 3;
    }

    _cups = [0, 1, 2]..shuffle(_random);
    _showBall = true;
    _isShuffling = false;
    _message = 'Track the ball before the cups shuffle.';
    setState(() {});

    Timer(const Duration(milliseconds: 900), () {
      if (!mounted || _lives == 0) return;
      _runShuffle();
    });
  }

  Future<void> _runShuffle() async {
    if (!mounted) return;
    setState(() {
      _showBall = false;
      _isShuffling = true;
      _message = 'Keep your eye on the hidden ball.';
    });

    final swaps = min(2 + _round, 8);
    for (var i = 0; i < swaps; i++) {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 360));
      final left = _random.nextInt(_cups.length);
      var right = _random.nextInt(_cups.length);
      while (right == left) {
        right = _random.nextInt(_cups.length);
      }
      setState(() {
        final next = List<int>.from(_cups);
        final temp = next[left];
        next[left] = next[right];
        next[right] = temp;
        _cups = next;
      });
    }

    if (!mounted) return;
    setState(() {
      _isShuffling = false;
      _message = 'Shuffle done. Pick the cup with the ball.';
    });
  }

  Future<void> _guessCup(int visualIndex) async {
    if (_showBall || _isShuffling || _lives == 0) return;
    final correct = _cups[visualIndex] == 0;

    setState(() {
      _showBall = true;
      if (correct) {
        _score += 1;
        _message = 'Nice catch. You followed the right cup.';
      } else {
        _lives -= 1;
        _message = _lives == 0
            ? 'Wrong cup. Game over.'
            : 'Wrong cup. $_lives lives left, try the next shuffle.';
      }
    });

    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted || _lives == 0) return;

    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    setState(() {
      _round += 1;
    });
    _startRound();
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff8b5cf6), Color(0xffec4899)];
    return GameScaffold(
      title: 'Cup Shuffle',
      subtitle: 'Follow the hidden ball through each shuffle and guess right.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Cups: 3',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where is the ball?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Watch the reveal, wait for the shuffle to finish, then tap the cup you think hides the ball.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xff94a3b8),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: List.generate(_cups.length, (index) {
                    final revealsBall = _showBall && _cups[index] == 0;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == _cups.length - 1 ? 0 : 12,
                        ),
                        child: InkWell(
                          onTap: () => _guessCup(index),
                          borderRadius: BorderRadius.circular(22),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: _isShuffling
                                    ? const Color(0xffc084fc)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              children: [
                                AnimatedSlide(
                                  duration: const Duration(milliseconds: 220),
                                  offset: revealsBall
                                      ? const Offset(0, -0.12)
                                      : Offset.zero,
                                  child: const Text(
                                    '🥤',
                                    style: TextStyle(fontSize: 54),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: revealsBall ? 1 : 0,
                                  child: const Text(
                                    '⚪',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Cup ${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
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
