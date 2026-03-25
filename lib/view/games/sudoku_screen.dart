import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  static const List<int> _solution = [
    1,
    2,
    3,
    4,
    3,
    4,
    1,
    2,
    2,
    1,
    4,
    3,
    4,
    3,
    2,
    1,
  ];

  static const List<int?> _puzzle = [
    1,
    null,
    null,
    4,
    null,
    4,
    1,
    null,
    2,
    null,
    null,
    3,
    null,
    3,
    2,
    null,
  ];

  late List<int?> _board;
  bool _completed = false;
  int _solvedBoards = 0;
  String _message = 'Tap an empty tile to cycle through 1 to 4.';

  @override
  void initState() {
    super.initState();
    _board = [..._puzzle];
    _loadStats();
  }

  Future<void> _loadStats() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _solvedBoards = snapshot.sudokuSolvedBoards;
    });
  }

  Future<void> _tapCell(int index) async {
    if (_puzzle[index] != null || _completed) return;
    final nextValue = ((_board[index] ?? 0) % 4) + 1;
    setState(() {
      _board[index] = nextValue;
      _message = nextValue == _solution[index]
          ? 'Nice placement.'
          : 'Keep checking the row and box.';
    });

    final solved =
        List<int?>.generate(
          _board.length,
          (index) => _board[index],
        ).every((value) => value != null) &&
        _board.indexed.every((entry) => entry.$2 == _solution[entry.$1]);

    if (solved) {
      setState(() {
        _completed = true;
        _solvedBoards += 1;
        _message = 'Puzzle solved. Great work.';
      });
      await GameStatsStore.instance.incrementSudokuSolvedBoards();
    }
  }

  void _resetBoard() {
    setState(() {
      _board = [..._puzzle];
      _completed = false;
      _message = 'Tap an empty tile to cycle through 1 to 4.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filled = _board.whereType<int>().length;
    return GameScaffold(
      title: 'Sudoku Mini',
      subtitle: 'A compact 4x4 sudoku with quick tap controls.',
      accent: const [Color(0xff6366f1), Color(0xff2563eb)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Filled',
            leftValue: '$filled/16',
            rightLabel: 'Solved',
            rightValue: _solvedBoards.toString(),
            footer: _completed
                ? 'Board complete.'
                : 'Each row and box uses 1 to 4.',
          ),
          const SizedBox(height: 22),
          StatusCard(
            message: _message,
            accent: _completed
                ? const Color(0xff22c55e)
                : const Color(0xff3b82f6),
          ),
          const SizedBox(height: 18),
          TextButton(onPressed: _resetBoard, child: const Text('New puzzle')),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 16,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final fixed = _puzzle[index] != null;
                final value = _board[index];
                final correct = value == null || value == _solution[index];
                return GestureDetector(
                  onTap: () => _tapCell(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: fixed
                          ? const Color(0xff1e3a8a)
                          : correct
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xff7f1d1d),
                      border: Border.all(
                        color: fixed
                            ? const Color(0xff60a5fa)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: Text(
                          value?.toString() ?? '',
                          key: ValueKey('${index}_${value ?? 0}'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: fixed
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
