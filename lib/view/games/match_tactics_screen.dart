import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class MatchTacticsScreen extends StatefulWidget {
  const MatchTacticsScreen({super.key});

  @override
  State<MatchTacticsScreen> createState() => _MatchTacticsScreenState();
}

class _MatchTacticsScreenState extends State<MatchTacticsScreen> {
  final Random _random = Random();
  static const List<String> _choices = ['Attack', 'Balance', 'Defend'];

  late int _minute;
  late int _goalDiff;
  late String _correctChoice;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  String _message = 'Read the match state and choose the best tactic.';

  @override
  void initState() {
    super.initState();
    _nextRound(resetGame: true);
  }

  void _nextRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final minute = 10 + _random.nextInt(81);
    final goalDiff = _random.nextInt(5) - 2;
    final correctChoice = _bestTactic(minute, goalDiff);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _minute = minute;
      _goalDiff = goalDiff;
      _correctChoice = correctChoice;
      _message =
          'Round $nextRound: choose the smartest tactic for this scoreline.';
    });
  }

  String _bestTactic(int minute, int goalDiff) {
    if (goalDiff <= -2) return 'Attack';
    if (goalDiff >= 2 && minute >= 55) return 'Defend';
    if (goalDiff == -1 && minute >= 60) return 'Attack';
    if (goalDiff == 1 && minute >= 70) return 'Defend';
    return 'Balance';
  }

  Future<void> _pickTactic(String choice) async {
    if (_lives == 0) return;
    if (choice == _correctChoice) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = '$choice was the right call.';
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
        _message = 'Best tactic was $_correctChoice. Tap reset to try again.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message = 'Best tactic was $_correctChoice. Lives left: $nextLives.';
    });
    _nextRound();
  }

  void _resetGame() {
    _nextRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff0f766e), Color(0xff22c55e)];
    final youScore = max(0, 2 + _goalDiff);
    final rivalScore = 2;
    return GameScaffold(
      title: 'Match Tactics',
      subtitle: 'Choose whether the team should attack, balance, or defend.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Minute: $_minute',
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
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Minute $_minute',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xffcbd5e1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$youScore - $rivalScore',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your team vs Rival',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xffcbd5e1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: _choices
                      .map(
                        (choice) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _lives == 0
                                  ? null
                                  : () => _pickTactic(choice),
                              child: Text(choice),
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
