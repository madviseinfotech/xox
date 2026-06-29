import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_mode_selector.dart';
import 'game_scaffold.dart';
import 'game_stats_store.dart';

class RockPaperScissorsScreen extends StatefulWidget {
  const RockPaperScissorsScreen({super.key});

  @override
  State<RockPaperScissorsScreen> createState() =>
      _RockPaperScissorsScreenState();
}

class _RockPaperScissorsScreenState extends State<RockPaperScissorsScreen> {
  static const List<_Move> _moves = [_Move.rock, _Move.paper, _Move.scissors];

  final Random _random = Random();

  _OpponentMode _mode = _OpponentMode.computer;
  _Move? _playerMove;
  _Move? _opponentMove;
  String _result = 'Choose your move to start the duel.';
  int _playerScore = 0;
  int _opponentScore = 0;
  int _rounds = 0;
  bool _isResolvingRound = false;
  bool _awaitingSecondPlayer = false;
  String? _winnerLabel;

  Future<void> _playRound(_Move move) async {
    if (_isResolvingRound) return;
    if (_mode == _OpponentMode.twoPlayers) {
      if (!_awaitingSecondPlayer) {
        setState(() {
          _playerMove = move;
          _opponentMove = null;
          _awaitingSecondPlayer = true;
          _result = 'Pass the device to Player 2.';
        });
        return;
      }
      final outcome = _decideOutcome(_playerMove!, move);
      setState(() {
        _opponentMove = move;
        _awaitingSecondPlayer = false;
        _rounds += 1;
        if (outcome == 1) {
          _playerScore += 1;
          _result = 'Player 1 wins this round.';
          _winnerLabel = 'Player 1 wins';
        } else if (outcome == -1) {
          _opponentScore += 1;
          _result = 'Player 2 wins this round.';
          _winnerLabel = 'Player 2 wins';
        } else {
          _result = 'Draw round. Try again.';
          _winnerLabel = null;
        }
      });
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      return;
    }

    final cpu = _moves[_random.nextInt(_moves.length)];
    final outcome = _decideOutcome(move, cpu);

    setState(() {
      _playerMove = move;
      _opponentMove = null;
      _isResolvingRound = true;
      _result = 'CPU is choosing a move...';
      _winnerLabel = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _opponentMove = cpu;
      _isResolvingRound = false;
      _rounds += 1;

      if (outcome == 1) {
        _playerScore += 1;
        _result = 'You win this round.';
        _winnerLabel = 'You win';
        GameStatsStore.instance.incrementRockPaperScissorsWins();
      } else if (outcome == -1) {
        _opponentScore += 1;
        _result = 'Computer takes this round.';
        _winnerLabel = 'CPU wins';
      } else {
        _result = 'Draw round. Try again.';
        _winnerLabel = null;
      }
    });
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
  }

  int _decideOutcome(_Move player, _Move cpu) {
    if (player == cpu) return 0;
    if ((player == _Move.rock && cpu == _Move.scissors) ||
        (player == _Move.paper && cpu == _Move.rock) ||
        (player == _Move.scissors && cpu == _Move.paper)) {
      return 1;
    }
    return -1;
  }

  void _resetGame() {
    setState(() {
      _playerMove = null;
      _opponentMove = null;
      _result = _mode == _OpponentMode.computer
          ? 'Choose your move to start the duel.'
          : 'Player 1, choose your move.';
      _playerScore = 0;
      _opponentScore = 0;
      _rounds = 0;
      _awaitingSecondPlayer = false;
      _winnerLabel = null;
    });
  }

