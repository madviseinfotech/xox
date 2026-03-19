import 'dart:math';

import 'package:flutter/material.dart';

import 'game_mode_selector.dart';
import 'game_scaffold.dart';
import 'game_stats_store.dart';

class CricketChaseScreen extends StatefulWidget {
  const CricketChaseScreen({super.key});

  @override
  State<CricketChaseScreen> createState() => _CricketChaseScreenState();
}

class _CricketChaseScreenState extends State<CricketChaseScreen> {
  static const List<int> _shots = [1, 2, 3, 4, 6];
  final Random _random = Random();

  _CricketMode _mode = _CricketMode.computer;
  bool _playerBatting = true;
  bool _matchOver = false;
  int _ballsLeft = 6;
  int _playerRuns = 0;
  int _opponentRuns = 0;
  int _wins = 0;
  String _message = 'You bat first. Pick a shot for ball one.';
  int? _playerChoice;
  int? _opponentChoice;
  String? _winnerLabel;

  @override
  void initState() {
    super.initState();
    _loadWins();
  }

  Future<void> _loadWins() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _wins = snapshot.cricketWins;
    });
  }

  Future<void> _playBall(int choice) async {
    if (_matchOver) return;
    if (_mode == _CricketMode.twoPlayers) {
      await _playTwoPlayerBall(choice);
      return;
    }
    final cpu = _shots[_random.nextInt(_shots.length)];
    setState(() {
      _playerChoice = choice;
      _opponentChoice = cpu;
    });

    if (_playerBatting) {
      _ballsLeft -= 1;
      if (choice == cpu) {
        _playerBatting = false;
        _ballsLeft = 6;
        _message = 'You are out on $choice. CPU needs ${_playerRuns + 1} runs.';
        _winnerLabel = null;
      } else {
        _playerRuns += choice;
        if (_ballsLeft == 0) {
          _playerBatting = false;
          _ballsLeft = 6;
          _message = 'Innings over. CPU needs ${_playerRuns + 1} runs.';
          _winnerLabel = null;
        } else {
          _message = 'You scored $choice. $_ballsLeft balls left.';
          _winnerLabel = null;
        }
      }
      setState(() {});
      return;
    }

    _ballsLeft -= 1;
    if (choice == cpu) {
      _finishMatch(playerWon: _playerRuns >= _opponentRuns);
      return;
    }

    _opponentRuns += cpu;
    if (_opponentRuns > _playerRuns) {
      _finishMatch(playerWon: false);
      return;
    }

    if (_ballsLeft == 0) {
      _finishMatch(playerWon: _playerRuns >= _opponentRuns);
      return;
    }

    setState(() {
      _message = 'CPU scored $cpu. Bowl again. $_ballsLeft balls left.';
      _winnerLabel = null;
    });
  }

  Future<void> _playTwoPlayerBall(int choice) async {
    final opponent = _shots[_random.nextInt(_shots.length)];
    setState(() {
      _playerChoice = choice;
      _opponentChoice = opponent;
    });

    if (_playerBatting) {
      _ballsLeft -= 1;
      if (choice == opponent) {
        _playerBatting = false;
        _ballsLeft = 6;
        _message =
            'Player 1 is out on $choice. Player 2 needs ${_playerRuns + 1} runs.';
        _winnerLabel = null;
      } else {
        _playerRuns += choice;
        if (_ballsLeft == 0) {
          _playerBatting = false;
          _ballsLeft = 6;
          _message = 'Player 1 finished on $_playerRuns. Pass to Player 2.';
          _winnerLabel = null;
        } else {
          _message =
              'Player 1 scored $choice. Pass to Player 2. $_ballsLeft balls left.';
          _winnerLabel = null;
        }
      }
      setState(() {});
      return;
    }

    _ballsLeft -= 1;
    if (choice == opponent) {
      _finishMatch(playerWon: _playerRuns >= _opponentRuns);
      return;
    }

    _opponentRuns += opponent;
    if (_opponentRuns > _playerRuns) {
      _finishMatch(playerWon: false);
      return;
    }

    if (_ballsLeft == 0) {
      _finishMatch(playerWon: _playerRuns >= _opponentRuns);
      return;
    }

    setState(() {
      _message =
          'Player 2 scored $opponent. Player 1, bowl again. $_ballsLeft balls left.';
      _winnerLabel = null;
    });
  }

  Future<void> _finishMatch({required bool playerWon}) async {
    setState(() {
      _matchOver = true;
      _message = _mode == _CricketMode.computer
          ? (playerWon
                ? 'You won the chase by ${_playerRuns - _opponentRuns} runs.'
                : 'CPU chased it down.')
          : (playerWon
                ? 'Player 1 won by ${_playerRuns - _opponentRuns} runs.'
                : 'Player 2 chased it down.');
      _winnerLabel = _mode == _CricketMode.computer
          ? (playerWon ? 'You win' : 'CPU wins')
          : (playerWon ? 'Player 1 wins' : 'Player 2 wins');
    });
    if (playerWon) {
      await GameStatsStore.instance.incrementCricketWins();
      if (!mounted) return;
      setState(() {
        _wins += 1;
      });
    }
  }

  void _resetMatch() {
    setState(() {
      _playerBatting = true;
      _matchOver = false;
      _ballsLeft = 6;
      _playerRuns = 0;
      _opponentRuns = 0;
      _playerChoice = null;
      _opponentChoice = null;
      _message = _mode == _CricketMode.computer
          ? 'You bat first. Pick a shot for ball one.'
          : 'Player 1 bats first. Pick a shot for ball one.';
      _winnerLabel = null;
    });
  }

  void _changeMode(_CricketMode mode) {
    setState(() {
      _mode = mode;
    });
    _resetMatch();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Cricket Chase',
      subtitle: 'Switch between a computer chase and local two-player cricket.',
      accent: const [Color(0xff0f766e), Color(0xff22c55e)],
      child: Column(
        children: [
          GameModeSelector<_CricketMode>(
            selectedValue: _mode,
            options: _CricketMode.values
                .map((mode) => GameModeOption(value: mode, label: mode.label))
                .toList(growable: false),
            onChanged: _changeMode,
            accentColor: const Color(0xff22c55e),
          ),
          const SizedBox(height: 18),
          ScorePanel(
            leftLabel: _mode == _CricketMode.computer ? 'You' : 'Player 1',
            leftValue: _playerRuns.toString(),
            rightLabel: _mode == _CricketMode.computer ? 'CPU' : 'Player 2',
            rightValue: _opponentRuns.toString(),
            footer: _playerBatting
                ? (_mode == _CricketMode.computer
                      ? 'You are batting. Balls left: $_ballsLeft'
                      : 'Player 1 batting. Balls left: $_ballsLeft')
                : (_mode == _CricketMode.computer
                      ? 'You are bowling. Balls left: $_ballsLeft'
                      : 'Player 1 bowling. Balls left: $_ballsLeft'),
          ),
          const SizedBox(height: 22),
          HeadToHeadPanel(
            leftLabel: _mode == _CricketMode.computer ? 'You' : 'Player 1',
            highlightLeft:
                _winnerLabel == 'You win' || _winnerLabel == 'Player 1 wins',
            leftChild: _choiceValue(_playerChoice),
            rightLabel: _mode == _CricketMode.computer ? 'CPU' : 'Player 2',
            highlightRight:
                _winnerLabel == 'CPU wins' || _winnerLabel == 'Player 2 wins',
            rightChild: _choiceValue(_opponentChoice),
          ),
          const SizedBox(height: 18),
          StatusCard(
            message: _message,
            accent: const Color(0xff22c55e),
            highlight: _winnerLabel != null,
            headline: _winnerLabel,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _shots
                .map(
                  (shot) => SizedBox(
                    width: 72,
                    child: ElevatedButton(
                      onPressed: _matchOver ? null : () => _playBall(shot),
                      child: Text(shot.toString()),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          ScorePanel(
            leftLabel: 'Wins',
            leftValue: _wins.toString(),
            rightLabel: 'Target',
            rightValue: _playerBatting ? '--' : (_playerRuns + 1).toString(),
            footer: _matchOver
                ? 'Match complete.'
                : 'Hand cricket rules: matching numbers mean wicket.',
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'New match', onPressed: _resetMatch),
        ],
      ),
    );
  }

  Widget _choiceValue(int? choice) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            choice?.toString() ?? '--',
            key: ValueKey('cricket_choice_$choice'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

enum _CricketMode {
  computer('Play with computer'),
  twoPlayers('Play with player 2');

  const _CricketMode(this.label);
  final String label;
}
