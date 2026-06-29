import 'dart:math';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class Twenty48Screen extends StatefulWidget {
  const Twenty48Screen({super.key});

  @override
  State<Twenty48Screen> createState() => _Twenty48ScreenState();
}

class _Twenty48ScreenState extends State<Twenty48Screen> {
  static const int _size = 4;

  final Random _random = Random();
  List<List<int>> _board = List.generate(_size, (_) => List.filled(_size, 0));
  int _score = 0;
  int _bestScore = 0;
  bool _gameOver = false;
  bool _won = false;
  String _message = 'Swipe to merge tiles. Reach 2048 to win.';

  @override
  void initState() {
    super.initState();
    _loadBest();
    _addTile();
    _addTile();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() => _bestScore = snapshot.twenty48BestScore);
  }

  void _newGame() {
    setState(() {
      _board = List.generate(_size, (_) => List.filled(_size, 0));
      _score = 0;
      _gameOver = false;
      _won = false;
      _message = 'Swipe to merge tiles. Reach 2048 to win.';
    });
    _addTile();
    _addTile();
  }

  void _addTile() {
    final empty = <(int, int)>[];
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_board[r][c] == 0) empty.add((r, c));
      }
    }
    if (empty.isEmpty) return;
    final pos = empty[_random.nextInt(empty.length)];
    _board[pos.$1][pos.$2] = _random.nextInt(10) < 9 ? 2 : 4;
  }

  List<int> _mergeRow(List<int> row) {
    final tiles = row.where((v) => v != 0).toList();
    final result = <int>[];
    int i = 0;
    while (i < tiles.length) {
      if (i + 1 < tiles.length && tiles[i] == tiles[i + 1]) {
        final merged = tiles[i] * 2;
        result.add(merged);
        _score += merged;
        if (merged == 2048) _won = true;
        i += 2;
      } else {
        result.add(tiles[i]);
        i++;
      }
    }
    while (result.length < _size) {
      result.add(0);
    }
    return result;
  }

  bool _move(_Direction dir) {
    final prev = _board.map((r) => List<int>.from(r)).toList();
    final board = _board.map((r) => List<int>.from(r)).toList();

    for (int r = 0; r < _size; r++) {
      switch (dir) {
        case _Direction.left:
          board[r] = _mergeRow(board[r]);
        case _Direction.right:
          board[r] = _mergeRow(board[r].reversed.toList()).reversed.toList();
        case _Direction.up:
          final col = List.generate(_size, (i) => board[i][r]);
          final merged = _mergeRow(col);
          for (int i = 0; i < _size; i++) {
            board[i][r] = merged[i];
          }
        case _Direction.down:
          final col = List.generate(_size, (i) => board[_size - 1 - i][r]);
          final merged = _mergeRow(col);
          for (int i = 0; i < _size; i++) {
            board[_size - 1 - i][r] = merged[i];
          }
      }
    }

    final changed = !List.generate(
      _size,
      (r) => List.generate(_size, (c) => board[r][c] == prev[r][c]),
    ).every((row) => row.every((v) => v));

    if (!changed) return false;
    _board = board;
    _addTile();
    return true;
  }

  bool _hasMovesLeft() {
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_board[r][c] == 0) return true;
        if (c + 1 < _size && _board[r][c] == _board[r][c + 1]) return true;
        if (r + 1 < _size && _board[r][c] == _board[r + 1][c]) return true;
      }
    }
    return false;
  }

  Future<void> _onSwipe(_Direction dir) async {
    if (_gameOver) return;
    final moved = _move(dir);
    if (!moved) return;

    if (_score > _bestScore) {
      _bestScore = _score;
      GameStatsStore.instance.recordTwenty48BestScore(_score);
    }

    if (_won) {
      setState(() => _message = '🎉 You reached 2048! Keep going or start fresh.');
      GameInterstitialService.instance.registerRoundCompletion();
      unawaited(GameInterstitialService.instance.maybeShow());
      return;
    }

    if (!_hasMovesLeft()) {
      setState(() {
        _gameOver = true;
        _message = 'No moves left. Score: $_score.';
      });
      GameInterstitialService.instance.registerRoundCompletion();
      unawaited(GameInterstitialService.instance.maybeShow());
      return;
    }

    setState(() {});
  }

  Color _tileColor(int value) {
    return switch (value) {
      0 => const Color(0xff132033),
      2 => const Color(0xff1e3a5f),
      4 => const Color(0xff1a4a6e),
      8 => const Color(0xff0e6b8a),
      16 => const Color(0xff0d7a6e),
      32 => const Color(0xff0f8a5a),
      64 => const Color(0xff1a9e3f),
      128 => const Color(0xff7c3aed),
      256 => const Color(0xff6d28d9),
      512 => const Color(0xffb45309),
      1024 => const Color(0xffb91c1c),
      2048 => const Color(0xffdc2626),
      _ => const Color(0xff7f1d1d),
    };
  }

  TextStyle _tileTextStyle(int value) {
    final size = value >= 1000 ? 18.0 : value >= 100 ? 22.0 : 26.0;
    return TextStyle(
      color: Colors.white,
      fontSize: size,
      fontWeight: FontWeight.w900,
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = [Color(0xff06b6d4), Color(0xff8b5cf6)];
    return GameScaffold(
      title: '2048',
      subtitle: 'Swipe to merge tiles and reach the 2048 tile.',
      accent: accent,
      scrollable: false,
      compactHeader: true,
      minimalHeader: true,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -200) _onSwipe(_Direction.up);
          if ((details.primaryVelocity ?? 0) > 200) _onSwipe(_Direction.down);
        },
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -200) _onSwipe(_Direction.left);
          if ((details.primaryVelocity ?? 0) > 200) _onSwipe(_Direction.right);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CompactMetricCard(label: 'Score', value: '$_score'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CompactMetricCard(label: 'Best', value: '$_bestScore'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InlineStatusStrip(
              message: _message,
              accent: _gameOver
                  ? const Color(0xffef4444)
                  : _won
                  ? const Color(0xfffacc15)
                  : const Color(0xff06b6d4),
              compact: true,
              highlight: _won || _gameOver,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GamePanel(
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _size * _size,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _size,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                      itemBuilder: (context, index) {
                        final r = index ~/ _size;
                        final c = index % _size;
                        final value = _board[r][c];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _tileColor(value),
                          ),
                          child: Center(
                            child: value == 0
                                ? null
                                : Text(
                                    '$value',
                                    style: _tileTextStyle(value),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _newGame,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('New Game'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _Direction { up, down, left, right }
