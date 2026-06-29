import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class SonarSweepScreen extends StatefulWidget {
  const SonarSweepScreen({super.key});

  @override
  State<SonarSweepScreen> createState() => _SonarSweepScreenState();
}

class _SonarSweepScreenState extends State<SonarSweepScreen> {
  final Random _random = Random();

  static const int _gridSize = 5;
  static const int _maxLives = 3;
  static const int _maxProbes = 6;

  late Point<int> _target;
  final Map<Point<int>, String> _revealedClues = <Point<int>, String>{};

  int _round = 1;
  int _score = 0;
  int _lives = _maxLives;
  int _probesLeft = _maxProbes;
  String _message = 'Use sonar probes to find the hidden signal.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  bool get _gameOver => _lives == 0;

  void _startRound({bool resetGame = false}) {
    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = _maxLives;
      }
      _target = Point<int>(
        _random.nextInt(_gridSize),
        _random.nextInt(_gridSize),
      );
      _revealedClues.clear();
      _probesLeft = _maxProbes;
      _message =
          'Sweep the grid. You have $_maxProbes probes to lock the signal.';
    });
  }

  Future<void> _scanCell(int row, int col) async {
    if (_gameOver) return;

    final guess = Point<int>(col, row);
    if (_revealedClues.containsKey(guess)) return;

    if (guess == _target) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message =
            'Signal locked at ${_cellLabel(row, col)}. New sector incoming.';
      });
      _startRound();
      return;
    }

    final nextProbes = _probesLeft - 1;
    final clue = _buildClue(guess);

    if (nextProbes <= 0) {
      final nextLives = _lives - 1;
      if (nextLives <= 0) {
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        if (!mounted) return;
        setState(() {
          _probesLeft = 0;
          _lives = 0;
          _revealedClues[guess] = clue;
          _message =
              'Signal lost. The target was at ${_cellLabel(_target.y, _target.x)}.';
        });
        return;
      }

      setState(() {
        _revealedClues[guess] = clue;
        _lives = nextLives;
        _message =
            'Sector escaped. The target was at ${_cellLabel(_target.y, _target.x)}. Lives left: $nextLives.';
      });
      _startRound();
      return;
    }

    setState(() {
      _revealedClues[guess] = clue;
      _probesLeft = nextProbes;
      _message = clue;
    });
  }

  String _buildClue(Point<int> guess) {
    final rowDelta = _target.y - guess.y;
    final colDelta = _target.x - guess.x;
    final distance = rowDelta.abs() + colDelta.abs();

    String range;
    if (distance == 1) {
      range = 'Very close';
    } else if (distance <= 2) {
      range = 'Close';
    } else if (distance <= 4) {
      range = 'Far';
    } else {
      range = 'Very far';
    }

    final vertical = rowDelta == 0
        ? ''
        : rowDelta < 0
        ? 'north'
        : 'south';
    final horizontal = colDelta == 0
        ? ''
        : colDelta < 0
        ? 'west'
        : 'east';
    final direction = [
      vertical,
      horizontal,
    ].where((item) => item.isNotEmpty).join('-');

    return direction.isEmpty
        ? '$range signal echo.'
        : '$range signal echo. Drift $direction from ${_cellLabel(guess.y, guess.x)}.';
  }

  String _cellLabel(int row, int col) {
    final letters = ['A', 'B', 'C', 'D', 'E'];
    return '${letters[col]}${row + 1}';
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff0ea5e9), Color(0xff14b8a6)];
    return GameScaffold(
      title: 'Sonar Sweep',
      subtitle:
          'Track a hidden signal with clue-based probes before it slips away.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives/$_maxLives • Probes left: $_probesLeft',
          ),
          const SizedBox(height: 18),
          StatusCard(
            headline: 'Sonar rules',
            message:
                'Tap a sector to scan it. Each miss gives a distance and direction clue. Find the signal before you run out of probes.',
            accent: accent.last,
            highlight: true,
          ),
          const SizedBox(height: 14),
          StatusCard(message: _message, accent: accent.first),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: List<Widget>.generate(_gridSize, (row) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: row == _gridSize - 1 ? 0 : 10,
                  ),
                  child: Row(
                    children: List<Widget>.generate(_gridSize, (col) {
                      final guess = Point<int>(col, row);
                      final clue = _revealedClues[guess];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: col == _gridSize - 1 ? 0 : 10,
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ElevatedButton(
                              onPressed: clue != null || _gameOver
                                  ? null
                                  : () => _scanCell(row, col),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                                disabledBackgroundColor: Colors.white
                                    .withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                              ),
                              child: clue == null
                                  ? Text(
                                      _cellLabel(row, col),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _cellLabel(row, col),
                                          style: TextStyle(
                                            color: accent.last,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          clue.split('.').first,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset sweep', onPressed: _resetGame),
        ],
      ),
    );
  }
}
