import 'dart:math';

import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class ColorMatchScreen extends StatefulWidget {
  const ColorMatchScreen({super.key});

  @override
  State<ColorMatchScreen> createState() => _ColorMatchScreenState();
}

class _ColorMatchScreenState extends State<ColorMatchScreen> {
  final Random _random = Random();
  final List<_ColorChoice> _choices = const [
    _ColorChoice('Red', Color(0xffef4444)),
    _ColorChoice('Blue', Color(0xff3b82f6)),
    _ColorChoice('Green', Color(0xff22c55e)),
    _ColorChoice('Yellow', Color(0xfffacc15)),
    _ColorChoice('Purple', Color(0xffa855f7)),
    _ColorChoice('Orange', Color(0xfff97316)),
  ];

  late _ColorChoice _target;
  int _level = 1;
  int _score = 0;
  int _bestScore = 0;
  int _rounds = 0;
  String _message = 'Tap the color that matches the card.';

  @override
  void initState() {
    super.initState();
    _target = _choices.first;
    _loadBest();
    _nextTarget();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _bestScore = snapshot.colorMatchBestScore;
    });
  }

  List<_ColorChoice> get _activeChoices {
    final count = (_level + 3).clamp(4, _choices.length);
    return _choices.take(count).toList(growable: false);
  }

  int get _targetScore => 4 + _level;

  void _nextTarget() {
    setState(() {
      final activeChoices = _activeChoices;
      _target = activeChoices[_random.nextInt(activeChoices.length)];
    });
  }

  Future<void> _pickColor(_ColorChoice choice) async {
    final correct = choice.label == _target.label;
    final nextScore = correct ? _score + 1 : 0;

    setState(() {
      _rounds += 1;
      _score = nextScore;
      _message = correct
          ? 'Great job. ${choice.label} is correct.'
          : 'Oops. That was ${_target.label}. Try again.';
    });

    if (nextScore > _bestScore) {
      await GameStatsStore.instance.recordColorMatchBestScore(nextScore);
      if (!mounted) return;
      setState(() {
        _bestScore = nextScore;
      });
    }

    if (correct && nextScore >= _targetScore) {
      if (!mounted) return;
      setState(() {
        _level += 1;
        _score = 0;
        _message = 'Level clear. Level $_level unlocked.';
      });
    }

    _nextTarget();
  }

  void _resetGame() {
    setState(() {
      _level = 1;
      _score = 0;
      _rounds = 0;
      _message = 'Tap the color that matches the card.';
    });
    _nextTarget();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Color Match',
      subtitle: 'Simple color choices that are bright, playful, and friendly.',
      accent: const [Color(0xff22c55e), Color(0xff38bdf8)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Level',
            leftValue: _level.toString(),
            rightLabel: 'Best',
            rightValue: _bestScore.toString(),
            footer: 'Streak $_score/$_targetScore • Rounds played: $_rounds',
          ),
          const SizedBox(height: 20),
          GamePanel(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Text(
                  'Tap this color',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xff94a3b8),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: _target.color,
                    boxShadow: [
                      BoxShadow(
                        color: _target.color.withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _target.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xff38bdf8)),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: _activeChoices
                .map(
                  (choice) => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: choice.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: () => _pickColor(choice),
                    child: Text(choice.label),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset game', onPressed: _resetGame),
        ],
      ),
    );
  }
}

class _ColorChoice {
  const _ColorChoice(this.label, this.color);

  final String label;
  final Color color;
}
