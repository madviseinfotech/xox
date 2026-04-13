import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class FlashCountScreen extends StatefulWidget {
  const FlashCountScreen({super.key});

  @override
  State<FlashCountScreen> createState() => _FlashCountScreenState();
}

class _FlashCountScreenState extends State<FlashCountScreen> {
  final Random _random = Random();

  Timer? _hideTimer;
  late int _answerCount;
  late List<int> _options;
  bool _showPreview = true;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  String _message = 'Count the flash, then choose the correct number.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startRound({bool resetGame = false}) {
    _hideTimer?.cancel();
    final nextRound = resetGame ? 1 : _round;
    final answerCount = min(3 + nextRound, 9);
    final options = <int>{answerCount};
    while (options.length < 4) {
      final delta = _random.nextInt(5) - 2;
      final guess = (answerCount + delta).clamp(1, 12);
      options.add(guess);
    }
    final shuffledOptions = options.toList()..shuffle(_random);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _answerCount = answerCount;
      _options = shuffledOptions;
      _showPreview = true;
      _message = 'Memorize the count before it disappears.';
    });

    _hideTimer = Timer(Duration(milliseconds: 1400 + (nextRound * 120)), () {
      if (!mounted) return;
      setState(() {
        _showPreview = false;
        _message = 'How many stars flashed on the screen?';
      });
    });
  }

  Future<void> _pickAnswer(int value) async {
    if (_lives == 0 || _showPreview) return;
    if (value == _answerCount) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
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
        _message = 'Wrong answer. Game over. Tap reset to play again.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          'Not quite. $_answerCount was correct. Lives left: $nextLives.';
    });
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff8b5cf6), Color(0xffec4899)];
    return GameScaffold(
      title: 'Flash Count',
      subtitle: 'Watch the quick star flash and remember the exact count.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Max shown: $_answerCount',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 180,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _showPreview
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: _showPreview
                      ? Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: List<Widget>.generate(
                            _answerCount,
                            (_) => const Icon(
                              Icons.star_rounded,
                              color: Color(0xfffde047),
                              size: 28,
                            ),
                          ),
                        )
                      : Text(
                          '?',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _options
                      .map(
                        (option) => SizedBox(
                          width: 80,
                          child: ElevatedButton(
                            onPressed: _showPreview || _lives == 0
                                ? null
                                : () => _pickAnswer(option),
                            child: Text('$option'),
                          ),
                        ),
                      )
                      .toList(growable: false),
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
