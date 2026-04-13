import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class LaneSwitchScreen extends StatefulWidget {
  const LaneSwitchScreen({super.key});

  @override
  State<LaneSwitchScreen> createState() => _LaneSwitchScreenState();
}

class _LaneSwitchScreenState extends State<LaneSwitchScreen> {
  final Random _random = Random();

  late List<int> _safeLanes;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  String _message = 'Pick the safe lane in each row to move forward.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  int get _rowCount => min(4 + (_round - 1), 7);

  void _startRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final rows = min(4 + (nextRound - 1), 7);
    final safeLanes = List<int>.generate(rows, (_) => _random.nextInt(3));

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _safeLanes = safeLanes;
      _message = 'Round $nextRound: cross $rows rows by choosing safe lanes.';
    });
  }

  Future<void> _pickLane(int row, int lane) async {
    if (_lives == 0 || row != (_score % _rowCount)) return;

    final safeLane = _safeLanes[row];
    if (lane != safeLane) {
      final nextLives = _lives - 1;
      if (nextLives <= 0) {
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        if (!mounted) return;
        setState(() {
          _lives = 0;
          _message = 'Crash. Tap reset to start over.';
        });
        return;
      }

      setState(() {
        _lives = nextLives;
        _message = 'Blocked lane. $nextLives lives left.';
      });
      return;
    }

    final nextScore = _score + 1;
    final clearedRound = (nextScore % _rowCount) == 0;
    if (!clearedRound) {
      setState(() {
        _score = nextScore;
        _message = 'Safe move. Keep going to the next row.';
      });
      return;
    }

    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _score = nextScore;
      _round += 1;
      _message = 'Great run. New lane pattern loaded.';
    });
    _startRound();
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff22c55e), Color(0xff16a34a)];
    final currentRow = _score % _rowCount;
    return GameScaffold(
      title: 'Lane Switch',
      subtitle: 'Choose the safe path row by row and keep your run alive.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Active row: ${currentRow + 1}/$_rowCount',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick one lane per row',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Column(
                  children: List.generate(_rowCount, (row) {
                    final enabled = row == currentRow && _lives > 0;
                    final cleared = row < currentRow;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: List.generate(3, (lane) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: lane == 0 ? 0 : 6,
                                right: lane == 2 ? 0 : 6,
                              ),
                              child: ElevatedButton(
                                onPressed: enabled
                                    ? () => _pickLane(row, lane)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cleared
                                      ? const Color(
                                          0xff22c55e,
                                        ).withValues(alpha: 0.22)
                                      : Colors.white.withValues(alpha: 0.08),
                                  disabledBackgroundColor: cleared
                                      ? const Color(
                                          0xff22c55e,
                                        ).withValues(alpha: 0.22)
                                      : Colors.white.withValues(alpha: 0.06),
                                  minimumSize: const Size.fromHeight(54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  cleared ? 'OK' : 'Lane ${lane + 1}',
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
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
