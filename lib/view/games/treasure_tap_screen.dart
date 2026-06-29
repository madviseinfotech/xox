import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class TreasureTapScreen extends StatefulWidget {
  const TreasureTapScreen({super.key});

  @override
  State<TreasureTapScreen> createState() => _TreasureTapScreenState();
}

class _TreasureTapScreenState extends State<TreasureTapScreen> {
  final Random _random = Random();

  late List<_TreasureTile> _tiles;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  int _treasuresLeft = 0;
  String _message = 'Open tiles and collect every treasure.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  int get _tileCount => min(9 + ((_round - 1) * 3), 18);

  int get _crossAxisCount => _tileCount <= 12 ? 3 : 4;

  void _startRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final tileCount = min(9 + ((nextRound - 1) * 3), 18);
    final treasureCount = min(3 + ((nextRound - 1) ~/ 2), 6);
    final bombCount = min(2 + ((nextRound - 1) ~/ 3), 4);
    final tiles = <_TreasureTile>[];

    for (var i = 0; i < treasureCount; i++) {
      tiles.add(const _TreasureTile(kind: _TreasureKind.treasure));
    }
    for (var i = 0; i < bombCount; i++) {
      tiles.add(const _TreasureTile(kind: _TreasureKind.bomb));
    }
    while (tiles.length < tileCount) {
      tiles.add(const _TreasureTile(kind: _TreasureKind.empty));
    }
    tiles.shuffle(_random);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _tiles = tiles;
      _treasuresLeft = treasureCount;
      _message =
          'Round $nextRound: find $treasureCount treasures and avoid bombs.';
    });
  }

  Future<void> _revealTile(int index) async {
    final tile = _tiles[index];
    if (tile.revealed || _lives == 0) return;

    final updatedTiles = List<_TreasureTile>.from(_tiles);
    updatedTiles[index] = tile.copyWith(revealed: true);

    switch (tile.kind) {
      case _TreasureKind.treasure:
        final nextTreasuresLeft = _treasuresLeft - 1;
        setState(() {
          _tiles = updatedTiles;
          _score += 1;
          _treasuresLeft = nextTreasuresLeft;
          _message = nextTreasuresLeft == 0
              ? 'Treasure round clear. Next board coming up.'
              : 'Nice find. $nextTreasuresLeft treasures left.';
        });

        if (nextTreasuresLeft != 0) return;

        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        if (!mounted) return;
        setState(() {
          _round += 1;
        });
        _startRound();
        return;

      case _TreasureKind.bomb:
        final nextLives = _lives - 1;
        if (nextLives <= 0) {
          setState(() {
            _tiles = updatedTiles;
            _lives = 0;
            _message = 'Boom. Game over. Tap reset to start again.';
          });
          GameInterstitialService.instance.registerRoundCompletion();
          await GameInterstitialService.instance.maybeShow();
          return;
        }

        setState(() {
          _tiles = updatedTiles;
          _lives = nextLives;
          _message = 'Bomb hit. $nextLives lives left.';
        });
        return;

      case _TreasureKind.empty:
        setState(() {
          _tiles = updatedTiles;
          _message = 'Empty tile. Keep searching.';
        });
        return;
    }
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xfff59e0b), Color(0xfff97316)];
    return GameScaffold(
      title: 'Treasure Tap',
      subtitle: 'Reveal tiles, collect treasure, and dodge the bombs.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Treasure left: $_treasuresLeft',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Treasure board',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Treasure gives points, bombs cost a life, and empty tiles just waste a move.',
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
                    final tile = _tiles[index];
                    return ElevatedButton(
                      onPressed: tile.revealed || _lives == 0
                          ? null
                          : () => _revealTile(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _backgroundFor(tile),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _backgroundFor(tile),
                        disabledForegroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: tile.revealed
                                ? Colors.white.withValues(alpha: 0.18)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: Text(
                        _labelFor(tile),
                        style: const TextStyle(
                          fontSize: 26,
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

  Color _backgroundFor(_TreasureTile tile) {
    if (!tile.revealed) return Colors.white.withValues(alpha: 0.08);
    switch (tile.kind) {
      case _TreasureKind.treasure:
        return const Color(0xff22c55e).withValues(alpha: 0.24);
      case _TreasureKind.bomb:
        return const Color(0xffef4444).withValues(alpha: 0.24);
      case _TreasureKind.empty:
        return Colors.white.withValues(alpha: 0.06);
    }
  }

  String _labelFor(_TreasureTile tile) {
    if (!tile.revealed) return '?';
    switch (tile.kind) {
      case _TreasureKind.treasure:
        return 'G';
      case _TreasureKind.bomb:
        return 'X';
      case _TreasureKind.empty:
        return '0';
    }
  }
}

enum _TreasureKind { treasure, bomb, empty }

class _TreasureTile {
  const _TreasureTile({required this.kind, this.revealed = false});

  final _TreasureKind kind;
  final bool revealed;

  _TreasureTile copyWith({bool? revealed}) {
    return _TreasureTile(kind: kind, revealed: revealed ?? this.revealed);
  }
}
