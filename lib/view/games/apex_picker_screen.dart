import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class ApexPickerScreen extends StatefulWidget {
  const ApexPickerScreen({super.key});

  @override
  State<ApexPickerScreen> createState() => _ApexPickerScreenState();
}

class _ApexPickerScreenState extends State<ApexPickerScreen> {
  final Random _random = Random();

  static const List<_CornerRound> _rounds = <_CornerRound>[
    _CornerRound(
      title: 'Tight hairpin',
      description: 'Very slow corner after a long straight.',
      answer: 'Brake hard, turn late, then accelerate out',
      options: <String>[
        'Brake hard, turn late, then accelerate out',
        'Stay full throttle all the way through',
        'Turn in early and hug the inside immediately',
      ],
      icon: Icons.turn_left_rounded,
      color: Color(0xffef4444),
    ),
    _CornerRound(
      title: 'Fast sweeper',
      description: 'Long corner where speed matters more than aggression.',
      answer: 'Use a smooth wide line and keep the car balanced',
      options: <String>[
        'Use a smooth wide line and keep the car balanced',
        'Brake to a full stop before turning',
        'Dive to the apex as early as possible',
      ],
      icon: Icons.turn_slight_right_rounded,
      color: Color(0xff0ea5e9),
    ),
    _CornerRound(
      title: 'Wet braking zone',
      description: 'Grip is low before turn-in.',
      answer: 'Brake earlier and avoid sudden steering',
      options: <String>[
        'Brake earlier and avoid sudden steering',
        'Brake later because the tires stay cooler',
        'Use full throttle to keep the car planted',
      ],
      icon: Icons.water_drop_rounded,
      color: Color(0xff38bdf8),
    ),
    _CornerRound(
      title: 'Chicane attack',
      description: 'Quick left-right change of direction.',
      answer: 'Stay tidy, clip both apexes, and avoid over-driving entry',
      options: <String>[
        'Stay tidy, clip both apexes, and avoid over-driving entry',
        'Miss the first apex and jump straight to the second',
        'Turn the wheel sharply and keep maximum speed',
      ],
      icon: Icons.sync_alt_rounded,
      color: Color(0xff22c55e),
    ),
    _CornerRound(
      title: 'Exit onto a straight',
      description: 'Corner speed matters, but the exit matters more.',
      answer: 'Prioritize a clean exit and get on throttle smoothly',
      options: <String>[
        'Prioritize a clean exit and get on throttle smoothly',
        'Use all your speed on entry even if exit is messy',
        'Brake twice in the middle of the corner',
      ],
      icon: Icons.trending_up_rounded,
      color: Color(0xfff59e0b),
    ),
  ];

  late _CornerRound _currentRound;
  late List<String> _options;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  String _message = 'Choose the best racing call for each corner.';

  @override
  void initState() {
    super.initState();
    _nextRound(resetGame: true);
  }

  void _nextRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final picked = _rounds[_random.nextInt(_rounds.length)];
    final options = <String>[...picked.options]..shuffle(_random);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _currentRound = picked;
      _options = options;
      _message = 'Round $nextRound: make the smartest racing decision.';
    });
  }

  Future<void> _pickAnswer(String answer) async {
    if (_lives == 0) return;

    if (answer == _currentRound.answer) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = 'Strong call. That line keeps the lap alive.';
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
        _message =
            'Wrong call. Best answer: ${_currentRound.answer}. Tap reset to try again.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          'Wrong call. Best answer: ${_currentRound.answer}. Lives left: $nextLives.';
    });
    _nextRound();
  }

  void _resetGame() {
    _nextRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xffef4444), Color(0xfff59e0b)];
    return GameScaffold(
      title: 'Apex Picker',
      subtitle: 'Read the corner situation and choose the best racing move.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Racing decision challenge',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _currentRound.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _currentRound.icon,
                        color: _currentRound.color,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentRound.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _currentRound.description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: _options
                      .map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _lives == 0
                                  ? null
                                  : () => _pickAnswer(option),
                              child: Text(option),
                            ),
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

class _CornerRound {
  const _CornerRound({
    required this.title,
    required this.description,
    required this.answer,
    required this.options,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final String answer;
  final List<String> options;
  final IconData icon;
  final Color color;
}
