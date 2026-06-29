import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class ClockMatchScreen extends StatefulWidget {
  const ClockMatchScreen({super.key});

  @override
  State<ClockMatchScreen> createState() => _ClockMatchScreenState();
}

class _ClockMatchScreenState extends State<ClockMatchScreen> {
  final Random _random = Random();

  int _score = 0;
  int _round = 1;
  int _lives = 3;
  late String _prompt;
  late List<String> _options;
  late String _answer;
  String _message = 'Match the clock reading with the correct digital time.';

  @override
  void initState() {
    super.initState();
    _nextRound(resetGame: true);
  }

  void _nextRound({bool resetGame = false}) {
    final hour = 1 + _random.nextInt(12);
    final minute = [0, 15, 30, 45][_random.nextInt(4)];
    final answer =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    final options = <String>{answer};
    while (options.length < 4) {
      final fakeHour = 1 + _random.nextInt(12);
      final fakeMinute = [0, 15, 30, 45][_random.nextInt(4)];
      options.add(
        '${fakeHour.toString().padLeft(2, '0')}:${fakeMinute.toString().padLeft(2, '0')}',
      );
    }

    setState(() {
      if (resetGame) {
        _score = 0;
        _round = 1;
        _lives = 3;
      }
      _prompt = _clockPhrase(hour, minute);
      _answer = answer;
      _options = options.toList()..shuffle(_random);
      _message = 'Read the time clue and pick the matching clock.';
    });
  }

  String _clockPhrase(int hour, int minute) {
    switch (minute) {
      case 0:
        return '$hour o\'clock';
      case 15:
        return 'Quarter past $hour';
      case 30:
        return 'Half past $hour';
      case 45:
        final nextHour = hour == 12 ? 1 : hour + 1;
        return 'Quarter to $nextHour';
      default:
        return '$hour:$minute';
    }
  }

  Future<void> _pickOption(String option) async {
    if (_lives == 0) return;
    if (option == _answer) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = 'Correct time reading. Next clock ready.';
      });
      _nextRound();
      return;
    }

    final nextLives = _lives - 1;
    if (nextLives <= 0) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _lives = 0;
        _message = 'Wrong answer. Game over. Correct time was $_answer.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message = 'Not quite. Lives left: $nextLives.';
    });
    _nextRound();
  }

  void _resetGame() {
    _nextRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff8b5cf6), Color(0xff6366f1)];
    return GameScaffold(
      title: 'Clock Match',
      subtitle:
          'Practice reading time offline with quick clue-and-choice rounds.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives/3 • Learning game',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    _prompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ..._options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _lives == 0
                            ? null
                            : () => _pickOption(option),
                        child: Text(option),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset lesson', onPressed: _resetGame),
        ],
      ),
    );
  }
}
