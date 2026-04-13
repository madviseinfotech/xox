import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class PairFinderScreen extends StatefulWidget {
  const PairFinderScreen({super.key});

  @override
  State<PairFinderScreen> createState() => _PairFinderScreenState();
}

class _PairFinderScreenState extends State<PairFinderScreen> {
  final Random _random = Random();

  late List<int> _tiles;
  final List<int> _selectedIndexes = [];
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  int _targetSum = 10;
  String _message = 'Pick two tiles that add up to the target sum.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  void _startRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final pairCount = min(3 + nextRound, 6);
    final targetSum = 8 + _random.nextInt(10);
    final tiles = <int>[];

    for (var i = 0; i < pairCount; i++) {
      final first = 1 + _random.nextInt(targetSum - 1);
      final second = targetSum - first;
      tiles
        ..add(first)
        ..add(second);
    }
    tiles.shuffle(_random);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _targetSum = targetSum;
      _tiles = tiles;
      _selectedIndexes.clear();
      _message = 'Find $pairCount pairs that add up to $_targetSum.';
    });
  }

  Future<void> _pickTile(int index) async {
    if (_lives == 0 ||
        _tiles[index] == -1 ||
        _selectedIndexes.contains(index)) {
      return;
    }

    final updatedSelection = [..._selectedIndexes, index];
    if (updatedSelection.length == 1) {
      setState(() {
        _selectedIndexes
          ..clear()
          ..addAll(updatedSelection);
        _message = 'Pick one more tile to make $_targetSum.';
      });
      return;
    }

    final firstValue = _tiles[updatedSelection.first];
    final secondValue = _tiles[updatedSelection.last];
    if (firstValue + secondValue == _targetSum) {
      final updatedTiles = List<int>.from(_tiles);
      updatedTiles[updatedSelection.first] = -1;
      updatedTiles[updatedSelection.last] = -1;
      final clearedBoard = updatedTiles.every((value) => value == -1);

      if (clearedBoard) {
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        if (!mounted) return;
        setState(() {
          _tiles = updatedTiles;
          _selectedIndexes.clear();
          _score += 1;
          _round += 1;
        });
        _startRound();
        return;
      }

      setState(() {
        _tiles = updatedTiles;
        _selectedIndexes.clear();
        _message = 'Nice pair. Keep clearing the board.';
      });
      return;
    }

    final nextLives = _lives - 1;
    if (nextLives <= 0) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _lives = 0;
        _selectedIndexes.clear();
        _message = 'Wrong pair. Game over. Tap reset to play again.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _selectedIndexes.clear();
      _message = 'That pair does not make $_targetSum. Lives left: $nextLives.';
    });
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xfff97316), Color(0xffef4444)];
    return GameScaffold(
      title: 'Pair Finder',
      subtitle: 'Match two numbers that add up to the target sum.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Target sum: $_targetSum',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tiles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final value = _tiles[index];
                final cleared = value == -1;
                final selected = _selectedIndexes.contains(index);
                return ElevatedButton(
                  onPressed: cleared || _lives == 0
                      ? null
                      : () => _pickTile(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cleared
                        ? const Color(0xff22c55e).withValues(alpha: 0.18)
                        : selected
                        ? accent.last.withValues(alpha: 0.26)
                        : Colors.white.withValues(alpha: 0.08),
                    disabledBackgroundColor: cleared
                        ? const Color(0xff22c55e).withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    cleared ? 'OK' : '$value',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset game', onPressed: _resetGame),
        ],
      ),
    );
  }
}
