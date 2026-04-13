import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class LightGridScreen extends StatefulWidget {
  const LightGridScreen({super.key});

  @override
  State<LightGridScreen> createState() => _LightGridScreenState();
}

class _LightGridScreenState extends State<LightGridScreen> {
  final Random _random = Random();

  late List<bool> _cells;
  int _gridSize = 3;
  int _moves = 0;
  int _bestSolvedLevel = 0;
  String _message = 'Turn every light off using as few moves as possible.';

  @override
  void initState() {
    super.initState();
    _cells = List<bool>.filled(_gridSize * _gridSize, false);
    _loadBest();
    _startPuzzle(resetLevel: true);
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestSolvedLevel = snapshot.lightGridBestLevel;
    });
  }

  void _startPuzzle({bool resetLevel = false}) {
    final size = resetLevel ? 3 : _gridSize;
    final nextCells = List<bool>.filled(size * size, false);
    final scrambleMoves = size * 2 + 1;

    for (var i = 0; i < scrambleMoves; i++) {
      _toggleIndex(nextCells, _random.nextInt(nextCells.length), size);
    }

    final hasAnyLightOn = nextCells.any((cell) => cell);
    if (!hasAnyLightOn) {
      nextCells[_random.nextInt(nextCells.length)] = true;
    }

    setState(() {
      _gridSize = size;
      _moves = 0;
      _cells = nextCells;
      _message = 'Turn every light off using as few moves as possible.';
    });
  }

  void _toggleCell(int index) async {
    final nextCells = List<bool>.from(_cells);
    _toggleIndex(nextCells, index, _gridSize);
    final nextMoves = _moves + 1;
    final solved = nextCells.every((cell) => !cell);

    setState(() {
      _cells = nextCells;
      _moves = nextMoves;
      _message = solved
          ? 'Board cleared in $nextMoves moves.'
          : 'Keep going. ${nextCells.where((cell) => cell).length} lights still on.';
    });

    if (!solved) return;

    final solvedLevel = _gridSize - 2;
    if (solvedLevel > _bestSolvedLevel) {
      await GameStatsStore.instance.recordLightGridBestLevel(solvedLevel);
      if (!mounted) return;
      setState(() {
        _bestSolvedLevel = solvedLevel;
      });
    }

    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();

    if (!mounted) return;
    setState(() {
      if (_gridSize < 5) {
        _gridSize += 1;
      }
    });
    _startPuzzle();
  }

  void _toggleIndex(List<bool> cells, int index, int size) {
    final row = index ~/ size;
    final col = index % size;

    void flip(int r, int c) {
      if (r < 0 || r >= size || c < 0 || c >= size) return;
      final targetIndex = (r * size) + c;
      cells[targetIndex] = !cells[targetIndex];
    }

    flip(row, col);
    flip(row - 1, col);
    flip(row + 1, col);
    flip(row, col - 1);
    flip(row, col + 1);
  }

  void _resetGame() {
    _startPuzzle(resetLevel: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff38bdf8), Color(0xff6366f1)];
    final level = _gridSize - 2;
    return GameScaffold(
      title: 'Light Grid',
      subtitle: 'Tap tiles to switch the whole board off.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Level',
            leftValue: level.toString(),
            rightLabel: 'Best',
            rightValue: _bestSolvedLevel.toString(),
            footer: 'Grid ${_gridSize}x$_gridSize • Moves: $_moves',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Turn all lights off',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Each tap flips the tapped tile and its nearby tiles.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xff94a3b8),
                  ),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cells.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridSize,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final isOn = _cells[index];
                    return ElevatedButton(
                      onPressed: () => _toggleCell(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOn
                            ? const Color(0xff38bdf8)
                            : Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Icon(
                        isOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline,
                        size: 28,
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
