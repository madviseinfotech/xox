import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class BalanceBeamScreen extends StatefulWidget {
  const BalanceBeamScreen({super.key});

  @override
  State<BalanceBeamScreen> createState() => _BalanceBeamScreenState();
}

class _BalanceBeamScreenState extends State<BalanceBeamScreen> {
  final Random _random = Random();

  late List<int> _weights;
  final Set<int> _usedIndexes = <int>{};
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  int _targetWeight = 12;
  int _currentWeight = 0;
  String _message = 'Build the exact target weight without going over.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  void _startRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final base = 2 + nextRound;
    final answer = [base, base + 1, base + 2]..shuffle(_random);
    final fillers = <int>[];
    while (fillers.length < 3) {
      final next = 2 + _random.nextInt(base + 5);
      if (answer.contains(next)) continue;
      fillers.add(next);
    }
    final weights = [...answer, ...fillers]..shuffle(_random);
    final targetWeight = answer.take(2).reduce((value, item) => value + item);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _weights = weights;
      _targetWeight = targetWeight;
      _currentWeight = 0;
      _usedIndexes.clear();
      _message = 'Reach exactly $_targetWeight kg. Going over costs a life.';
    });
  }

  Future<void> _pickWeight(int index) async {
    if (_lives == 0 || _usedIndexes.contains(index)) return;

    final nextWeight = _currentWeight + _weights[index];
    final nextUsed = {..._usedIndexes, index};
    if (nextWeight == _targetWeight) {
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

    if (nextWeight > _targetWeight) {
      final nextLives = _lives - 1;
      if (nextLives <= 0) {
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        if (!mounted) return;
        setState(() {
          _lives = 0;
          _message = 'Too heavy. Game over. Tap reset to try again.';
        });
        return;
      }

      setState(() {
        _lives = nextLives;
        _currentWeight = 0;
        _usedIndexes.clear();
        _message = 'Too heavy. Beam reset. Lives left: $nextLives.';
      });
      return;
    }

    if (nextUsed.length == _weights.length) {
      final nextLives = _lives - 1;
      if (nextLives <= 0) {
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        if (!mounted) return;
        setState(() {
          _lives = 0;
          _message = 'No weights left. Game over. Tap reset to try again.';
        });
        return;
      }

      setState(() {
        _lives = nextLives;
        _currentWeight = 0;
        _usedIndexes.clear();
        _message = 'No exact match this try. Lives left: $nextLives.';
      });
      return;
    }

    setState(() {
      _currentWeight = nextWeight;
      _usedIndexes
        ..clear()
        ..addAll(nextUsed);
      _message = 'Current weight: $nextWeight / $_targetWeight kg.';
    });
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff22c55e), Color(0xff16a34a)];
    return GameScaffold(
      title: 'Balance Beam',
      subtitle: 'Stack weights carefully and hit the exact target.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Target: $_targetWeight kg',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_currentWeight kg',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (_currentWeight / _targetWeight).clamp(0, 1),
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(accent.last),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List<Widget>.generate(_weights.length, (index) {
                    final used = _usedIndexes.contains(index);
                    return SizedBox(
                      width: 92,
                      child: ElevatedButton(
                        onPressed: used || _lives == 0
                            ? null
                            : () => _pickWeight(index),
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: const Color(
                            0xff22c55e,
                          ).withValues(alpha: 0.18),
                        ),
                        child: Text(used ? 'Used' : '${_weights[index]} kg'),
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
