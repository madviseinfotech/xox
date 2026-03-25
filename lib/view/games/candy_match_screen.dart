import 'dart:math';

import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class CandyMatchScreen extends StatefulWidget {
  const CandyMatchScreen({super.key});

  @override
  State<CandyMatchScreen> createState() => _CandyMatchScreenState();
}

class _CandyMatchScreenState extends State<CandyMatchScreen> {
  static const int _size = 7;
  static const List<_CandyStyle> _styles = [
    _CandyStyle(
      baseColor: Color(0xfff97316),
      glowColor: Color(0xffffedd5),
      symbol: _CandySymbol.lozenge,
    ),
    _CandyStyle(
      baseColor: Color(0xffef4444),
      glowColor: Color(0xfffee2e2),
      symbol: _CandySymbol.round,
    ),
    _CandyStyle(
      baseColor: Color(0xffa855f7),
      glowColor: Color(0xfff3e8ff),
      symbol: _CandySymbol.diamond,
    ),
    _CandyStyle(
      baseColor: Color(0xff22c55e),
      glowColor: Color(0xffdcfce7),
      symbol: _CandySymbol.square,
    ),
    _CandyStyle(
      baseColor: Color(0xff38bdf8),
      glowColor: Color(0xffe0f2fe),
      symbol: _CandySymbol.drop,
    ),
    _CandyStyle(
      baseColor: Color(0xfffacc15),
      glowColor: Color(0xfffef9c3),
      symbol: _CandySymbol.star,
    ),
  ];

  final Random _random = Random();
  late List<List<int>> _board;
  int? _selectedRow;
  int? _selectedCol;
  int _level = 1;
  int _score = 0;
  int _bestScore = 0;
  int _movesLeft = 18;
  int _lastMatchCount = 0;
  bool _isBusy = false;
  String _message = 'Drag a candy into a neighbor to make a match.';
  Offset? _dragStartLocal;
  int? _dragStartRow;
  int? _dragStartCol;