  void _changeMode(_OpponentMode mode) {
    setState(() {
      _mode = mode;
    });
    _resetGame();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Rock Paper Scissors',
      subtitle: 'Switch between computer duels and local two-player rounds.',
      accent: const [Color(0xff22c55e), Color(0xff14b8a6)],
      compactHeader: true,
      minimalHeader: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 620;
          return Column(
            children: [
              GameModeSelector<_OpponentMode>(
                dense: compact,
                selectedValue: _mode,
                options: _OpponentMode.values
                    .map(
                      (mode) => GameModeOption(value: mode, label: mode.label),
                    )
                    .toList(growable: false),
                onChanged: _changeMode,
                accentColor: const Color(0xff22c55e),
              ),
              SizedBox(height: compact ? 10 : 16),
              Row(
                children: [
                  Expanded(
                    child: CompactMetricCard(
                      label: _mode == _OpponentMode.computer
                          ? 'You'
                          : 'Player 1',
                      value: _playerScore.toString(),
                      compact: compact,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CompactMetricCard(
                      label: _mode == _OpponentMode.computer
                          ? 'CPU'
                          : 'Player 2',
                      value: _opponentScore.toString(),
                      compact: compact,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CompactMetricCard(
                      label: 'Rounds',
                      value: _rounds.toString(),
                      compact: compact,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 16),
              Wrap(
                spacing: compact ? 8 : 12,
                runSpacing: compact ? 8 : 12,
                alignment: WrapAlignment.center,
                children: _moves
                    .map((move) => _moveButton(move, compact: compact))
                    .toList(growable: false),
              ),
              SizedBox(height: compact ? 10 : 14),
              InlineStatusStrip(
                message: _winnerLabel == null
                    ? _result
                    : '${_winnerLabel!}. $_result',
                accent: const Color(0xff22c55e),
                compact: compact,
                highlight: _winnerLabel != null,
              ),
              SizedBox(height: compact ? 12 : 18),
              ResetActionButton(label: 'Reset score', onPressed: _resetGame),
              SizedBox(height: compact ? 12 : 18),
              HeadToHeadPanel(
                leftLabel: _mode == _OpponentMode.computer ? 'You' : 'Player 1',
                highlightLeft:
                    _winnerLabel == 'You win' ||
                    _winnerLabel == 'Player 1 wins',
                leftChild: _choiceValue(
                  _playerMove,
                  compact: compact,
                  hidden:
                      _mode == _OpponentMode.twoPlayers &&
                      _awaitingSecondPlayer,
                ),
                rightLabel: _mode == _OpponentMode.computer
                    ? 'CPU'
                    : 'Player 2',
                highlightRight:
                    _winnerLabel == 'CPU wins' ||
                    _winnerLabel == 'Player 2 wins',
                rightChild: _choiceValue(
                  _opponentMove,
                  compact: compact,
                  hidden:
                      _mode == _OpponentMode.twoPlayers &&
                      !_awaitingSecondPlayer,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _choiceValue(
    _Move? move, {
    required bool hidden,
    required bool compact,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            hidden ? '• • •' : move?.emoji ?? '❔',
            key: ValueKey('${move?.label}_${hidden ? 'hidden' : 'shown'}'),
            style: TextStyle(fontSize: compact ? 34 : 44),
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            hidden ? 'Hidden' : move?.label ?? 'Waiting',
            key: ValueKey('${move?.label ?? 'Waiting'}_$hidden'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _moveButton(_Move move, {required bool compact}) {
    return SizedBox(
      width: compact ? 94 : 104,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: compact ? 12 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        onPressed: _isResolvingRound ? null : () => _playRound(move),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(move.emoji, style: TextStyle(fontSize: compact ? 24 : 30)),
            SizedBox(height: compact ? 4 : 8),
            Text(move.label, style: TextStyle(fontSize: compact ? 13 : 14)),
          ],
        ),
      ),
    );
  }
}

enum _OpponentMode {
  computer('Play with computer'),
  twoPlayers('2 players');

  const _OpponentMode(this.label);
  final String label;
}

enum _Move {
  rock('Rock', '🪨'),
  paper('Paper', '📄'),
  scissors('Scissors', '✂️');

  const _Move(this.label, this.emoji);

  final String label;
  final String emoji;
}
