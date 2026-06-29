import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class TargetHuntScreen extends StatefulWidget {
  const TargetHuntScreen({super.key});

  @override
  State<TargetHuntScreen> createState() => _TargetHuntScreenState();
}

class _TargetHuntScreenState extends State<TargetHuntScreen> {
  final Random _random = Random();

  late List<int> _tiles;
  late int _targetValue;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  int _targetsLeft = 0;
  String _message = 'Tap every tile that matches the target number.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  int get _tileCount => min(6 + ((_round - 1) * 2), 16);

  int get _crossAxisCount {
    if (_tileCount <= 6) return 3;
    if (_tileCount <= 12) return 4;
    return 4;
  }

  void _startRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final tileCount = min(6 + ((nextRound - 1) * 2), 16);
    final targetValue = _random.nextInt(9) + 1;
    final targetCopies = min(2 + ((nextRound - 1) ~/ 2), 5);
    final tiles = <int>[];

    for (var i = 0; i < targetCopies; i++) {
      tiles.add(targetValue);
    }
    while (tiles.length < tileCount) {
      final next = _random.nextInt(9) + 1;
      if (next == targetValue) continue;
      tiles.add(next);
    }
    tiles.shuffle(_random);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _targetValue = targetValue;
      _targetsLeft = targetCopies;
      _tiles = tiles;
      _message = 'Find all $targetCopies tiles with number $targetValue.';
    });
  }

  Future<void> _handleTap(int index) async {
    final value = _tiles[index];
    if (value == -1) return;

    if (value == _targetValue) {
      final updatedTiles = List<int>.from(_tiles);
      updatedTiles[index] = -1;
      final nextTargetsLeft = _targetsLeft - 1;

      setState(() {
        _tiles = updatedTiles;
        _targetsLeft = nextTargetsLeft;
        _score += 1;
        _message = nextTargetsLeft == 0
            ? 'Round clear. Get ready for the next board.'
            : 'Nice. $nextTargetsLeft matching tiles left.';
      });

      if (nextTargetsLeft != 0) return;

      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _round += 1;
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
        _message = 'Game over. Tap reset to play again.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message = 'Wrong tile. $nextLives lives left.';
    });
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xfff97316), Color(0xffef4444)];
    return GameScaffold(
      title: 'Target Hunt',
      subtitle: 'Find every matching number before you run out of lives.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Target: $_targetValue',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap all matching tiles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Only tap the number shown as the target. Wrong taps cost a life.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xff94a3b8),
                  ),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _tiles.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final value = _tiles[index];
                    final cleared = value == -1;
                    return ElevatedButton(
                      onPressed: _lives == 0 || cleared
                          ? null
                          : () => _handleTap(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cleared
                            ? const Color(0xff22c55e).withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: cleared
                            ? const Color(0xff22c55e).withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.06),
                        disabledForegroundColor: Colors.white70,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: cleared
                                ? const Color(0xff22c55e)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: Text(
                        cleared ? 'OK' : value.toString(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  },
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
