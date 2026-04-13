import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class PitLanePlannerScreen extends StatefulWidget {
  const PitLanePlannerScreen({super.key});

  @override
  State<PitLanePlannerScreen> createState() => _PitLanePlannerScreenState();
}

class _PitLanePlannerScreenState extends State<PitLanePlannerScreen> {
  final Random _random = Random();

  late _RaceScenario _scenario;
  int _score = 0;
  int _round = 1;
  int _lives = 3;
  String _message = 'Choose the smartest pit call for the current race state.';

  @override
  void initState() {
    super.initState();
    _nextRound(resetGame: true);
  }

  void _nextRound({bool resetGame = false}) {
    _RaceScenario scenario;
    while (true) {
      scenario = _RaceScenario.random(_random);
      final distinct =
          scenario.options.map((e) => e.correct).where((e) => e).length == 1;
      if (distinct) break;
    }

    setState(() {
      if (resetGame) {
        _score = 0;
        _round = 1;
        _lives = 3;
      }
      _scenario = scenario;
      _message = 'Fuel, tire wear, and weather decide the call.';
    });
  }

  Future<void> _pickChoice(_StrategyChoice choice) async {
    if (_lives == 0) return;

    if (choice.correct) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = 'Good strategy call. The team gains track position.';
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
            'Bad pit call. Race over. Best answer: ${_scenario.correctLabel}.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message = 'Not the best call. Lives left: $nextLives.';
    });
    _nextRound();
  }

  void _resetGame() {
    _nextRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xffef4444), Color(0xfff97316)];
    return GameScaffold(
      title: 'Pit Lane Planner',
      subtitle: 'A racing strategy game where timing matters more than speed.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives/3 • Offline racing strategy',
          ),
          const SizedBox(height: 18),
          StatusCard(
            headline: 'Race state',
            message:
                'Laps left: ${_scenario.lapsLeft} • Fuel: ${_scenario.fuel}% • Tire wear: ${_scenario.tireWear}% • Weather: ${_scenario.weather}',
            accent: accent.last,
            highlight: true,
          ),
          const SizedBox(height: 14),
          StatusCard(message: _message, accent: accent.first),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: _scenario.options
                  .map(
                    (choice) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _lives == 0
                              ? null
                              : () => _pickChoice(choice),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                choice.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(choice.description),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset strategy', onPressed: _resetGame),
        ],
      ),
    );
  }
}

class _RaceScenario {
  const _RaceScenario({
    required this.lapsLeft,
    required this.fuel,
    required this.tireWear,
    required this.weather,
    required this.options,
  });

  final int lapsLeft;
  final int fuel;
  final int tireWear;
  final String weather;
  final List<_StrategyChoice> options;

  String get correctLabel =>
      options.firstWhere((choice) => choice.correct).label;

  static _RaceScenario random(Random random) {
    final lapsLeft = 2 + random.nextInt(7);
    final fuel = 12 + random.nextInt(70);
    final tireWear = 20 + random.nextInt(75);
    final weather = ['Clear', 'Drizzle', 'Hot track'][random.nextInt(3)];

    final needsPit = fuel < 20 || tireWear > 80;
    final wet = weather == 'Drizzle';

    return _RaceScenario(
      lapsLeft: lapsLeft,
      fuel: fuel,
      tireWear: tireWear,
      weather: weather,
      options: [
        _StrategyChoice(
          label: 'Pit now for fresh tires',
          description: 'Box this lap and protect the final run.',
          correct: needsPit && !wet,
        ),
        _StrategyChoice(
          label: 'Stay out and defend track position',
          description: 'Keep the car out and avoid losing time in the lane.',
          correct: !needsPit && !wet,
        ),
        _StrategyChoice(
          label: 'Pit now for wet setup',
          description: 'React early to changing weather and switch plan.',
          correct: wet,
        ),
      ],
    );
  }
}

class _StrategyChoice {
  const _StrategyChoice({
    required this.label,
    required this.description,
    required this.correct,
  });

  final String label;
  final String description;
  final bool correct;
}
