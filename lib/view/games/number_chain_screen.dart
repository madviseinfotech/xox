import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class NumberChainScreen extends StatefulWidget {
  const NumberChainScreen({super.key});

  @override
  State<NumberChainScreen> createState() => _NumberChainScreenState();
}

class _NumberChainScreenState extends State<NumberChainScreen> {
  final Random _random = Random();

  late List<int> _choices;
  int _currentValue = 0;
  int _targetValue = 0;
  int _round = 1;
  int _score = 0;
  int _movesLeft = 4;
  String _message = 'Reach the target number before you run out of moves.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  void _startRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final current = _random.nextInt(12) + 3;
    final target = current + 6 + _random.nextInt(8);
    final choices = {
      1 + _random.nextInt(4),
      2 + _random.nextInt(4),
      3 + _random.nextInt(4),
      4 + _random.nextInt(4),
    }.toList()..shuffle(_random);

    while (choices.length < 4) {
      final value = 1 + _random.nextInt(7);
      if (!choices.contains(value)) {
        choices.add(value);
      }
    }

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
      }
      _currentValue = current;
      _targetValue = target;
      _choices = choices;
      _movesLeft = 4 + min(nextRound - 1, 2);
      _message = 'Round $nextRound: use the steps to hit $target exactly.';
    });
  }

  Future<void> _pickStep(int value) async {
    if (_movesLeft == 0) return;

    final nextValue = _currentValue + value;
    final nextMoves = _movesLeft - 1;

    if (nextValue == _targetValue) {
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

    if (nextValue > _targetValue || nextMoves == 0) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _currentValue = nextValue;
        _movesLeft = nextMoves;
        _message =
            'Round lost. You reached $nextValue, target was $_targetValue. Tap reset or try next app launch.';
      });
      return;
    }

    setState(() {
      _currentValue = nextValue;
      _movesLeft = nextMoves;
      _message = 'Now at $nextValue. $_movesLeft moves left.';
    });
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xfff97316), Color(0xfffb7185)];
    return GameScaffold(
      title: 'Number Chain',
      subtitle: 'Add the right steps to land exactly on the target number.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Current: $_currentValue • Target: $_targetValue',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick your next step',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _choices
                      .map(
                        (choice) => SizedBox(
                          width: 88,
                          child: ElevatedButton(
                            onPressed: _movesLeft == 0
                                ? null
                                : () => _pickStep(choice),
                            child: Text('+$choice'),
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
