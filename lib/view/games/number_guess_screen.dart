import 'dart:math';

import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class NumberGuessScreen extends StatefulWidget {
  const NumberGuessScreen({super.key});

  @override
  State<NumberGuessScreen> createState() => _NumberGuessScreenState();
}

class _NumberGuessScreenState extends State<NumberGuessScreen> {
  final Random _random = Random();
  final TextEditingController _controller = TextEditingController();

  late int _target;
  String _message = 'Guess a number from 1 to 50.';
  int _attempts = 0;
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _startNewRound();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startNewRound() {
    setState(() {
      _target = _random.nextInt(50) + 1;
      _controller.clear();
      _message = 'Guess a number from 1 to 50.';
      _attempts = 0;
    });
  }

  void _submitGuess() {
    final guess = int.tryParse(_controller.text);
    if (guess == null || guess < 1 || guess > 50) {
      setState(() {
        _message = 'Enter a valid number between 1 and 50.';
      });
      return;
    }

    setState(() {
      _attempts += 1;

      if (guess == _target) {
        _message = 'Correct. You cracked it in $_attempts tries.';
        if (_bestScore == 0 || _attempts < _bestScore) {
          _bestScore = _attempts;
        }
        GameStatsStore.instance.recordNumberGuessBest(_attempts);
      } else if (guess < _target) {
        _message = 'Too low. Move higher.';
      } else {
        _message = 'Too high. Move lower.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Number Guess',
      subtitle: 'A simple logic challenge with quick feedback every turn.',
      accent: const [Color(0xff06b6d4), Color(0xff3b82f6)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Attempts',
            leftValue: _attempts.toString(),
            rightLabel: 'Best',
            rightValue: _bestScore == 0 ? '--' : _bestScore.toString(),
            footer: 'Secret number range: 1 to 50',
          ),
          const SizedBox(height: 22),
          GamePanel(
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type your guess',
                    hintStyle: const TextStyle(color: Color(0xff94a3b8)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitGuess,
                    child: const Text('Check guess'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xff3b82f6)),
          const SizedBox(height: 22),
          TextButton(
            onPressed: _startNewRound,
            child: const Text('New number'),
          ),
        ],
      ),
    );
  }
}
