import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class QuickSortScreen extends StatefulWidget {
  const QuickSortScreen({super.key});

  @override
  State<QuickSortScreen> createState() => _QuickSortScreenState();
}

class _QuickSortScreenState extends State<QuickSortScreen> {
  final Random _random = Random();

  late List<int> _numbers;
  final List<int> _picked = [];
  int _round = 1;
  int _score = 0;
  int _mistakesLeft = 3;
  String _message = 'Tap the numbers from lowest to highest.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  int get _count => min(4 + (_round - 1), 8);

  void _startRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final values = <int>{};
    while (values.length < min(4 + (nextRound - 1), 8)) {
      values.add(_random.nextInt(50) + 1);
    }
    final nextNumbers = values.toList()..shuffle(_random);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _mistakesLeft = 3;
      }
      _numbers = nextNumbers;
      _picked.clear();
      _message = 'Round $nextRound: sort ${nextNumbers.length} numbers.';
    });
  }

  Future<void> _pickNumber(int value) async {
    if (_mistakesLeft == 0 || _picked.contains(value)) return;

    final remaining = _numbers
        .where((item) => !_picked.contains(item))
        .toList();
    final expected = remaining.reduce(min);
    if (value != expected) {
      final nextMistakes = _mistakesLeft - 1;
      if (nextMistakes <= 0) {
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        if (!mounted) return;
        setState(() {
          _mistakesLeft = 0;
          _message = 'Wrong pick. Game over. Tap reset to try again.';
        });
        return;
      }

      setState(() {
        _mistakesLeft = nextMistakes;
        _message = 'Wrong. Smallest remaining number is $expected.';
      });
      return;
    }

    final updatedPicked = [..._picked, value];
    if (updatedPicked.length == _numbers.length) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _picked
          ..clear()
          ..addAll(updatedPicked);
        _score += 1;
        _round += 1;
      });
      _startRound();
      return;
    }

    setState(() {
      _picked
        ..clear()
        ..addAll(updatedPicked);
      _message = 'Nice. Keep sorting upward.';
    });
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff06b6d4), Color(0xff3b82f6)];
    return GameScaffold(
      title: 'Quick Sort',
      subtitle: 'Pick numbers in ascending order before mistakes run out.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Mistakes left: $_mistakesLeft • Count: $_count',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _numbers
                  .map(
                    (value) => SizedBox(
                      width: 88,
                      child: ElevatedButton(
                        onPressed: _picked.contains(value)
                            ? null
                            : () => _pickNumber(value),
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: const Color(
                            0xff22c55e,
                          ).withValues(alpha: 0.22),
                        ),
                        child: Text(_picked.contains(value) ? 'OK' : '$value'),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset game', onPressed: _resetGame),
        ],
      ),
    );
  }
}
