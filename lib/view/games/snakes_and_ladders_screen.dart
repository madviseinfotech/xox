import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_mode_selector.dart';
import 'game_scaffold.dart';
import 'game_stats_store.dart';

class SnakesAndLaddersScreen extends StatefulWidget {
  const SnakesAndLaddersScreen({super.key});

  @override
  State<SnakesAndLaddersScreen> createState() => _SnakesAndLaddersScreenState();
}

class _SnakesAndLaddersScreenState extends State<SnakesAndLaddersScreen> {
  static const int _boardEnd = 100;
  static const int _crossAxisCount = 10;

  final Random _random = Random();
  final Map<int, int> _jumps = const {
    4: 14,
    9: 31,
    20: 38,
    28: 84,
    40: 59,
    51: 67,
    63: 81,
    71: 91,
    17: 7,
    54: 34,
    62: 19,
    64: 60,
    87: 24,
    93: 73,
    95: 75,
    99: 78,
  };

  _RaceMode _mode = _RaceMode.computer;
  int _playerPos = 1;
  int _opponentPos = 1;
  int _lastRoll = 0;
  int _wins = 0;
  String _message = 'Roll the dice and race to square 100.';
  bool _matchOver = false;
  bool _isPlayerOneTurn = true;
  bool _isAnimatingMove = false;
  int? _jumpSource;
  int? _jumpTarget;
  bool _jumpIsLadder = false;

  @override
  void initState() {
    super.initState();
    _loadWins();
  }

