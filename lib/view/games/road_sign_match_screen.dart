import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class RoadSignMatchScreen extends StatefulWidget {
  const RoadSignMatchScreen({super.key});

  @override
  State<RoadSignMatchScreen> createState() => _RoadSignMatchScreenState();
}

class _RoadSignMatchScreenState extends State<RoadSignMatchScreen> {
  final Random _random = Random();

  static const List<_RoadSignRound> _rounds = <_RoadSignRound>[
    _RoadSignRound(
      sign: 'STOP',
      clue: 'Red octagon sign',
      answer: 'Come to a full stop',
      options: <String>[
        'Come to a full stop',
        'Drive faster',
        'Parking area ahead',
      ],
      color: Color(0xffef4444),
    ),
    _RoadSignRound(
      sign: 'SCHOOL',
      clue: 'Children crossing sign',
      answer: 'Slow down near a school zone',
      options: <String>[
        'Slow down near a school zone',
        'Only buses may enter',
        'Playground this way',
      ],
      color: Color(0xfff59e0b),
    ),
    _RoadSignRound(
      sign: 'P',
      clue: 'Blue parking sign',
      answer: 'Parking is allowed here',
      options: <String>[
        'Parking is allowed here',
        'Petrol pump ahead',
        'Pedestrians only',
      ],
      color: Color(0xff0ea5e9),
    ),
    _RoadSignRound(
      sign: '↺',
      clue: 'Circular arrows',
      answer: 'Roundabout ahead',
      options: <String>['Roundabout ahead', 'Road closed', 'Reverse only'],
      color: Color(0xff22c55e),
    ),
    _RoadSignRound(
      sign: '60',
      clue: 'Speed limit sign',
      answer: 'Maximum speed is 60',
      options: <String>[
        'Maximum speed is 60',
        'Minimum speed is 60',
        'Drive 60 minutes more',
      ],
      color: Color(0xff8b5cf6),
    ),
    _RoadSignRound(
      sign: '⛽',
      clue: 'Fuel pump symbol',
      answer: 'Fuel station ahead',
      options: <String>[
        'Fuel station ahead',
        'No trucks allowed',
        'Bridge ahead',
      ],
      color: Color(0xff14b8a6),
    ),
  ];

  late _RoadSignRound _currentRound;
  late List<String> _options;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  String _message = 'Match each road sign with its correct meaning.';

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
      _message = 'Round $nextRound: what does this sign mean?';
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
        _message = 'Correct. Nice road-safety call.';
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
            'Wrong answer. Correct meaning: ${_currentRound.answer}. Tap reset to play again.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          'Wrong answer. Correct meaning: ${_currentRound.answer}. Lives left: $nextLives.';
    });
    _nextRound();
  }

  void _resetGame() {
    _nextRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff0ea5e9), Color(0xff8b5cf6)];
    return GameScaffold(
      title: 'Road Sign Match',
      subtitle: 'Learn common road signs by matching each one to its meaning.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Learning road rules',
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
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _currentRound.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 88,
                        width: 88,
                        decoration: BoxDecoration(
                          color: _currentRound.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _currentRound.sign,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _currentRound.clue,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xffcbd5e1),
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

class _RoadSignRound {
  const _RoadSignRound({
    required this.sign,
    required this.clue,
    required this.answer,
    required this.options,
    required this.color,
  });

  final String sign;
  final String clue;
  final String answer;
  final List<String> options;
  final Color color;
}
