import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class HeadsOrTailsScreen extends StatefulWidget {
  const HeadsOrTailsScreen({super.key});

  @override
  State<HeadsOrTailsScreen> createState() => _HeadsOrTailsScreenState();
}

class _HeadsOrTailsScreenState extends State<HeadsOrTailsScreen> {
  final Random _random = Random();

  String _playerPick = 'Heads';
  String _coinResult = 'Heads';
  String _message = 'Pick a side and flip the coin.';
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _wins = 0;
  bool _isFlipping = false;
  int _flipFrame = 0;
  bool _lastFlipWon = false;

  @override
  void initState() {
    super.initState();
    _loadBestStreak();
  }

  Future<void> _loadBestStreak() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestStreak = snapshot.headsOrTailsBestStreak;
    });
  }

  Future<void> _flipCoin(String pick) async {
    if (_isFlipping) return;
    final result = _random.nextBool() ? 'Heads' : 'Tails';
    final won = pick == result;
    final nextStreak = won ? _currentStreak + 1 : 0;

    setState(() {
      _playerPick = pick;
      _isFlipping = true;
      _flipFrame = 0;
      _message = 'Flipping the coin...';
      _lastFlipWon = false;
    });

    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      setState(() {
        _flipFrame = i + 1;
      });
    }

    if (!mounted) return;
    setState(() {
      _coinResult = result;
      _currentStreak = nextStreak;
      _isFlipping = false;
      _lastFlipWon = won;
      if (won) {
        _wins += 1;
        _message = 'Nice call. It landed on $result.';
      } else {
        _message = 'Missed it. It landed on $result.';
      }
      if (nextStreak > _bestStreak) {
        _bestStreak = nextStreak;
      }
    });

    await GameStatsStore.instance.recordHeadsOrTailsStreak(nextStreak);
  }

  void _resetSession() {
    setState(() {
      _playerPick = 'Heads';
      _coinResult = 'Heads';
      _message = 'Pick a side and flip the coin.';
      _currentStreak = 0;
      _wins = 0;
      _isFlipping = false;
      _flipFrame = 0;
      _lastFlipWon = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Heads or Tails',
      subtitle: 'Call the coin, build a streak, and try to beat your best run.',
      accent: const [Color(0xfff59e0b), Color(0xffef4444)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Wins',
            leftValue: _wins.toString(),
            rightLabel: 'Best streak',
            rightValue: _bestStreak.toString(),
            footer: 'Current streak: $_currentStreak',
          ),
          const SizedBox(height: 22),
          GamePanel(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: Tween<double>(
                        begin: 0.9,
                        end: 1,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Text(
                    _isFlipping
                        ? (_flipFrame.isEven ? '🪙' : '🥇')
                        : (_coinResult == 'Heads' ? '🪙' : '🥇'),
                    key: ValueKey(
                      _isFlipping ? 'flip_$_flipFrame' : _coinResult,
                    ),
                    style: const TextStyle(fontSize: 60),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    'You picked $_playerPick',
                    key: ValueKey(_playerPick),
                    style: const TextStyle(color: Color(0xff94a3b8)),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    'Coin result: $_coinResult',
                    key: ValueKey(
                      _isFlipping
                          ? 'result_flipping_$_flipFrame'
                          : 'result_$_coinResult',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StatusCard(
            message: _message,
            accent: const Color(0xffef4444),
            highlight: _lastFlipWon,
            headline: _lastFlipWon ? 'You called it' : null,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isFlipping ? null : () => _flipCoin('Heads'),
                  child: const Text('Pick Heads'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isFlipping ? null : () => _flipCoin('Tails'),
                  child: const Text('Pick Tails'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _resetSession,
            child: const Text('Reset session'),
          ),
        ],
      ),
    );
  }
}