  Future<void> _loadWins() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _wins = snapshot.snakesAndLaddersWins;
    });
  }

  Future<void> _rollTurn() async {
    if (_matchOver || _isAnimatingMove) return;
    if (_mode == _RaceMode.twoPlayers) {
      await _rollTwoPlayerTurn();
      return;
    }

    final playerRoll = _random.nextInt(6) + 1;
    final cpuRoll = _random.nextInt(6) + 1;
    setState(() {
      _isAnimatingMove = true;
      _lastRoll = playerRoll;
    });
    final playerNext = await _animateMove(
      isPlayer: true,
      roll: playerRoll,
      actorLabel: 'You',
    );
    final playerWon = playerNext >= _boardEnd;

    if (playerWon) {
      setState(() {
        _matchOver = true;
        _isAnimatingMove = false;
        _message = 'You reached 100 first and won the race.';
      });
      await GameStatsStore.instance.incrementSnakesAndLaddersWins();
      if (!mounted) return;
      setState(() {
        _wins += 1;
      });
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      return;
    }

    if (!mounted) return;
    setState(() {
      _lastRoll = cpuRoll;
    });
    final cpuNext = await _animateMove(
      isPlayer: false,
      roll: cpuRoll,
      actorLabel: 'CPU',
    );
    final cpuWon = cpuNext >= _boardEnd;
    if (!mounted) return;
    setState(() {
      _isAnimatingMove = false;
      if (cpuWon) {
        _matchOver = true;
        _message = 'CPU reached 100 first. Try another run.';
      } else {
        _message =
            'You rolled $playerRoll, CPU rolled $cpuRoll. Keep climbing.';
      }
    });
    if (cpuWon) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
    }
  }

  Future<void> _rollTwoPlayerTurn() async {
    if (_isAnimatingMove) return;
    final roll = _random.nextInt(6) + 1;
    setState(() {
      _isAnimatingMove = true;
      _lastRoll = roll;
    });
    if (_isPlayerOneTurn) {
      final next = await _animateMove(
        isPlayer: true,
        roll: roll,
        actorLabel: 'Player 1',
      );
      if (!mounted) return;
      final playerWon = next >= _boardEnd;
      setState(() {
        if (playerWon) {
          _matchOver = true;
          _isAnimatingMove = false;
          _message = 'Player 1 reached 100 first.';
        } else {
          _isPlayerOneTurn = false;
          _isAnimatingMove = false;
          _message = 'Player 1 rolled $roll. Pass to Player 2.';
        }
      });
      if (playerWon) {
        await GameStatsStore.instance.incrementSnakesAndLaddersWins();
        if (!mounted) return;
        setState(() {
          _wins += 1;
        });
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
      }
      return;
    }

    final next = await _animateMove(
      isPlayer: false,
      roll: roll,
      actorLabel: 'Player 2',
    );
    if (!mounted) return;
    final playerTwoWon = next >= _boardEnd;
    setState(() {
      if (playerTwoWon) {
        _matchOver = true;
        _isAnimatingMove = false;
        _message = 'Player 2 reached 100 first.';
      } else {
        _isPlayerOneTurn = true;
        _isAnimatingMove = false;
        _message = 'Player 2 rolled $roll. Player 1, your turn.';
      }
    });
    if (playerTwoWon) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
    }
  }

  Future<int> _animateMove({
    required bool isPlayer,
    required int roll,
    required String actorLabel,
  }) async {
    final start = isPlayer ? _playerPos : _opponentPos;
    final attempted = start + roll;
    if (attempted > _boardEnd) {
      if (mounted) {
        setState(() {
          _message =
              '$actorLabel rolled $roll, but needs exact steps to reach 100.';
          _jumpSource = null;
          _jumpTarget = null;
        });
      }
      await Future<void>.delayed(const Duration(milliseconds: 320));
      return start;
    }

    final landed = attempted;
    if (mounted) {
      setState(() {
        _message = '$actorLabel rolled $roll. Moving...';
        _jumpSource = null;
        _jumpTarget = null;
      });
    }
    for (var square = start + 1; square <= landed; square++) {
      await Future<void>.delayed(const Duration(milliseconds: 110));
      if (!mounted) return isPlayer ? _playerPos : _opponentPos;
      setState(() {
        if (isPlayer) {
          _playerPos = square;
        } else {
          _opponentPos = square;
        }
      });
    }

    final jumpTarget = _jumps[landed];
    if (jumpTarget == null) {
      return landed;
    }

    final isLadder = jumpTarget > landed;
    if (mounted) {
      setState(() {
        _jumpSource = landed;
        _jumpTarget = jumpTarget;
        _jumpIsLadder = isLadder;
        _message = isLadder
            ? '$actorLabel found a ladder. Climb to $jumpTarget.'
            : '$actorLabel hit a snake. Slide to $jumpTarget.';
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return jumpTarget;

    if (isLadder) {
      for (var square = landed + 1; square <= jumpTarget; square++) {
        await Future<void>.delayed(const Duration(milliseconds: 70));
        if (!mounted) return jumpTarget;
        setState(() {
          if (isPlayer) {
            _playerPos = square;
          } else {
            _opponentPos = square;
          }
        });
      }
    } else {
      for (var square = landed - 1; square >= jumpTarget; square--) {
        await Future<void>.delayed(const Duration(milliseconds: 70));
        if (!mounted) return jumpTarget;
        setState(() {
          if (isPlayer) {
            _playerPos = square;
          } else {
            _opponentPos = square;
          }
        });
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return jumpTarget;
    setState(() {
      _jumpSource = null;
      _jumpTarget = null;
    });
    return jumpTarget;
  }

  void _resetMatch() {
    setState(() {
      _playerPos = 1;
      _opponentPos = 1;
      _lastRoll = 0;
      _matchOver = false;
      _isPlayerOneTurn = true;
      _isAnimatingMove = false;
      _jumpSource = null;
      _jumpTarget = null;
      _message = _mode == _RaceMode.computer
          ? 'Roll the dice and race the CPU to square 100.'
          : 'Player 1 starts the race to square 100.';
    });
  }

  void _changeMode(_RaceMode mode) {
    setState(() {
      _mode = mode;
    });
    _resetMatch();
  }

  int _squareForIndex(int index) {
    final rowFromTop = index ~/ _crossAxisCount;
    final rowFromBottom = (_crossAxisCount - 1) - rowFromTop;
    final base = rowFromBottom * _crossAxisCount + 1;
    final column = index % _crossAxisCount;
    final isLeftToRight = rowFromBottom.isEven;
    return isLeftToRight
        ? base + column
        : base + (_crossAxisCount - 1 - column);
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Snakes & Ladders',
      subtitle: 'Full 100-square race.',
      accent: const [Color(0xff7c3aed), Color(0xffec4899)],
      compactHeader: true,
      minimalHeader: true,
      backgroundMusicAsset: 'music/begin.mp3',
      child: Column(
        children: [
          GameModeSelector<_RaceMode>(
            selectedValue: _mode,
            options: _RaceMode.values
                .map((mode) => GameModeOption(value: mode, label: mode.label))
                .toList(growable: false),
            onChanged: _changeMode,
            accentColor: const Color(0xffec4899),
            dense: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CompactMetricCard(
                  label: _mode == _RaceMode.computer ? 'You' : 'Player 1',
                  value: _playerPos.toString(),
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CompactMetricCard(
                  label: _mode == _RaceMode.computer ? 'CPU' : 'Player 2',
                  value: _opponentPos.toString(),
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CompactMetricCard(
                  label: 'Last roll',
                  value: _lastRoll == 0 ? '-' : _lastRoll.toString(),
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InlineStatusStrip(
            message: _message,
            accent: _matchOver
                ? const Color(0xffec4899)
                : const Color(0xffa855f7),
            compact: true,
            highlight: _matchOver,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: CompactMetricCard(
                  label: 'Wins',
                  value: _wins.toString(),
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _matchOver || _isAnimatingMove ? null : _rollTurn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isAnimatingMove
                        ? 'Moving...'
                        : _mode == _RaceMode.computer
                        ? 'Roll dice'
                        : (_isPlayerOneTurn
                              ? 'Player 1 roll'
                              : 'Player 2 roll'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          TextButton(onPressed: _resetMatch, child: const Text('New race')),
          const SizedBox(height: 8),
          GamePanel(
            padding: const EdgeInsets.all(6),
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _boardEnd,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final square = _squareForIndex(index);
                  final playerHere = square == _playerPos;
                  final opponentHere = square == _opponentPos;
                  final jump = _jumps[square];
                  final isLadder = jump != null && jump > square;
                  final isSnake = jump != null && jump < square;
                  final isHighlighted =
                      square == _jumpSource || square == _jumpTarget;
                  final highlightColor = _jumpIsLadder
                      ? const Color(0xff22c55e)
                      : const Color(0xffef4444);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: playerHere
                          ? const Color(0xffc084fc)
                          : opponentHere
                          ? const Color(0xfffb7185)
                          : isHighlighted
                          ? highlightColor.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: isHighlighted
                            ? highlightColor.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.08),
                        width: isHighlighted ? 1.4 : 1,
                      ),
                      boxShadow: isHighlighted
                          ? [
                              BoxShadow(
                                color: highlightColor.withValues(alpha: 0.24),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 4,
                          top: 3,
                          child: Text(
                            square.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            isLadder
                                ? '🪜'
                                : isSnake
                                ? '🐍'
                                : '',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        if (playerHere || opponentHere)
                          Positioned(
                            right: 4,
                            bottom: 3,
                            child: Text(
                              playerHere && opponentHere
                                  ? 'B'
                                  : playerHere
                                  ? (_mode == _RaceMode.computer ? 'Y' : '1')
                                  : (_mode == _RaceMode.computer ? 'C' : '2'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _RaceMode {
  computer('Play with computer'),
  twoPlayers('Play with player 2');

  const _RaceMode(this.label);
  final String label;
}
