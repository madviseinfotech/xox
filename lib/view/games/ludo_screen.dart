import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_mode_selector.dart';
import 'game_scaffold.dart';
import 'game_stats_store.dart';

class LudoScreen extends StatefulWidget {
  const LudoScreen({super.key});

  @override
  State<LudoScreen> createState() => _LudoScreenState();
}

class _LudoScreenState extends State<LudoScreen> {
  _LudoScreenState()
    : _selectedColors = [
        _LudoColor.red,
        _LudoColor.blue,
        _LudoColor.green,
        _LudoColor.yellow,
      ],
      _tokens = List.generate(4, (_) => List<int>.filled(4, -1));

  static const int _trackLength = 52;
  static const int _finishSteps = 57;
  static const List<int> _safeSquares = [0, 8, 13, 21, 26, 34, 39, 47];
  static const List<_BoardPoint> _track = [
    _BoardPoint(6, 1),
    _BoardPoint(6, 2),
    _BoardPoint(6, 3),
    _BoardPoint(6, 4),
    _BoardPoint(6, 5),
    _BoardPoint(5, 6),
    _BoardPoint(4, 6),
    _BoardPoint(3, 6),
    _BoardPoint(2, 6),
    _BoardPoint(1, 6),
    _BoardPoint(0, 6),
    _BoardPoint(0, 7),
    _BoardPoint(0, 8),
    _BoardPoint(1, 8),
    _BoardPoint(2, 8),
    _BoardPoint(3, 8),
    _BoardPoint(4, 8),
    _BoardPoint(5, 8),
    _BoardPoint(6, 9),
    _BoardPoint(6, 10),
    _BoardPoint(6, 11),
    _BoardPoint(6, 12),
    _BoardPoint(6, 13),
    _BoardPoint(6, 14),
    _BoardPoint(7, 14),
    _BoardPoint(8, 14),
    _BoardPoint(8, 13),
    _BoardPoint(8, 12),
    _BoardPoint(8, 11),
    _BoardPoint(8, 10),
    _BoardPoint(8, 9),
    _BoardPoint(9, 8),
    _BoardPoint(10, 8),
    _BoardPoint(11, 8),
    _BoardPoint(12, 8),
    _BoardPoint(13, 8),
    _BoardPoint(14, 8),
    _BoardPoint(14, 7),
    _BoardPoint(14, 6),
    _BoardPoint(13, 6),
    _BoardPoint(12, 6),
    _BoardPoint(11, 6),
    _BoardPoint(10, 6),
    _BoardPoint(9, 6),
    _BoardPoint(8, 5),
    _BoardPoint(8, 4),
    _BoardPoint(8, 3),
    _BoardPoint(8, 2),
    _BoardPoint(8, 1),
    _BoardPoint(8, 0),
    _BoardPoint(7, 0),
    _BoardPoint(6, 0),
  ];
  static const Map<_LudoColor, int> _startOffsets = {
    _LudoColor.red: 0,
    _LudoColor.blue: 13,
    _LudoColor.yellow: 26,
    _LudoColor.green: 39,
  };
  static const Map<_LudoColor, List<_BoardPoint>> _homePaths = {
    _LudoColor.red: [
      _BoardPoint(1, 7),
      _BoardPoint(2, 7),
      _BoardPoint(3, 7),
      _BoardPoint(4, 7),
      _BoardPoint(5, 7),
      _BoardPoint(6, 7),
    ],
    _LudoColor.blue: [
      _BoardPoint(7, 13),
      _BoardPoint(7, 12),
      _BoardPoint(7, 11),
      _BoardPoint(7, 10),
      _BoardPoint(7, 9),
      _BoardPoint(7, 8),
    ],
    _LudoColor.yellow: [
      _BoardPoint(13, 7),
      _BoardPoint(12, 7),
      _BoardPoint(11, 7),
      _BoardPoint(10, 7),
      _BoardPoint(9, 7),
      _BoardPoint(8, 7),
    ],
    _LudoColor.green: [
      _BoardPoint(7, 1),
      _BoardPoint(7, 2),
      _BoardPoint(7, 3),
      _BoardPoint(7, 4),
      _BoardPoint(7, 5),
      _BoardPoint(7, 6),
    ],
  };
  static const Map<_LudoColor, List<_BoardPoint>> _baseSlots = {
    _LudoColor.red: [
      _BoardPoint(2, 2),
      _BoardPoint(2, 4),
      _BoardPoint(4, 2),
      _BoardPoint(4, 4),
    ],
    _LudoColor.blue: [
      _BoardPoint(2, 10),
      _BoardPoint(2, 12),
      _BoardPoint(4, 10),
      _BoardPoint(4, 12),
    ],
    _LudoColor.yellow: [
      _BoardPoint(10, 10),
      _BoardPoint(10, 12),
      _BoardPoint(12, 10),
      _BoardPoint(12, 12),
    ],
    _LudoColor.green: [
      _BoardPoint(10, 2),
      _BoardPoint(10, 4),
      _BoardPoint(12, 2),
      _BoardPoint(12, 4),
    ],
  };
  final Random _random = Random();
  final List<_LudoColor> _selectedColors;
  final List<List<int>> _tokens;