  @override
  void initState() {
    super.initState();
    _loadBest();
    _resetLevel();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestScore = snapshot.candyMatchBestScore;
    });
  }

  int get _targetScore => 180 + ((_level - 1) * 80);

  void _resetLevel() {
    _board = List.generate(
      _size,
      (_) => List.generate(_size, (_) => _random.nextInt(_styles.length)),
    );
    _selectedRow = null;
    _selectedCol = null;
    _movesLeft = max(10, 18 - ((_level - 1) ~/ 2));
    _lastMatchCount = 0;
    _clearExistingMatches();
  }

  void _clearExistingMatches() {
    while (true) {
      final matches = _findMatches();
      if (matches.isEmpty) return;
      for (final (row, col) in matches) {
        _board[row][col] = _random.nextInt(_styles.length);
      }
    }
  }

  Set<(int, int)> _findMatches() {
    final matches = <(int, int)>{};

    for (var row = 0; row < _size; row++) {
      var runStart = 0;
      for (var col = 1; col <= _size; col++) {
        final same =
            col < _size &&
            _board[row][col] != -1 &&
            _board[row][col] == _board[row][runStart];
        if (same) continue;
        final runLength = col - runStart;
        if (runLength >= 3 && _board[row][runStart] != -1) {
          for (var i = runStart; i < col; i++) {
            matches.add((row, i));
          }
        }
        runStart = col;
      }
    }

    for (var col = 0; col < _size; col++) {
      var runStart = 0;
      for (var row = 1; row <= _size; row++) {
        final same =
            row < _size &&
            _board[row][col] != -1 &&
            _board[row][col] == _board[runStart][col];
        if (same) continue;
        final runLength = row - runStart;
        if (runLength >= 3 && _board[runStart][col] != -1) {
          for (var i = runStart; i < row; i++) {
            matches.add((i, col));
          }
        }
        runStart = row;
      }
    }

    return matches;
  }

  bool _isAdjacent(int rowA, int colA, int rowB, int colB) {
    return (rowA - rowB).abs() + (colA - colB).abs() == 1;
  }

  void _swapCells(int firstRow, int firstCol, int secondRow, int secondCol) {
    final firstValue = _board[firstRow][firstCol];
    _board[firstRow][firstCol] = _board[secondRow][secondCol];
    _board[secondRow][secondCol] = firstValue;
  }

  Future<void> _handleTap(int row, int col) async {
    if (_isBusy || _movesLeft <= 0) return;

    if (_selectedRow == null || _selectedCol == null) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
        _message = 'Tap one nearby candy to swap.';
      });
      return;
    }

    if (_selectedRow == row && _selectedCol == col) {
      setState(() {
        _selectedRow = null;
        _selectedCol = null;
        _message = 'Selection cleared. Try another swap.';
      });
      return;
    }

    if (!_isAdjacent(_selectedRow!, _selectedCol!, row, col)) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
        _message = 'Choose a candy touching the first one.';
      });
      return;
    }

    final firstRow = _selectedRow!;
    final firstCol = _selectedCol!;
    _selectedRow = null;
    _selectedCol = null;
    await _attemptSwap(firstRow, firstCol, row, col, viaDrag: false);
  }

  void _handleBoardPanStart(DragStartDetails details, double tileSize) {
    if (_isBusy || _movesLeft <= 0) return;
    final cell = _cellFromOffset(details.localPosition, tileSize);
    if (cell == null) return;
    _dragStartLocal = details.localPosition;
    _dragStartRow = cell.$1;
    _dragStartCol = cell.$2;
    setState(() {
      _selectedRow = cell.$1;
      _selectedCol = cell.$2;
      _message = 'Slide to a neighbor to swap candies.';
    });
  }

  Future<void> _handleBoardPanUpdate(
    DragUpdateDetails details,
    double tileSize,
  ) async {
    if (_isBusy ||
        _dragStartLocal == null ||
        _dragStartRow == null ||
        _dragStartCol == null) {
      return;
    }
    final delta = details.localPosition - _dragStartLocal!;
    if (delta.distance < tileSize * 0.34) return;

    final startRow = _dragStartRow!;
    final startCol = _dragStartCol!;
    var targetRow = startRow;
    var targetCol = startCol;
    if (delta.dx.abs() > delta.dy.abs()) {
      targetCol += delta.dx.isNegative ? -1 : 1;
    } else {
      targetRow += delta.dy.isNegative ? -1 : 1;
    }
    _clearDragSelection();
    if (targetRow < 0 ||
        targetRow >= _size ||
        targetCol < 0 ||
        targetCol >= _size) {
      return;
    }
    await _attemptSwap(startRow, startCol, targetRow, targetCol, viaDrag: true);
  }

  void _handleBoardPanEnd(DragEndDetails details) {
    _clearDragSelection();
  }

  void _clearDragSelection() {
    _dragStartLocal = null;
    _dragStartRow = null;
    _dragStartCol = null;
  }

  (int, int)? _cellFromOffset(Offset position, double tileSize) {
    final col = (position.dx / tileSize).floor();
    final row = (position.dy / tileSize).floor();
    if (row < 0 || row >= _size || col < 0 || col >= _size) {
      return null;
    }
    return (row, col);
  }

  Future<void> _attemptSwap(
    int firstRow,
    int firstCol,
    int secondRow,
    int secondCol, {
    required bool viaDrag,
  }) async {
    if (_isBusy || _movesLeft <= 0) return;
    if (!_isAdjacent(firstRow, firstCol, secondRow, secondCol)) return;

    setState(() {
      _isBusy = true;
      _selectedRow = null;
      _selectedCol = null;
    });

    _swapCells(firstRow, firstCol, secondRow, secondCol);
    setState(() {
      _message = viaDrag
          ? 'Sweet swap. Checking matches...'
          : 'Checking match...';
    });

    final matches = _findMatches();
    if (matches.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 140));
      _swapCells(firstRow, firstCol, secondRow, secondCol);
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _message = 'That swap did not match. Try another move.';
      });
      return;
    }

    await _resolveMatches(matches);
  }

  Future<void> _resolveMatches(Set<(int, int)> initialMatches) async {
    var pendingMatches = initialMatches;
    var totalGain = 0;
    var cascade = 0;

    while (pendingMatches.isNotEmpty) {
      cascade += 1;
      _lastMatchCount = pendingMatches.length;
      totalGain += pendingMatches.length * 12 * cascade;

      for (final (row, col) in pendingMatches) {
        _board[row][col] = -1;
      }

      if (mounted) {
        setState(() {
          _message = cascade == 1
              ? '$_lastMatchCount candies crushed.'
              : 'Combo x$cascade. Board keeps dropping.';
        });
      }

      await Future<void>.delayed(const Duration(milliseconds: 150));

      for (var col = 0; col < _size; col++) {
        final survivors = <int>[];
        for (var row = _size - 1; row >= 0; row--) {
          if (_board[row][col] != -1) {
            survivors.add(_board[row][col]);
          }
        }
        while (survivors.length < _size) {
          survivors.add(_random.nextInt(_styles.length));
        }
        for (var row = _size - 1, index = 0; row >= 0; row--, index++) {
          _board[row][col] = survivors[index];
        }
      }

      pendingMatches = _findMatches();
    }

    final nextScore = _score + totalGain;
    final nextMoves = _movesLeft - 1;
    final isBest = nextScore > _bestScore;
    if (isBest) {
      await GameStatsStore.instance.recordCandyMatchBestScore(nextScore);
    }
    if (!mounted) return;

    if (nextScore >= _targetScore) {
      final nextLevel = _level + 1;
      setState(() {
        _score = nextScore;
        _movesLeft = nextMoves;
        _bestScore = isBest ? nextScore : _bestScore;
        _isBusy = false;
        _message = 'Sugar rush. Level $nextLevel is ready.';
      });
      await Future<void>.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;
      setState(() {
        _level = nextLevel;
        _resetLevel();
      });
      return;
    }

    setState(() {
      _score = nextScore;
      _movesLeft = nextMoves;
      _bestScore = isBest ? nextScore : _bestScore;
      _isBusy = false;
      _message = nextMoves == 0
          ? 'Out of moves. Tap reset and chase a bigger combo.'
          : cascade > 1
          ? 'Combo x$cascade landed. $nextMoves moves left.'
          : 'Nice crush. $nextMoves moves left.';
    });
  }

  void _resetGame() {
    setState(() {
      _level = 1;
      _score = 0;
      _message = 'Drag a candy into a neighbor to make a match.';
      _isBusy = false;
      _resetLevel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Candy Match',
      subtitle: 'Drag bright candies, trigger combos, and beat the level goal.',
      accent: const [Color(0xfffb7185), Color(0xffa855f7)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Level',
            leftValue: _level.toString(),
            rightLabel: 'Best',
            rightValue: _bestScore.toString(),
            footer: 'Score $_score/$_targetScore • Moves $_movesLeft',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _CandyInfoPill(
                    label: 'Goal',
                    value: '$_targetScore pts',
                    color: const Color(0xfffb7185),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CandyInfoPill(
                    label: 'Last crush',
                    value: _lastMatchCount == 0 ? 'Ready' : '$_lastMatchCount',
                    color: const Color(0xff38bdf8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xffa855f7)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _movesLeft == 0 && !_isBusy ? _resetGame : null,
              child: const Text('Reset level'),
            ),
          ),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileSize = constraints.maxWidth / _size;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) =>
                      _handleBoardPanStart(details, tileSize),
                  onPanUpdate: (details) =>
                      _handleBoardPanUpdate(details, tileSize),
                  onPanEnd: _handleBoardPanEnd,
                  onPanCancel: _clearDragSelection,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xff6d28d9).withValues(alpha: 0.28),
                          const Color(0xff1d4ed8).withValues(alpha: 0.12),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _size * _size,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _size,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                              childAspectRatio: 1,
                            ),
                        itemBuilder: (context, index) {
                          final row = index ~/ _size;
                          final col = index % _size;
                          final selected =
                              _selectedRow == row && _selectedCol == col;
                          final value = _board[row][col];
                          if (value == -1) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: () => _handleTap(row, col),
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 140),
                              scale: selected ? 1.06 : 1,
                              child: _CandyTile(
                                style: _styles[value],
                                selected: selected,
                              ),
                            ),
                          );
                        },
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

