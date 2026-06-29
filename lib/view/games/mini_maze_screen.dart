import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class MiniMazeScreen extends StatefulWidget {
  const MiniMazeScreen({super.key});

  @override
  State<MiniMazeScreen> createState() => _MiniMazeScreenState();
}

class _MiniMazeScreenState extends State<MiniMazeScreen> {
  final Random _random = Random();
  static const int _size = 5;

  late Set<int> _walls;
  int _playerIndex = 0;
  final int _goalIndex = (_size * _size) - 1;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  int _stepsLeft = 10;
  String _message = 'Reach the goal tile before your steps run out.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  void _startRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final safePath = _buildPath();
    final walls = <int>{};
    final maxWalls = min(5 + nextRound, 10);

    while (walls.length < maxWalls) {
      final candidate = _random.nextInt(_size * _size);
      if (candidate == 0 ||
          candidate == _goalIndex ||
          safePath.contains(candidate)) {
        continue;
      }
      walls.add(candidate);
    }

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _playerIndex = 0;
      _walls = walls;
      _stepsLeft = 10 + nextRound;
      _message = 'Round $nextRound: reach the finish in $_stepsLeft steps.';
    });
  }

  Set<int> _buildPath() {
    var row = 0;
    var col = 0;
    final path = <int>{0};
    while (row < _size - 1 || col < _size - 1) {
      final canMoveRight = col < _size - 1;
      final canMoveDown = row < _size - 1;
      final moveRight = canMoveRight && (!canMoveDown || _random.nextBool());
      if (moveRight) {
        col += 1;
      } else {
        row += 1;
      }
      path.add((row * _size) + col);
    }
    return path;
  }

  Future<void> _move(int rowDelta, int colDelta) async {
    if (_lives == 0 || _stepsLeft == 0) return;
    final row = _playerIndex ~/ _size;
    final col = _playerIndex % _size;
    final nextRow = row + rowDelta;
    final nextCol = col + colDelta;

    if (nextRow < 0 || nextRow >= _size || nextCol < 0 || nextCol >= _size) {
      setState(() {
        _message = 'That move goes outside the maze.';
      });
      return;
    }

    final nextIndex = (nextRow * _size) + nextCol;
    if (_walls.contains(nextIndex)) {
      setState(() {
        _message = 'Wall ahead. Try a different path.';
      });
      return;
    }

    final remainingSteps = _stepsLeft - 1;
    if (nextIndex == _goalIndex) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _playerIndex = nextIndex;
        _score += 1;
        _round += 1;
      });
      _startRound();
      return;
    }

    if (remainingSteps <= 0) {
      final nextLives = _lives - 1;
      if (nextLives <= 0) {
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        if (!mounted) return;
        setState(() {
          _lives = 0;
          _stepsLeft = 0;
          _message = 'Out of steps. Game over. Tap reset to try again.';
        });
        return;
      }

      setState(() {
        _lives = nextLives;
        _message = 'Out of steps. Lives left: $nextLives. Maze reset.';
      });
      _startRound();
      return;
    }

    setState(() {
      _playerIndex = nextIndex;
      _stepsLeft = remainingSteps;
      _message = 'Keep going. Exit is waiting.';
    });
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xfff59e0b), Color(0xfff97316)];
    return GameScaffold(
      title: 'Mini Maze',
      subtitle: 'Move through the maze, avoid walls, and reach the goal tile.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Steps left: $_stepsLeft',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _size * _size,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _size,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final isPlayer = index == _playerIndex;
                    final isGoal = index == _goalIndex;
                    final isWall = _walls.contains(index);
                    final color = isPlayer
                        ? accent.last
                        : isGoal
                        ? const Color(0xff22c55e)
                        : isWall
                        ? const Color(0xff334155)
                        : Colors.white.withValues(alpha: 0.08);
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: isPlayer
                          ? const Icon(
                              Icons.directions_walk_rounded,
                              color: Colors.white,
                            )
                          : isGoal
                          ? const Icon(Icons.flag_rounded, color: Colors.white)
                          : isWall
                          ? const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                            )
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: 92,
                      child: ElevatedButton(
                        onPressed: _lives == 0 ? null : () => _move(-1, 0),
                        child: const Icon(Icons.keyboard_arrow_up_rounded),
                      ),
                    ),
                    SizedBox(
                      width: 92,
                      child: ElevatedButton(
                        onPressed: _lives == 0 ? null : () => _move(0, -1),
                        child: const Icon(Icons.keyboard_arrow_left_rounded),
                      ),
                    ),
                    SizedBox(
                      width: 92,
                      child: ElevatedButton(
                        onPressed: _lives == 0 ? null : () => _move(0, 1),
                        child: const Icon(Icons.keyboard_arrow_right_rounded),
                      ),
                    ),
                    SizedBox(
                      width: 92,
                      child: ElevatedButton(
                        onPressed: _lives == 0 ? null : () => _move(1, 0),
                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ),
                  ],
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
