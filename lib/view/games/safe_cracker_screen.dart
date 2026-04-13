import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class SafeCrackerScreen extends StatefulWidget {
  const SafeCrackerScreen({super.key});

  @override
  State<SafeCrackerScreen> createState() => _SafeCrackerScreenState();
}

class _SafeCrackerScreenState extends State<SafeCrackerScreen> {
  final Random _random = Random();

  late List<int> _secretCode;
  final List<int> _currentGuess = [];
  int _round = 1;
  int _attemptsLeft = 7;
  int _bestRound = 1;
  String _message = 'Build the 3-number code and crack the safe.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  void _startRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final codeLength = min(3 + ((nextRound - 1) ~/ 3), 4);
    final nextCode = List<int>.generate(
      codeLength,
      (_) => _random.nextInt(9) + 1,
    );

    setState(() {
      if (resetGame) {
        _round = 1;
        _bestRound = 1;
      }
      _secretCode = nextCode;
      _currentGuess.clear();
      _attemptsLeft = 7;
      _message = 'Round $nextRound: crack the ${nextCode.length}-digit code.';
    });
  }

  void _tapDigit(int value) {
    if (_attemptsLeft == 0 || _currentGuess.length == _secretCode.length) {
      return;
    }
    setState(() {
      _currentGuess.add(value);
    });
  }

  void _clearGuess() {
    if (_currentGuess.isEmpty || _attemptsLeft == 0) return;
    setState(() {
      _currentGuess.removeLast();
    });
  }

  Future<void> _submitGuess() async {
    if (_currentGuess.length != _secretCode.length || _attemptsLeft == 0) {
      return;
    }

    var exactMatches = 0;
    for (var i = 0; i < _secretCode.length; i++) {
      if (_currentGuess[i] == _secretCode[i]) {
        exactMatches += 1;
      }
    }

    if (exactMatches == _secretCode.length) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _round += 1;
        if (_round > _bestRound) {
          _bestRound = _round;
        }
      });
      _startRound();
      return;
    }

    final partialMatches = _countPartialMatches();
    final nextAttempts = _attemptsLeft - 1;
    if (nextAttempts <= 0) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _attemptsLeft = 0;
        _message =
            'Safe locked. Code was ${_secretCode.join('-')}. Tap reset to try again.';
        _currentGuess.clear();
      });
      return;
    }

    setState(() {
      _attemptsLeft = nextAttempts;
      _message =
          'Close. Exact: $exactMatches, misplaced: $partialMatches. $nextAttempts tries left.';
      _currentGuess.clear();
    });
  }

  int _countPartialMatches() {
    final secretCounts = <int, int>{};
    final guessCounts = <int, int>{};

    for (var i = 0; i < _secretCode.length; i++) {
      if (_currentGuess[i] == _secretCode[i]) continue;
      secretCounts[_secretCode[i]] = (secretCounts[_secretCode[i]] ?? 0) + 1;
      guessCounts[_currentGuess[i]] = (guessCounts[_currentGuess[i]] ?? 0) + 1;
    }

    var partial = 0;
    for (final entry in guessCounts.entries) {
      partial += min(entry.value, secretCounts[entry.key] ?? 0);
    }
    return partial;
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff0ea5e9), Color(0xff2563eb)];
    return GameScaffold(
      title: 'Safe Cracker',
      subtitle: 'Guess the code using exact and misplaced digit hints.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Best',
            rightValue: _bestRound.toString(),
            footer: 'Attempts left: $_attemptsLeft',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current guess',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_secretCode.length, (index) {
                    final hasValue = index < _currentGuess.length;
                    return Container(
                      height: 58,
                      width: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        hasValue ? _currentGuess[index].toString() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(9, (index) {
                    final value = index + 1;
                    return SizedBox(
                      width: 78,
                      child: ElevatedButton(
                        onPressed: () => _tapDigit(value),
                        child: Text(value.toString()),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentGuess.isEmpty ? null : _clearGuess,
                        child: const Text('Undo'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentGuess.length == _secretCode.length
                            ? _submitGuess
                            : null,
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
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