class _CandyInfoPill extends StatelessWidget {
  const _CandyInfoPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CandyTile extends StatelessWidget {
  const _CandyTile({required this.style, required this.selected});

  final _CandyStyle style;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.14);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            style.baseColor.withValues(alpha: 0.9),
            Color.lerp(style.baseColor, Colors.white, 0.24)!,
          ],
        ),
        border: Border.all(color: borderColor, width: selected ? 2.8 : 1.1),
        boxShadow: [
          BoxShadow(
            color: style.baseColor.withValues(alpha: 0.32),
            blurRadius: selected ? 18 : 12,
            spreadRadius: selected ? 1 : 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 7,
            child: Container(
              width: 18,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.26),
              ),
            ),
          ),
          Center(child: _CandyShape(style: style)),
        ],
      ),
    );
  }
}

class _CandyShape extends StatelessWidget {
  const _CandyShape({required this.style});

  final _CandyStyle style;

  @override
  Widget build(BuildContext context) {
    switch (style.symbol) {
      case _CandySymbol.round:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: style.glowColor,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.26),
                blurRadius: 10,
              ),
            ],
          ),
        );
      case _CandySymbol.square:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: style.glowColor,
          ),
        );
      case _CandySymbol.diamond:
        return Transform.rotate(
          angle: pi / 4,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: style.glowColor,
            ),
          ),
        );
      case _CandySymbol.lozenge:
        return Container(
          width: 32,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: style.glowColor,
          ),
        );
      case _CandySymbol.drop:
        return Transform.rotate(
          angle: -0.35,
          child: Icon(
            Icons.water_drop_rounded,
            size: 28,
            color: style.glowColor,
          ),
        );
      case _CandySymbol.star:
        return Icon(Icons.star_rounded, size: 28, color: style.glowColor);
    }
  }
}

enum _CandySymbol { round, square, diamond, lozenge, drop, star }

class _CandyStyle {
  const _CandyStyle({
    required this.baseColor,
    required this.glowColor,
    required this.symbol,
  });

  final Color baseColor;
  final Color glowColor;
  final _CandySymbol symbol;
}