  _LudoMode _mode = _LudoMode.computer;
  int _currentSeat = 0;
  int _lastRoll = 0;
  int? _displayRoll;
  int _wins = 0;
  int? _pendingRoll;
  bool _rolling = false;
  bool _matchOver = false;
  String _message = 'Choose mode, pick colors, and roll the dice.';
  List<int> _movableTokens = const [];
  List<_CaptureAnimation> _captureAnimations = const [];

  int get _activeSeatCount => switch (_mode) {
    _LudoMode.computer => 2,
    _LudoMode.twoPlayers => 2,
    _LudoMode.threePlayers => 3,
    _LudoMode.fourPlayers => 4,
  };

  bool get _isComputerMode => _mode == _LudoMode.computer;
  bool get _isComputerTurn => _isComputerMode && _currentSeat == 1;

  @override
  void initState() {
    super.initState();
    _loadWins();
  }

  Future<void> _loadWins() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _wins = snapshot.ludoWins;
    });
  }

  Future<void> _rollDice() async {
    if (_rolling || _pendingRoll != null || _matchOver) return;

    final seat = _currentSeat;
    final roll = _random.nextInt(6) + 1;
    final movable = _movableTokensForSeat(seat, roll);
    setState(() {
      _rolling = true;
      _displayRoll = _random.nextInt(6) + 1;
      _message = '${_seatLabel(seat)} is rolling the dice...';
    });
    for (var step = 0; step < 7; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 75));
      if (!mounted) return;
      setState(() {
        _displayRoll = step == 6 ? roll : _random.nextInt(6) + 1;
      });
    }
    if (!mounted) return;
    setState(() {
      _rolling = false;
      _lastRoll = roll;
      _pendingRoll = roll;
      _movableTokens = movable;
      _message = movable.isEmpty
          ? '${_seatLabel(seat)} cannot move on $roll.'
          : movable.length == 1
          ? '${_seatLabel(seat)} auto-moves token ${movable.first + 1}.'
          : '${_seatLabel(seat)} rolled $roll. Choose a token to move.';
    });

    if (movable.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      await _finishTurn(extraTurn: false);
      return;
    }

    if (movable.length == 1) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted || _pendingRoll == null) return;
      await _moveToken(movable.first);
      return;
    }

    if (_isComputerTurn) {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted || _pendingRoll == null) return;
      await _moveToken(_bestTokenForComputer(seat, roll, movable));
    }
  }

  List<int> _movableTokensForSeat(int seat, int roll) {
    final tokens = _tokens[seat];
    final movable = <int>[];
    for (var index = 0; index < tokens.length; index++) {
      final position = tokens[index];
      if (position == -1 && roll == 6) {
        movable.add(index);
      } else if (position >= 0 && position < _finishSteps) {
        if (position + roll <= _finishSteps) {
          movable.add(index);
        }
      }
    }
    return movable;
  }

  Future<void> _onTokenTap(int seat, int tokenIndex) async {
    if (seat != _currentSeat ||
        _pendingRoll == null ||
        _rolling ||
        _matchOver) {
      return;
    }
    if (!_movableTokens.contains(tokenIndex)) return;
    await _moveToken(tokenIndex);
  }

  Future<void> _moveToken(int tokenIndex) async {
    final seat = _currentSeat;
    final roll = _pendingRoll;
    if (roll == null) return;
    if (!_movableTokens.contains(tokenIndex)) return;

    final from = _tokens[seat][tokenIndex];
    final to = from == -1 ? 0 : from + roll;
    setState(() {
      _rolling = true;
      _pendingRoll = null;
      _movableTokens = const [];
      _message = '${_seatLabel(seat)} moved token ${tokenIndex + 1}.';
    });

    await _animateTokenMove(
      seat: seat,
      tokenIndex: tokenIndex,
      from: from,
      to: to,
    );
    if (!mounted) return;

    if (to >= 0 && to < _trackLength) {
      final captured = await _captureOpponentsIfNeeded(seat, to);
      if (captured.isNotEmpty) {
        setState(() {
          _message =
              '${_seatLabel(seat)} sent ${captured.map(_seatLabel).join(', ')} back home.';
        });
      }
    }

    final allFinished = _tokens[seat].every(
      (position) => position == _finishSteps,
    );
    if (allFinished) {
      if (!_isComputerMode || seat == 0) {
        await GameStatsStore.instance.incrementLudoWins();
      }
      if (!mounted) return;
      setState(() {
        _rolling = false;
        _matchOver = true;
        _message = '${_seatLabel(seat)} brought all 4 tokens home and won.';
        if (!_isComputerMode || seat == 0) {
          _wins += 1;
        }
      });
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      return;
    }

    final extraTurn = roll == 6;
    await _finishTurn(extraTurn: extraTurn);
  }

  Future<void> _finishTurn({required bool extraTurn}) async {
    if (!mounted) return;
    final seat = _currentSeat;
    final nextSeat = extraTurn ? seat : _nextSeat(seat);
    setState(() {
      _rolling = false;
      _pendingRoll = null;
      _movableTokens = const [];
      _currentSeat = nextSeat;
      _message = extraTurn
          ? '${_seatLabel(seat)} rolled 6 and gets another turn.'
          : '${_seatLabel(nextSeat)} turn.';
    });
    if (_isComputerTurn && !_matchOver) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      await _rollDice();
    }
  }

  int _nextSeat(int currentSeat) => (currentSeat + 1) % _activeSeatCount;

  Future<void> _animateTokenMove({
    required int seat,
    required int tokenIndex,
    required int from,
    required int to,
  }) async {
    if (from == -1) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      setState(() {
        _tokens[seat][tokenIndex] = 0;
      });
      if (to == 0) return;
    }

    for (var position = max(0, from) + 1; position <= to; position++) {
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      setState(() {
        _tokens[seat][tokenIndex] = position;
      });
    }
  }

  Future<List<int>> _captureOpponentsIfNeeded(int seat, int movedTo) async {
    final globalTrackIndex = _globalTrackIndex(seat, movedTo);
    if (_safeSquares.contains(globalTrackIndex)) return const [];

    final capturedSeats = <int>[];
    final animations = <_CaptureAnimation>[];
    for (var otherSeat = 0; otherSeat < _activeSeatCount; otherSeat++) {
      if (otherSeat == seat) continue;
      for (
        var tokenIndex = 0;
        tokenIndex < _tokens[otherSeat].length;
        tokenIndex++
      ) {
        final otherPosition = _tokens[otherSeat][tokenIndex];
        if (otherPosition >= 0 &&
            otherPosition < _trackLength &&
            _globalTrackIndex(otherSeat, otherPosition) == globalTrackIndex) {
          animations.add(
            _CaptureAnimation(
              key:
                  '${DateTime.now().microsecondsSinceEpoch}_${otherSeat}_$tokenIndex',
              seat: otherSeat,
              tokenIndex: tokenIndex,
              from: _track[globalTrackIndex],
              to: _baseSlots[_selectedColors[otherSeat]]![tokenIndex],
            ),
          );
          if (!capturedSeats.contains(otherSeat)) {
            capturedSeats.add(otherSeat);
          }
        }
      }
    }

    if (animations.isEmpty) {
      return capturedSeats;
    }

    setState(() {
      _captureAnimations = [..._captureAnimations, ...animations];
    });
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return capturedSeats;
    setState(() {
      for (final animation in animations) {
        _tokens[animation.seat][animation.tokenIndex] = -1;
      }
      final removed = animations.map((animation) => animation.key).toSet();
      _captureAnimations = _captureAnimations
          .where((animation) => !removed.contains(animation.key))
          .toList(growable: false);
    });
    return capturedSeats;
  }

  int _bestTokenForComputer(int seat, int roll, List<int> movable) {
    var bestToken = movable.first;
    var bestScore = -1;
    for (final tokenIndex in movable) {
      final current = _tokens[seat][tokenIndex];
      final target = current == -1 ? 0 : current + roll;
      var score = target;
      if (target == _finishSteps) score += 1000;
      if (current == -1) score += 120;
      if (target >= 0 && target < _trackLength) {
        final global = _globalTrackIndex(seat, target);
        if (!_safeSquares.contains(global)) {
          for (var otherSeat = 0; otherSeat < _activeSeatCount; otherSeat++) {
            if (otherSeat == seat) continue;
            if (_tokens[otherSeat].any(
              (other) =>
                  other >= 0 &&
                  other < _trackLength &&
                  _globalTrackIndex(otherSeat, other) == global,
            )) {
              score += 500;
            }
          }
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestToken = tokenIndex;
      }
    }
    return bestToken;
  }

  int _globalTrackIndex(int seat, int position) {
    final color = _selectedColors[seat];
    final start = _startOffsets[color]!;
    return (start + position) % _trackLength;
  }

  _BoardPoint _pointForToken(int seat, int tokenIndex) {
    final color = _selectedColors[seat];
    final position = _tokens[seat][tokenIndex];
    if (position == -1) {
      return _baseSlots[color]![tokenIndex];
    }
    if (position < _trackLength) {
      return _track[_globalTrackIndex(seat, position)];
    }
    return _homePaths[color]![position - _trackLength];
  }

  void _changeMode(_LudoMode mode) {
    setState(() {
      _mode = mode;
    });
    _resetMatch();
  }

  void _changeSeatColor(int seat, _LudoColor color) {
    final existing = _selectedColors.indexOf(color);
    setState(() {
      if (existing != -1 && existing < _activeSeatCount) {
        final current = _selectedColors[seat];
        _selectedColors[existing] = current;
      }
      _selectedColors[seat] = color;
      _message = '${_seatLabel(seat)} chose ${color.label}.';
    });
  }

  void _resetMatch() {
    setState(() {
      for (final seatTokens in _tokens) {
        for (var index = 0; index < seatTokens.length; index++) {
          seatTokens[index] = -1;
        }
      }
      _currentSeat = 0;
      _lastRoll = 0;
      _displayRoll = null;
      _pendingRoll = null;
      _movableTokens = const [];
      _rolling = false;
      _matchOver = false;
      _message = _isComputerMode
          ? 'Choose colors and roll the dice against CPU.'
          : '${_seatLabel(0)} starts. Roll a 6 to enter the board.';
    });
  }

  String _seatLabel(int seat) {
    if (_isComputerMode && seat == 1) return 'CPU';
    return 'Player ${seat + 1}';
  }

  List<_TokenPlacement> _tokenPlacements() {
    final placements = <_TokenPlacement>[];
    final counts = <_BoardPoint, int>{};
    for (var seat = 0; seat < _activeSeatCount; seat++) {
      for (var tokenIndex = 0; tokenIndex < 4; tokenIndex++) {
        if (_captureAnimations.any(
          (animation) =>
              animation.seat == seat && animation.tokenIndex == tokenIndex,
        )) {
          continue;
        }
        final point = _pointForToken(seat, tokenIndex);
        final slot = counts[point] ?? 0;
        counts[point] = slot + 1;
        placements.add(
          _TokenPlacement(
            seat: seat,
            tokenIndex: tokenIndex,
            point: point,
            slot: slot,
            activeTurn: seat == _currentSeat,
            movable:
                seat == _currentSeat && _movableTokens.contains(tokenIndex),
          ),
        );
      }
    }
    return placements;
  }

  @override
  Widget build(BuildContext context) {
    final placements = _tokenPlacements();
    final currentColor = _selectedColors[_currentSeat];

    return GameScaffold(
      title: 'Ludo',
      subtitle: 'Real token-based Ludo with color selection and move choice.',
      accent: [currentColor.color, currentColor.lightColor],
      compactHeader: true,
      minimalHeader: true,
      backgroundMusicAsset: null,
      child: Column(
        children: [
          GameModeSelector<_LudoMode>(
            selectedValue: _mode,
            options: _LudoMode.values
                .map((mode) => GameModeOption(value: mode, label: mode.label))
                .toList(growable: false),
            onChanged: _changeMode,
            accentColor: currentColor.color,
            dense: true,
          ),
          const SizedBox(height: 10),
          GamePanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Colors',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...List.generate(_activeSeatCount, (seat) {
                  final color = _selectedColors[seat];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 88,
                          child: Text(
                            _seatLabel(seat),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _LudoColor.values
                                .map((option) {
                                  final selected = option == color;
                                  final takenByOther = _selectedColors
                                      .take(_activeSeatCount)
                                      .indexed
                                      .any(
                                        (entry) =>
                                            entry.$1 != seat &&
                                            entry.$2 == option,
                                      );
                                  return GestureDetector(
                                    onTap: () => _changeSeatColor(seat, option),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 140,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: selected
                                            ? option.color.withValues(
                                                alpha: 0.22,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.04,
                                              ),
                                        border: Border.all(
                                          color: selected
                                              ? option.color
                                              : Colors.white.withValues(
                                                  alpha: 0.12,
                                                ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 14,
                                            width: 14,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: option.color,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            option.label,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: takenByOther && !selected
                                                    ? 0.72
                                                    : 1,
                                              ),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                })
                                .toList(growable: false),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_activeSeatCount, (seat) {
              final homeCount = _tokens[seat]
                  .where((position) => position == _finishSteps)
                  .length;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: seat == _activeSeatCount - 1 ? 0 : 8,
                  ),
                  child: CompactMetricCard(
                    label: _seatLabel(seat),
                    value: '$homeCount/4',
                    compact: true,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          GamePanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Wins',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xffcbd5e1),
                    ),
                  ),
                ),
                Text(
                  _wins.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  _lastRoll == 0 ? 'Last roll: -' : 'Last roll: $_lastRoll',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StatusCard(
            message: _matchOver
                ? _message
                : '${_seatLabel(_currentSeat)} turn. $_message',
            accent: currentColor.color,
          ),
          const SizedBox(height: 12),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dice',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _pendingRoll != null
                            ? 'Choose a token on the board'
                            : _rolling
                            ? 'Rolling now...'
                            : _matchOver
                            ? 'Match complete'
                            : '${_seatLabel(_currentSeat)} to roll',
                        style: const TextStyle(
                          color: Color(0xffcbd5e1),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _DiceFace(
                  value: _rolling
                      ? _displayRoll
                      : (_lastRoll == 0 ? null : _lastRoll),
                  accent: currentColor.color,
                  rolling: _rolling,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GamePanel(
            padding: const EdgeInsets.all(10),
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = constraints.maxWidth / 15;
                  return Stack(
                    children: [
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 225,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 15,
                            ),
                        itemBuilder: (context, index) {
                          final row = index ~/ 15;
                          final col = index % 15;
                          final point = _BoardPoint(row, col);
                          final tile = _tileFor(point);
                          return Container(
                            margin: const EdgeInsets.all(0.5),
                            decoration: BoxDecoration(
                              color: tile.background,
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.08),
                                width: 0.6,
                              ),
                            ),
                            child: tile.icon == null
                                ? null
                                : Center(child: tile.icon),
                          );
                        },
                      ),
                      Positioned(
                        left: cellSize * 6,
                        top: cellSize * 6,
                        child: SizedBox(
                          height: cellSize * 3,
                          width: cellSize * 3,
                          child: CustomPaint(
                            painter: _CenterPainter(
                              colors: [
                                _LudoColor.red.color,
                                _LudoColor.blue.color,
                                _LudoColor.yellow.color,
                                _LudoColor.green.color,
                              ],
                            ),
                          ),
                        ),
                      ),
                      ...placements.map((placement) {
                        final seatColor = _selectedColors[placement.seat];
                        return _PositionedToken(
                          placement: placement,
                          cellSize: cellSize,
                          color: seatColor.color,
                          onTap: () =>
                              _onTokenTap(placement.seat, placement.tokenIndex),
                        );
                      }),
                      ..._captureAnimations.map((animation) {
                        final seatColor = _selectedColors[animation.seat];
                        return _AnimatedCapturedToken(
                          key: ValueKey(animation.key),
                          animation: animation,
                          cellSize: cellSize,
                          color: seatColor.color,
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          _isComputerMode
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _rolling ||
                            _pendingRoll != null ||
                            _matchOver ||
                            _isComputerTurn
                        ? null
                        : _rollDice,
                    child: Text(
                      _rolling
                          ? 'Rolling...'
                          : _pendingRoll != null
                          ? 'Choose token to move'
                          : _matchOver
                          ? 'Match complete'
                          : _isComputerTurn
                          ? 'CPU is playing'
                          : 'Roll dice',
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final buttonWidth = _activeSeatCount <= 2
                        ? (constraints.maxWidth - 8) / 2
                        : (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_activeSeatCount, (seat) {
                        final isCurrentSeat = seat == _currentSeat;
                        final canRoll =
                            isCurrentSeat &&
                            !_rolling &&
                            _pendingRoll == null &&
                            !_matchOver;
                        final seatColor = _selectedColors[seat].color;
                        return SizedBox(
                          width: buttonWidth,
                          child: ElevatedButton(
                            onPressed: canRoll ? _rollDice : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrentSeat ? seatColor : null,
                              foregroundColor: isCurrentSeat
                                  ? Colors.white
                                  : null,
                            ),
                            child: Text(
                              _matchOver
                                  ? '${_seatLabel(seat)} done'
                                  : _rolling && isCurrentSeat
                                  ? '${_seatLabel(seat)} rolling...'
                                  : _pendingRoll != null && isCurrentSeat
                                  ? '${_seatLabel(seat)} choose token'
                                  : isCurrentSeat
                                  ? '${_seatLabel(seat)} roll'
                                  : '${_seatLabel(seat)} wait',
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'New Ludo match', onPressed: _resetMatch),
        ],
      ),
    );
  }

  _TileVisual _tileFor(_BoardPoint point) {
    final inRedBase = point.row < 6 && point.col < 6;
    final inBlueBase = point.row < 6 && point.col > 8;
    final inYellowBase = point.row > 8 && point.col > 8;
    final inGreenBase = point.row > 8 && point.col < 6;

    if (point.row == 7 && point.col == 7) {
      return const _TileVisual(background: Colors.transparent);
    }
    if (inRedBase) {
      return _TileVisual(
        background: _LudoColor.red.color.withValues(alpha: 0.18),
      );
    }
    if (inBlueBase) {
      return _TileVisual(
        background: _LudoColor.blue.color.withValues(alpha: 0.18),
      );
    }
    if (inYellowBase) {
      return _TileVisual(
        background: _LudoColor.yellow.color.withValues(alpha: 0.18),
      );
    }
    if (inGreenBase) {
      return _TileVisual(
        background: _LudoColor.green.color.withValues(alpha: 0.18),
      );
    }

    for (final color in _LudoColor.values) {
      if (_homePaths[color]!.contains(point)) {
        return _TileVisual(background: color.color.withValues(alpha: 0.28));
      }
    }

    if (_track.contains(point)) {
      final globalIndex = _track.indexOf(point);
      final safe = _safeSquares.contains(globalIndex);
      return _TileVisual(
        background: safe ? const Color(0xffe2e8f0) : Colors.white,
        icon: safe
            ? const Icon(Icons.star_rounded, size: 14, color: Color(0xff334155))
            : null,
      );
    }

    if ((point.row >= 6 && point.row <= 8) ||
        (point.col >= 6 && point.col <= 8)) {
      return _TileVisual(background: Colors.white.withValues(alpha: 0.96));
    }

    return const _TileVisual(background: Colors.white);
  }
}

enum _LudoMode {
  computer('Computer'),
  twoPlayers('2 Player'),
  threePlayers('3 Player'),
  fourPlayers('4 Player');

  const _LudoMode(this.label);

  final String label;
}

enum _LudoColor {
  red('Red', Color(0xffef4444), Color(0xfffecaca)),
  blue('Blue', Color(0xff2563eb), Color(0xffdbeafe)),
  yellow('Yellow', Color(0xffeab308), Color(0xfffef9c3)),
  green('Green', Color(0xff22c55e), Color(0xffdcfce7));

  const _LudoColor(this.label, this.color, this.lightColor);

  final String label;
  final Color color;
  final Color lightColor;
}

class _BoardPoint {
  const _BoardPoint(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BoardPoint && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);
}

class _TokenPlacement {
  const _TokenPlacement({
    required this.seat,
    required this.tokenIndex,
    required this.point,
    required this.slot,
    required this.activeTurn,
    required this.movable,
  });

  final int seat;
  final int tokenIndex;
  final _BoardPoint point;
  final int slot;
  final bool activeTurn;
  final bool movable;
}

class _CaptureAnimation {
  const _CaptureAnimation({
    required this.key,
    required this.seat,
    required this.tokenIndex,
    required this.from,
    required this.to,
  });

  final String key;
  final int seat;
  final int tokenIndex;
  final _BoardPoint from;
  final _BoardPoint to;
}

class _TileVisual {
  const _TileVisual({required this.background, this.icon});

  final Color background;
  final Widget? icon;
}

class _CenterPainter extends CustomPainter {
  const _CenterPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final top = Offset(size.width / 2, 0);
    final right = Offset(size.width, size.height / 2);
    final bottom = Offset(size.width / 2, size.height);
    final left = Offset(0, size.height / 2);

    paint.color = colors[0];
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(top.dx, top.dy)
        ..close(),
      paint,
    );
    paint.color = colors[1];
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(top.dx, top.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      paint,
    );
    paint.color = colors[2];
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(right.dx, right.dy)
        ..lineTo(bottom.dx, bottom.dy)
        ..close(),
      paint,
    );
    paint.color = colors[3];
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(bottom.dx, bottom.dy)
        ..lineTo(left.dx, left.dy)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CenterPainter oldDelegate) => false;
}

class _BoardToken extends StatelessWidget {
  const _BoardToken({
    required this.color,
    required this.label,
    this.highlighted = false,
    this.activeTurn = false,
    this.size = 28,
  });

  final Color color;
  final String label;
  final bool highlighted;
  final bool activeTurn;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.92), color],
        ),
        border: Border.all(color: Colors.white, width: size * 0.08),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
          if (activeTurn)
            BoxShadow(
              color: color.withValues(alpha: highlighted ? 0.52 : 0.26),
              blurRadius: highlighted ? 18 : 10,
              spreadRadius: highlighted ? 1.2 : 0.4,
            ),
          if (highlighted)
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 14),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: size * 0.36,
            width: size * 0.36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          Positioned(
            right: size * 0.02,
            bottom: size * 0.02,
            child: Container(
              height: size * 0.42,
              width: size * 0.42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff0f172a),
                border: Border.all(color: Colors.white, width: size * 0.05),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({
    required this.value,
    required this.accent,
    required this.rolling,
  });

  final int? value;
  final Color accent;
  final bool rolling;

  @override
  Widget build(BuildContext context) {
    final pipSets = <int, List<Alignment>>{
      1: const [Alignment.center],
      2: const [Alignment(-0.55, -0.55), Alignment(0.55, 0.55)],
      3: const [
        Alignment(-0.55, -0.55),
        Alignment.center,
        Alignment(0.55, 0.55),
      ],
      4: const [
        Alignment(-0.55, -0.55),
        Alignment(0.55, -0.55),
        Alignment(-0.55, 0.55),
        Alignment(0.55, 0.55),
      ],
      5: const [
        Alignment(-0.55, -0.55),
        Alignment(0.55, -0.55),
        Alignment.center,
        Alignment(-0.55, 0.55),
        Alignment(0.55, 0.55),
      ],
      6: const [
        Alignment(-0.55, -0.62),
        Alignment(0.55, -0.62),
        Alignment(-0.55, 0),
        Alignment(0.55, 0),
        Alignment(-0.55, 0.62),
        Alignment(0.55, 0.62),
      ],
    };
    final alignments = pipSets[value] ?? const <Alignment>[];
    return AnimatedRotation(
      duration: Duration(milliseconds: rolling ? 120 : 260),
      turns: rolling ? 0.06 : 0,
      child: AnimatedScale(
        duration: Duration(milliseconds: rolling ? 120 : 220),
        scale: rolling ? 1.06 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 74,
          width: 74,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            border: Border.all(color: accent.withValues(alpha: 0.75), width: 2),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: rolling ? 0.28 : 0.18),
                blurRadius: rolling ? 22 : 16,
                offset: Offset(0, rolling ? 10 : 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              for (final alignment in alignments)
                Align(
                  alignment: alignment,
                  child: Container(
                    height: rolling ? 11 : 10,
                    width: rolling ? 11 : 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xff111827),
                    ),
                  ),
                ),
              if (value == null)
                const Center(
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: Color(0xff64748b),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCapturedToken extends StatelessWidget {
  const _AnimatedCapturedToken({
    super.key,
    required this.animation,
    required this.cellSize,
    required this.color,
  });

  final _CaptureAnimation animation;
  final double cellSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokenSize = (cellSize * 0.56).clamp(16.0, 22.0);
    final startLeft =
        animation.from.col * cellSize + (cellSize - tokenSize) / 2;
    final startTop = animation.from.row * cellSize + (cellSize - tokenSize) / 2;
    final endLeft = animation.to.col * cellSize + (cellSize - tokenSize) / 2;
    final endTop = animation.to.row * cellSize + (cellSize - tokenSize) / 2;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        final left = startLeft + ((endLeft - startLeft) * value);
        final top = startTop + ((endTop - startTop) * value);
        return Positioned(
          left: left,
          top: top,
          child: Opacity(opacity: 1 - (value * 0.2), child: child),
        );
      },
      child: _BoardToken(
        color: color,
        label: '${animation.tokenIndex + 1}',
        size: tokenSize,
      ),
    );
  }
}

class _PositionedToken extends StatelessWidget {
  const _PositionedToken({
    required this.placement,
    required this.cellSize,
    required this.color,
    required this.onTap,
  });

  final _TokenPlacement placement;
  final double cellSize;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokenSize = (cellSize * 0.56).clamp(16.0, 22.0);
    final edge = cellSize * 0.08;
    final offsets = [
      Offset(edge, edge),
      Offset(cellSize - tokenSize - edge, edge),
      Offset(edge, cellSize - tokenSize - edge),
      Offset(cellSize - tokenSize - edge, cellSize - tokenSize - edge),
    ];
    final offset = offsets[placement.slot.clamp(0, 3)];
    return Positioned(
      left: placement.point.col * cellSize + offset.dx,
      top: placement.point.row * cellSize + offset.dy,
      child: GestureDetector(
        onTap: onTap,
        child: _BoardToken(
          color: color,
          label: '${placement.tokenIndex + 1}',
          activeTurn: placement.activeTurn,
          highlighted: placement.movable,
          size: tokenSize,
        ),
      ),
    );
  }
}
