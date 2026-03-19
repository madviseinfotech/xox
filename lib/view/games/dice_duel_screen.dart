import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'game_mode_selector.dart';
import 'game_scaffold.dart';
import 'game_stats_store.dart';

class DiceDuelScreen extends StatefulWidget {
  const DiceDuelScreen({super.key});

  @override
  State<DiceDuelScreen> createState() => _DiceDuelScreenState();
}

class _DiceDuelScreenState extends State<DiceDuelScreen> {
  final Random _random = Random();

  _DiceMode _mode = _DiceMode.computer;
  int _playerRoll = 1;
  int _opponentRoll = 1;
  int _playerScore = 0;
  int _opponentScore = 0;
  String _message = 'Roll the dice to start the duel.';
  bool _isRolling = false;
  bool _awaitingSecondRoll = false;
  Timer? _rollTimer;
  String? _winnerLabel;

  @override
  void dispose() {
    _rollTimer?.cancel();
    super.dispose();
  }

  Future<void> _rollDice() async {
    if (_isRolling) return;
    if (_mode == _DiceMode.twoPlayers) {
      await _rollForTwoPlayers();
      return;
    }

    final player = _random.nextInt(6) + 1;
    final cpu = _random.nextInt(6) + 1;

    setState(() {
      _isRolling = true;
      _message = 'Rolling the dice...';
      _winnerLabel = null;
    });

    var ticks = 0;
    final completer = Completer<void>();
    _rollTimer?.cancel();
    _rollTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      ticks += 1;
      if (!mounted) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
        return;
      }
      setState(() {
        _playerRoll = _random.nextInt(6) + 1;
        _opponentRoll = _random.nextInt(6) + 1;
      });
      if (ticks >= 10) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });
    await completer.future;
    if (!mounted) return;

    setState(() {
      _playerRoll = player;
      _opponentRoll = cpu;
      _isRolling = false;

      if (player > cpu) {
        _playerScore += 1;
        _message = 'You win the roll.';
        _winnerLabel = 'You win';
        GameStatsStore.instance.incrementDiceWins();
      } else if (cpu > player) {
        _opponentScore += 1;
        _message = 'CPU wins the roll.';
        _winnerLabel = 'CPU wins';
      } else {
        _message = 'Tie roll. Run it again.';
        _winnerLabel = null;
      }
    });
  }

  Future<void> _rollForTwoPlayers() async {
    final rolledValue = _random.nextInt(6) + 1;
    setState(() {
      _isRolling = true;
      _message = _awaitingSecondRoll
          ? 'Player 2 is rolling...'
          : 'Player 1 is rolling...';
      _winnerLabel = null;
    });

    var ticks = 0;
    final completer = Completer<void>();
    _rollTimer?.cancel();
    _rollTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      ticks += 1;
      if (!mounted) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
        return;
      }
      setState(() {
        if (_awaitingSecondRoll) {
          _opponentRoll = _random.nextInt(6) + 1;
        } else {
          _playerRoll = _random.nextInt(6) + 1;
        }
      });
      if (ticks >= 10) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });
    await completer.future;
    if (!mounted) return;

    setState(() {
      _isRolling = false;
      if (_awaitingSecondRoll) {
        _opponentRoll = rolledValue;
        _awaitingSecondRoll = false;
        if (_playerRoll > _opponentRoll) {
          _playerScore += 1;
          _message = 'Player 1 wins the roll.';
          _winnerLabel = 'Player 1 wins';
        } else if (_opponentRoll > _playerRoll) {
          _opponentScore += 1;
          _message = 'Player 2 wins the roll.';
          _winnerLabel = 'Player 2 wins';
        } else {
          _message = 'Tie roll. Run it again.';
          _winnerLabel = null;
        }
      } else {
        _playerRoll = rolledValue;
        _awaitingSecondRoll = true;
        _message = 'Pass the device to Player 2.';
        _winnerLabel = null;
      }
    });
  }

  void _reset() {
    setState(() {
      _playerRoll = 1;
      _opponentRoll = 1;
      _playerScore = 0;
      _opponentScore = 0;
      _message = _mode == _DiceMode.computer
          ? 'Roll the dice to start the duel.'
          : 'Player 1, roll the dice to start.';
      _isRolling = false;
      _awaitingSecondRoll = false;
      _winnerLabel = null;
    });
  }

  void _changeMode(_DiceMode mode) {
    setState(() {
      _mode = mode;
    });
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Dice Duel',
      subtitle: 'Choose a computer rival or local two-player dice rounds.',
      accent: const [Color(0xffa855f7), Color(0xffec4899)],
      child: Column(
        children: [
          GameModeSelector<_DiceMode>(
            selectedValue: _mode,
            options: _DiceMode.values
                .map((mode) => GameModeOption(value: mode, label: mode.label))
                .toList(growable: false),
            onChanged: _changeMode,
            accentColor: const Color(0xffec4899),
          ),
          const SizedBox(height: 18),
          ScorePanel(
            leftLabel: _mode == _DiceMode.computer ? 'You' : 'Player 1',
            leftValue: _playerScore.toString(),
            rightLabel: _mode == _DiceMode.computer ? 'CPU' : 'Player 2',
            rightValue: _opponentScore.toString(),
            footer: 'Higher dice wins the round.',
          ),
          const SizedBox(height: 22),
          HeadToHeadPanel(
            leftLabel: _mode == _DiceMode.computer ? 'You' : 'Player 1',
            highlightLeft:
                _winnerLabel == 'You win' || _winnerLabel == 'Player 1 wins',
            leftChild: _diceValue(_playerRoll),
            rightLabel: _mode == _DiceMode.computer ? 'CPU' : 'Player 2',
            highlightRight:
                _winnerLabel == 'CPU wins' || _winnerLabel == 'Player 2 wins',
            rightChild: _diceValue(_opponentRoll),
          ),
          const SizedBox(height: 18),
          StatusCard(
            message: _message,
            accent: const Color(0xffec4899),
            highlight: _winnerLabel != null,
            headline: _winnerLabel,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isRolling ? null : _rollDice,
              child: Text(
                _isRolling
                    ? 'Rolling...'
                    : _mode == _DiceMode.computer
                    ? 'Roll dice'
                    : (_awaitingSecondRoll ? 'Player 2 roll' : 'Player 1 roll'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset match', onPressed: _reset),
        ],
      ),
    );
  }

  Widget _diceValue(int value) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            return RotationTransition(
              turns: Tween<double>(begin: 0.94, end: 1).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            _diceFace(value),
            key: ValueKey(value),
            style: const TextStyle(fontSize: 54),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            'Rolled $value',
            key: ValueKey('rolled_$value'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _diceFace(int value) {
    const faces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    return faces[value - 1];
  }
}

enum _DiceMode {
  computer('Play with computer'),
  twoPlayers('2 players');

  const _DiceMode(this.label);
  final String label;
}
