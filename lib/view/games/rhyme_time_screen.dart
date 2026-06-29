import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class RhymeTimeScreen extends StatefulWidget {
  const RhymeTimeScreen({super.key});

  @override
  State<RhymeTimeScreen> createState() => _RhymeTimeScreenState();
}

class _RhymeTimeScreenState extends State<RhymeTimeScreen> {
  final Random _random = Random();

  static const List<_RhymeRound> _rounds = [
    _RhymeRound(prompt: 'Cat', answer: 'Hat', options: ['Hat', 'Cup', 'Tree']),
    _RhymeRound(prompt: 'Sun', answer: 'Run', options: ['Run', 'Leaf', 'Book']),
    _RhymeRound(
      prompt: 'Ball',
      answer: 'Tall',
      options: ['Tall', 'Fish', 'Pen'],
    ),
    _RhymeRound(
      prompt: 'Cake',
      answer: 'Lake',
      options: ['Lake', 'Spoon', 'Drum'],
    ),
    _RhymeRound(
      prompt: 'Blue',
      answer: 'Glue',
      options: ['Glue', 'Park', 'Ring'],
    ),
    _RhymeRound(
      prompt: 'Star',
      answer: 'Car',
      options: ['Car', 'Hill', 'Mouse'],
    ),
    _RhymeRound(
      prompt: 'Bee',
      answer: 'Tree',
      options: ['Tree', 'Chair', 'Clock'],
    ),
    _RhymeRound(
      prompt: 'Moon',
      answer: 'Spoon',
      options: ['Spoon', 'Stone', 'Bread'],
    ),
  ];

  late _RhymeRound _currentRound;
  late List<String> _options;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  String _message = 'Pick the word that rhymes with the prompt word.';

  @override
  void initState() {
    super.initState();
    _nextRound(resetGame: true);
  }

  void _nextRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final picked = _rounds[_random.nextInt(_rounds.length)];
    final options = [...picked.options]..shuffle(_random);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _currentRound = picked;
      _options = options;
      _message = 'Round $nextRound: find a rhyme for ${picked.prompt}.';
    });
  }

  Future<void> _pickWord(String word) async {
    if (_lives == 0) return;
    if (word == _currentRound.answer) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message =
            'Nice. ${_currentRound.answer} rhymes with ${_currentRound.prompt}.';
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
            'Wrong word. Correct rhyme was ${_currentRound.answer}. Tap reset to try again.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          'Wrong word. Correct rhyme was ${_currentRound.answer}. Lives left: $nextLives.';
    });
    _nextRound();
  }

  void _resetGame() {
    _nextRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff14b8a6), Color(0xff06b6d4)];
    return GameScaffold(
      title: 'Rhyme Time',
      subtitle: 'Practice word sounds by picking the word that rhymes.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Prompt: ${_currentRound.prompt}',
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
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Find a rhyme for',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xffcbd5e1),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _currentRound.prompt,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
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
                                  : () => _pickWord(option),
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

class _RhymeRound {
  const _RhymeRound({
    required this.prompt,
    required this.answer,
    required this.options,
  });

  final String prompt;
  final String answer;
  final List<String> options;
}
