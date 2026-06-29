import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class ColorSweepScreen extends StatefulWidget {
  const ColorSweepScreen({super.key});

  @override
  State<ColorSweepScreen> createState() => _ColorSweepScreenState();
}

class _ColorSweepScreenState extends State<ColorSweepScreen> {
  final Random _random = Random();

  late List<_ColorTile> _tiles;
  late Color _targetColor;
  int _round = 1;
  int _score = 0;
  int _mistakesLeft = 3;
  int _targetsLeft = 0;
  String _message = 'Tap every tile that matches the target color.';

  static const List<Color> _palette = [
    Color(0xffef4444),
    Color(0xff22c55e),
    Color(0xff3b82f6),
    Color(0xfff59e0b),
    Color(0xff8b5cf6),
    Color(0xffec4899),
  ];

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  int get _tileCount => min(9 + ((_round - 1) * 3), 20);

  int get _crossAxisCount => _tileCount <= 12 ? 3 : 4;

  void _startRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final tileCount = min(9 + ((nextRound - 1) * 3), 20);
    final targetColor = _palette[_random.nextInt(_palette.length)];
    final targetCount = min(3 + ((nextRound - 1) ~/ 2), 6);
    final tiles = <_ColorTile>[];

    for (var i = 0; i < targetCount; i++) {
      tiles.add(_ColorTile(color: targetColor));
    }

    while (tiles.length < tileCount) {
      final nextColor = _palette[_random.nextInt(_palette.length)];
      if (nextColor == targetColor) continue;
      tiles.add(_ColorTile(color: nextColor));
    }

    tiles.shuffle(_random);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _mistakesLeft = 3;
      }
      _targetColor = targetColor;
      _tiles = tiles;
      _targetsLeft = targetCount;
      _message = 'Round $nextRound: clear all $targetCount target tiles.';
    });
  }

  Future<void> _pickTile(int index) async {
    final tile = _tiles[index];
    if (tile.cleared || _mistakesLeft == 0) return;

    if (tile.color == _targetColor) {
      final updated = List<_ColorTile>.from(_tiles);
      updated[index] = tile.copyWith(cleared: true);
      final nextTargets = _targetsLeft - 1;
      setState(() {
        _tiles = updated;
        _targetsLeft = nextTargets;
        _score += 1;
        _message = nextTargets == 0
            ? 'Board cleared. Next color sweep is loading.'
            : 'Great. $nextTargets target tiles left.';
      });

      if (nextTargets != 0) return;

      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _round += 1;
      });
      _startRound();
      return;
    }

    final nextMistakes = _mistakesLeft - 1;
    if (nextMistakes <= 0) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _mistakesLeft = 0;
        _message = 'No chances left. Tap reset to start again.';
      });
      return;
    }

    setState(() {
      _mistakesLeft = nextMistakes;
      _message = 'Wrong color. $nextMistakes mistakes left.';
    });
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff14b8a6), Color(0xff06b6d4)];
    return GameScaffold(
      title: 'Color Sweep',
      subtitle: 'Clear only the target color and protect your chances.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Mistakes left: $_mistakesLeft • Targets: $_targetsLeft',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target color',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 58,
                  width: 120,
                  decoration: BoxDecoration(
                    color: _targetColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
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
                    final tile = _tiles[index];
                    return ElevatedButton(
                      onPressed: tile.cleared || _mistakesLeft == 0
                          ? null
                          : () => _pickTile(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tile.cleared
                            ? tile.color.withValues(alpha: 0.22)
                            : tile.color,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: tile.cleared
                            ? tile.color.withValues(alpha: 0.22)
                            : tile.color,
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: tile.cleared
                                ? const Color(0xff22c55e)
                                : Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      child: Text(
                        tile.cleared ? 'OK' : '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
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

class _ColorTile {
  const _ColorTile({required this.color, this.cleared = false});

  final Color color;
  final bool cleared;

  _ColorTile copyWith({bool? cleared}) {
    return _ColorTile(color: color, cleared: cleared ?? this.cleared);
  }
}
