import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class DirectionDashScreen extends StatefulWidget {
  const DirectionDashScreen({super.key});

  @override
  State<DirectionDashScreen> createState() => _DirectionDashScreenState();
}

class _DirectionDashScreenState extends State<DirectionDashScreen> {
  final Random _random = Random();
  static const List<_DirectionChoice> _choices = [
    _DirectionChoice('Up', Icons.keyboard_arrow_up_rounded),
    _DirectionChoice('Right', Icons.keyboard_arrow_right_rounded),
    _DirectionChoice('Down', Icons.keyboard_arrow_down_rounded),
    _DirectionChoice('Left', Icons.keyboard_arrow_left_rounded),
  ];

  late _DirectionChoice _prompt;
  bool _useOpposite = false;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  int _streak = 0;
  String _message = 'Follow the direction rule and tap the correct arrow.';

  @override
  void initState() {
    super.initState();
    _nextPrompt(resetGame: true);
  }

  void _nextPrompt({bool resetGame = false}) {
    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
        _streak = 0;
      }
      _prompt = _choices[_random.nextInt(_choices.length)];
      _useOpposite = _random.nextBool();
      _message = _useOpposite
          ? 'Tap the opposite direction of ${_prompt.label}.'
          : 'Tap the same direction as ${_prompt.label}.';
    });
  }

  _DirectionChoice _expectedChoice() {
    if (!_useOpposite) return _prompt;
    final index = _choices.indexOf(_prompt);
    return _choices[(index + 2) % _choices.length];
  }

  Future<void> _answer(_DirectionChoice choice) async {
    if (_lives == 0) return;
    final expected = _expectedChoice();
    if (choice == expected) {
      final nextRound = _round + 1;
      final nextScore = _score + 1;
      final nextStreak = _streak + 1;
      if (nextRound % 5 == 0) {
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        if (!mounted) return;
      }
      setState(() {
        _round = nextRound;
        _score = nextScore;
        _streak = nextStreak;
      });
      _nextPrompt();
      return;
    }

    final nextLives = _lives - 1;
    if (nextLives <= 0) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _lives = 0;
        _streak = 0;
        _message = 'Wrong arrow. Game over. Tap reset to try again.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _streak = 0;
      _message =
          'Wrong choice. ${expected.label} was correct. Lives left: $nextLives.';
    });
  }

  void _resetGame() {
    _nextPrompt(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff06b6d4), Color(0xff3b82f6)];
    return GameScaffold(
      title: 'Direction Dash',
      subtitle: 'Read the rule, then tap the matching arrow fast and clean.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Streak: $_streak',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(_prompt.icon, color: Colors.white, size: 54),
                      const SizedBox(height: 10),
                      Text(
                        _prompt.label,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _choices
                      .map(
                        (choice) => SizedBox(
                          width: 120,
                          child: ElevatedButton.icon(
                            onPressed: _lives == 0
                                ? null
                                : () => _answer(choice),
                            icon: Icon(choice.icon),
                            label: Text(choice.label),
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

class _DirectionChoice {
  const _DirectionChoice(this.label, this.icon);

  final String label;
  final IconData icon;
}
