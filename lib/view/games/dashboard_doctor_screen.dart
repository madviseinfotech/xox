import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class DashboardDoctorScreen extends StatefulWidget {
  const DashboardDoctorScreen({super.key});

  @override
  State<DashboardDoctorScreen> createState() => _DashboardDoctorScreenState();
}

class _DashboardDoctorScreenState extends State<DashboardDoctorScreen> {
  final Random _random = Random();

  static const int _maxLives = 3;
  static const List<_RepairCase> _cases = <_RepairCase>[
    _RepairCase(
      title: 'Battery light is on',
      description: 'The car struggles to start and the lights feel weak.',
      correctAnswer: 'Check battery and charging system',
      options: <String>[
        'Check battery and charging system',
        'Refill windshield washer fluid',
        'Rotate the tires',
      ],
      accent: Color(0xfff59e0b),
    ),
    _RepairCase(
      title: 'Engine temperature is high',
      description: 'Steam appears near the hood after a long drive.',
      correctAnswer: 'Inspect coolant and radiator',
      options: <String>[
        'Inspect coolant and radiator',
        'Replace the floor mats',
        'Tune the radio antenna',
      ],
      accent: Color(0xffef4444),
    ),
    _RepairCase(
      title: 'Tire pressure warning',
      description: 'One corner feels soft and the car pulls slightly.',
      correctAnswer: 'Check tire pressure and punctures',
      options: <String>[
        'Check tire pressure and punctures',
        'Clean the dashboard trim',
        'Top up engine oil only',
      ],
      accent: Color(0xff0ea5e9),
    ),
    _RepairCase(
      title: 'Oil warning appears',
      description: 'The engine sounds rough and the warning stays on.',
      correctAnswer: 'Check engine oil level',
      options: <String>[
        'Check engine oil level',
        'Wax the headlights',
        'Change the seat covers',
      ],
      accent: Color(0xff22c55e),
    ),
    _RepairCase(
      title: 'Brake warning stays lit',
      description: 'Stopping distance feels longer than usual.',
      correctAnswer: 'Inspect brake fluid and pads',
      options: <String>[
        'Inspect brake fluid and pads',
        'Increase tire shine',
        'Open the sunroof',
      ],
      accent: Color(0xfffb7185),
    ),
    _RepairCase(
      title: 'Headlights look dim',
      description: 'Night driving visibility is worse than normal.',
      correctAnswer: 'Inspect bulbs and battery health',
      options: <String>[
        'Inspect bulbs and battery health',
        'Fold the mirrors inward',
        'Refuel with premium only',
      ],
      accent: Color(0xff8b5cf6),
    ),
  ];

  late _RepairCase _currentCase;
  int _round = 1;
  int _score = 0;
  int _lives = _maxLives;
  String _message = 'Read the warning and pick the best garage action.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  bool get _gameOver => _lives == 0;

  void _startRound({bool resetGame = false}) {
    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = _maxLives;
      }
      _currentCase = _cases[_random.nextInt(_cases.length)];
      _message = 'Pick the best action for this car problem.';
    });
  }

  Future<void> _chooseAnswer(String answer) async {
    if (_gameOver) return;

    if (answer == _currentCase.correctAnswer) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = 'Correct fix. The car is ready for the next check-in.';
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
        _message =
            'Garage closed. The better answer was "${_currentCase.correctAnswer}".';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          'Not the best fix. Lives left: $nextLives. A new car is rolling in.';
    });
    _startRound();
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff0ea5e9), Color(0xff22c55e)];
    return GameScaffold(
      title: 'Dashboard Doctor',
      subtitle:
          'Read the car warning, choose the right fix, and keep the garage moving.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives/$_maxLives • Car care quick challenge',
          ),
          const SizedBox(height: 18),
          StatusCard(
            headline: 'Garage rules',
            message:
                'Read the warning card, then tap the most useful garage action. One bad call costs a life.',
            accent: accent.last,
            highlight: true,
          ),
          const SizedBox(height: 14),
          StatusCard(message: _message, accent: accent.first),
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
                    border: Border.all(
                      color: _currentCase.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.directions_car_filled_rounded,
                            color: _currentCase.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _currentCase.title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentCase.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._currentCase.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _gameOver
                            ? null
                            : () => _chooseAnswer(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset garage', onPressed: _resetGame),
        ],
      ),
    );
  }
}

class _RepairCase {
  const _RepairCase({
    required this.title,
    required this.description,
    required this.correctAnswer,
    required this.options,
    required this.accent,
  });

  final String title;
  final String description;
  final String correctAnswer;
  final List<String> options;
  final Color accent;
}
