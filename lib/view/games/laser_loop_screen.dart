import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class LaserLoopScreen extends StatefulWidget {
  const LaserLoopScreen({super.key});

  @override
  State<LaserLoopScreen> createState() => _LaserLoopScreenState();
}

class _LaserLoopScreenState extends State<LaserLoopScreen> {
  final Random _random = Random();

  late List<int> _tiles;
  int _moves = 0;
  int _score = 0;
  int _level = 1;
  String _message = 'Rotate mirrors so the laser reaches the target.';

  @override
  void initState() {
    super.initState();
    _startLevel(resetGame: true);
  }

  void _startLevel({bool resetGame = false}) {
    final tiles = List<int>.generate(9, (_) => _random.nextInt(2));
    setState(() {
      if (resetGame) {
        _moves = 0;
        _score = 0;
        _level = 1;
      }
      _tiles = tiles;
      _message = 'Rotate the mirrors and light the target in the bottom-right.';
    });
  }

  bool _isSolved(List<int> tiles) {
    final rightMoves = <int>[0, 1, 2, 5, 8];
    return rightMoves.every((index) => tiles[index] == 1);
  }

  Future<void> _rotateTile(int index) async {
    final next = [..._tiles];
    next[index] = next[index] == 0 ? 1 : 0;
    final nextMoves = _moves + 1;

    if (_isSolved(next)) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _tiles = next;
        _moves = nextMoves;
        _score += max(1, 12 - nextMoves);
        _level += 1;
        _message = 'Laser linked. New mirror grid loaded.';
      });
      _startLevel();
      return;
    }

    setState(() {
      _tiles = next;
      _moves = nextMoves;
      _message = 'Beam rerouted. Keep building the path.';
    });
  }

  void _resetGame() {
    _startLevel(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff06b6d4), Color(0xff3b82f6)];
    return GameScaffold(
      title: 'Laser Loop',
      subtitle: 'A compact mirror puzzle you can solve fully offline.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Level',
            leftValue: _level.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Moves this level: $_moves',
          ),
          const SizedBox(height: 18),
          StatusCard(
            headline: 'Puzzle rules',
            message:
                'Tap a tile to rotate its mirror. Build a clean path from the top-left source to the bottom-right target.',
            accent: accent.last,
            highlight: true,
          ),
          const SizedBox(height: 14),
          StatusCard(message: _message, accent: accent.first),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 9,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final active = _tiles[index] == 1;
                    final isStart = index == 0;
                    final isEnd = index == 8;
                    return ElevatedButton(
                      onPressed: () => _rotateTile(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: active
                            ? accent.last.withValues(alpha: 0.28)
                            : Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            active
                                ? Icons.call_split_rounded
                                : Icons.remove_rounded,
                            size: 34,
                          ),
                          if (isStart || isEnd) ...[
                            const SizedBox(height: 6),
                            Text(
                              isStart ? 'Start' : 'Target',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset puzzle', onPressed: _resetGame),
        ],
      ),
    );
  }
}
