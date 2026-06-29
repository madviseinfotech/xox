import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class TapSequenceScreen extends StatefulWidget {
  const TapSequenceScreen({super.key});

  @override
  State<TapSequenceScreen> createState() => _TapSequenceScreenState();
}

class _TapSequenceScreenState extends State<TapSequenceScreen> {
  final Random _random = Random();

  late List<int> _tiles;
  int _level = 1;
  int _nextNumber = 1;
  int _bestLevel = 0;
  String _message = 'Tap the numbers in ascending order.';

  @override
  void initState() {
    super.initState();
    _tiles = _buildTiles();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestLevel = snapshot.tapSequenceBestLevel;
    });
  }

  int get _tileCount => min(_level + 3, 16);

  int get _crossAxisCount {
    if (_tileCount <= 4) return 2;
    if (_tileCount <= 9) return 3;
    return 4;
  }

  List<int> _buildTiles() {
    final values = List<int>.generate(_tileCount, (index) => index + 1);
    values.shuffle(_random);
    return values;
  }

  Future<void> _pickTile(int value) async {
    if (value != _nextNumber) {
      setState(() {
        _nextNumber = 1;
        _tiles = _buildTiles();
        _message = 'Wrong tap. Start again from 1.';
      });
      return;
    }

    final completedRound = value == _tileCount;
    if (!completedRound) {
      setState(() {
        _nextNumber += 1;
        _message = 'Good. Now tap $_nextNumber.';
      });
      return;
    }

    final clearedLevel = _level;
    final nextLevel = _level < 13 ? _level + 1 : _level;
    if (clearedLevel > _bestLevel) {
      await GameStatsStore.instance.recordTapSequenceBestLevel(clearedLevel);
      if (!mounted) return;
      setState(() {
        _bestLevel = clearedLevel;
      });
    }

    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();

    if (!mounted) return;
    setState(() {
      _level = nextLevel;
      _nextNumber = 1;
      _tiles = _buildTiles();
      _message = nextLevel == clearedLevel
          ? 'Perfect run. You cleared the max board.'
          : 'Nice. Level ${clearedLevel + 1} is ready.';
    });
  }

  void _resetGame() {
    setState(() {
      _level = 1;
      _nextNumber = 1;
      _tiles = _buildTiles();
      _message = 'Tap the numbers in ascending order.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff22c55e), Color(0xff0ea5e9)];
    return GameScaffold(
      title: 'Tap Sequence',
      subtitle: 'Tap every number in order before the board grows.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Level',
            leftValue: _level.toString(),
            rightLabel: 'Best',
            rightValue: _bestLevel.toString(),
            footer: 'Board $_tileCount tiles • Next: $_nextNumber',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap from low to high',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A wrong tap reshuffles the board and sends you back to 1.',
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
                    final alreadyPicked = value < _nextNumber;
                    return ElevatedButton(
                      onPressed: alreadyPicked ? null : () => _pickTile(value),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alreadyPicked
                            ? const Color(0xff22c55e).withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xff22c55e,
                        ).withValues(alpha: 0.18),
                        disabledForegroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: alreadyPicked
                                ? const Color(0xff22c55e)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: _crossAxisCount == 4 ? 24 : 28,
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
