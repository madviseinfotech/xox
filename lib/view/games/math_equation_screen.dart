import 'dart:math';

import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class MathEquationScreen extends StatefulWidget {
  const MathEquationScreen({super.key});

  @override
  State<MathEquationScreen> createState() => _MathEquationScreenState();
}

class _MathEquationScreenState extends State<MathEquationScreen> {
  final Random _random = Random();

  _EquationRound? _round;
  int _level = 1;
  int _correct = 0;
  int _bestLevel = 1;
  int? _selectedIndex;
  bool _answered = false;
  String _message = 'Solve equations to unlock the next level.';

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    _level = snapshot.mathEquationLevel == 0 ? 1 : snapshot.mathEquationLevel;
    _bestLevel = _level;
    _round = _generateRound();
    if (!mounted) return;
    setState(() {});
  }

  int get _goalCorrect => 5 + min(5, (_level - 1) ~/ 2);

  _EquationRound _generateRound() {
    final maxValue = min(12 + (_level * 2), 40);
    final useMultiply = _level >= 4 && _random.nextBool();
    final useSubtract = _level >= 2 && _random.nextBool();

    int left;
    int right;
    String symbol;
    int answer;

    if (useMultiply) {
      left = _random.nextInt(min(10, 3 + _level)) + 2;
      right = _random.nextInt(min(10, 3 + _level)) + 2;
      symbol = 'x';
      answer = left * right;
    } else if (useSubtract) {
      left = _random.nextInt(maxValue) + 4;
      right = _random.nextInt(left - 1) + 1;
      symbol = '-';
      answer = left - right;
    } else {
      left = _random.nextInt(maxValue) + 1;
      right = _random.nextInt(maxValue) + 1;
      symbol = '+';
      answer = left + right;
    }

    final options = <int>{answer};
    while (options.length < 4) {
      final delta = _random.nextInt(9) - 4;
      final candidate = max(
        0,
        answer + delta + (_random.nextBool() ? _level : 0),
      );
      options.add(candidate);
    }

    final shuffled = options.toList()..shuffle(_random);
    return _EquationRound(
      prompt: '$left $symbol $right = ?',
      answer: answer,
      options: shuffled,
    );
  }

  Future<void> _selectAnswer(int index) async {
    final round = _round;
    if (round == null) return;
    if (_answered) return;
    final picked = round.options[index];
    final correct = picked == round.answer;
    var nextLevel = _level;
    var nextCorrect = _correct;
    var nextMessage = _message;

    if (correct) {
      nextCorrect += 1;
      nextMessage = 'Correct. Nice solving.';
      if (nextCorrect >= _goalCorrect) {
        nextLevel += 1;
        nextCorrect = 0;
        nextMessage = 'Level clear. Level $nextLevel unlocked.';
        await GameStatsStore.instance.recordMathEquationLevel(nextLevel);
        _bestLevel = max(_bestLevel, nextLevel);
      }
    } else {
      nextMessage = 'Not this one. The answer was ${round.answer}.';
    }

    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      _level = nextLevel;
      _correct = nextCorrect;
      _message = nextMessage;
    });
  }

  void _nextQuestion() {
    setState(() {
      _selectedIndex = null;
      _answered = false;
      _round = _generateRound();
      if (_message.startsWith('Level clear')) {
        _message = 'Level $_level: solve $_goalCorrect equations.';
      } else {
        _message = 'Keep going.';
      }
    });
  }

  Future<void> _resetProgress() async {
    await GameStatsStore.instance.recordMathEquationLevel(1);
    if (!mounted) return;
    setState(() {
      _level = 1;
      _bestLevel = max(_bestLevel, 1);
      _correct = 0;
      _selectedIndex = null;
      _answered = false;
      _round = _generateRound();
      _message = 'Progress reset to level 1.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    if (_bestLevel == 0 || round == null) {
      return const SizedBox.shrink();
    }

    return GameScaffold(
      title: 'Math Equation',
      subtitle:
          'An endless level game with sums, subtraction, and multiplication.',
      accent: const [Color(0xffef4444), Color(0xfff97316)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Level',
            leftValue: _level.toString(),
            rightLabel: 'Goal',
            rightValue: '$_correct/$_goalCorrect',
            footer: 'Saved level stays on this device',
          ),
          const SizedBox(height: 18),
          if (_answered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                child: const Text('Next equation'),
              ),
            ),
          if (_answered) const SizedBox(height: 10),
          ResetActionButton(
            label: 'Reset to level 1',
            onPressed: _resetProgress,
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xfff97316)),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                const Text(
                  'Solve this',
                  style: TextStyle(color: Color(0xffcbd5e1)),
                ),
                const SizedBox(height: 12),
                Text(
                  round.prompt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: List.generate(round.options.length, (index) {
              final selected = _selectedIndex == index;
              final correct = _answered && round.options[index] == round.answer;
              final wrong = _answered && selected && !correct;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: correct
                      ? const Color(0xff22c55e)
                      : wrong
                      ? const Color(0xffef4444)
                      : Colors.white.withValues(alpha: 0.08),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: _answered ? null : () => _selectAnswer(index),
                child: Text(
                  round.options[index].toString(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _EquationRound {
  const _EquationRound({
    required this.prompt,
    required this.answer,
    required this.options,
  });

  final String prompt;
  final int answer;
  final List<int> options;
}
