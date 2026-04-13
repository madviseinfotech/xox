import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class BombDiffuserScreen extends StatefulWidget {
  const BombDiffuserScreen({super.key});

  @override
  State<BombDiffuserScreen> createState() => _BombDiffuserScreenState();
}

class _BombDiffuserScreenState extends State<BombDiffuserScreen> {
  final Random _random = Random();

  static const int _maxLives = 3;
  static const List<_WireData> _wirePool = [
    _WireData('Red', Color(0xffef4444), _WireGroup.warm),
    _WireData('Gold', Color(0xfff59e0b), _WireGroup.warm),
    _WireData('Orange', Color(0xfff97316), _WireGroup.warm),
    _WireData('Blue', Color(0xff3b82f6), _WireGroup.cool),
    _WireData('Teal', Color(0xff14b8a6), _WireGroup.cool),
    _WireData('Violet', Color(0xff8b5cf6), _WireGroup.cool),
    _WireData('Silver', Color(0xff94a3b8), _WireGroup.neutral),
    _WireData('White', Color(0xffe2e8f0), _WireGroup.neutral),
  ];

  late List<_WireData> _currentWires;
  late _RoundRule _rule;
  int _round = 1;
  int _score = 0;
  int _lives = _maxLives;
  String _message = 'Read the clue and cut the correct wire.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  bool get _gameOver => _lives == 0;

  void _startRound({bool resetGame = false}) {
    final wires = List<_WireData>.from(_wirePool)..shuffle(_random);
    final selected = wires.take(4).toList(growable: false);
    final rule = _buildRule(selected);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = _maxLives;
        _message = 'Read the clue and cut the correct wire.';
      }
      _currentWires = selected;
      _rule = rule;
    });
  }

  _RoundRule _buildRule(List<_WireData> wires) {
    final rules = <_RoundRule>[];

    final alphabetical = [...wires]
      ..sort((a, b) => a.name.compareTo(b.name));
    rules.add(
      _RoundRule(
        clue: 'Cut the wire that comes first alphabetically.',
        answer: alphabetical.first,
      ),
    );
    rules.add(
      _RoundRule(
        clue: 'Cut the wire that comes last alphabetically.',
        answer: alphabetical.last,
      ),
    );

    final byLength = [...wires]
      ..sort((a, b) => a.name.length.compareTo(b.name.length));
    if (byLength.first.name.length != byLength[1].name.length) {
      rules.add(
        _RoundRule(
          clue: 'Cut the wire with the shortest name.',
          answer: byLength.first,
        ),
      );
    }
    if (byLength.last.name.length != byLength[byLength.length - 2].name.length) {
      rules.add(
        _RoundRule(
          clue: 'Cut the wire with the longest name.',
          answer: byLength.last,
        ),
      );
    }

    final warm = wires.where((wire) => wire.group == _WireGroup.warm).toList();
    if (warm.length == 1) {
      rules.add(
        _RoundRule(
          clue: 'Cut the only warm-colored wire.',
          answer: warm.first,
        ),
      );
    }

    final cool = wires.where((wire) => wire.group == _WireGroup.cool).toList();
    if (cool.length == 1) {
      rules.add(
        _RoundRule(
          clue: 'Cut the only cool-colored wire.',
          answer: cool.first,
        ),
      );
    }

    final neutral = wires
        .where((wire) => wire.group == _WireGroup.neutral)
        .toList();
    if (neutral.length == 1) {
      rules.add(
        _RoundRule(
          clue: 'Cut the only neutral wire.',
          answer: neutral.first,
        ),
      );
    }

    rules.add(
      _RoundRule(
        clue: 'Cut the second wire from the top.',
        answer: wires[1],
      ),
    );
    rules.add(
      _RoundRule(
        clue: 'Cut the bottom wire.',
        answer: wires.last,
      ),
    );

    return rules[_random.nextInt(rules.length)];
  }

  Future<void> _cutWire(_WireData wire) async {
    if (_gameOver) return;

    final correct = wire == _rule.answer;
    if (correct) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = '${wire.name} was correct. Next bomb armed.';
      });
      _startRound();
      return;
    }

    final nextLives = _lives - 1;
    if (nextLives <= 0) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _lives = 0;
        _message =
            'Boom. ${wire.name} was wrong. Correct wire: ${_rule.answer.name}.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          '${wire.name} was wrong. ${_rule.answer.name} was safe. Lives left: $nextLives.';
    });
    _startRound();
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xffef4444), Color(0xfff59e0b)];
    return GameScaffold(
      title: 'Bomb Diffuser',
      subtitle: 'Decode the clue and cut the right wire before you run out of lives.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives/$_maxLives',
          ),
          const SizedBox(height: 18),
          StatusCard(
            headline: 'Bomb clue',
            message: _rule.clue,
            accent: accent.last,
            highlight: true,
          ),
          const SizedBox(height: 14),
          StatusCard(message: _message, accent: accent.first),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cut one wire',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                for (final wire in _currentWires) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _gameOver ? null : () => _cutWire(wire),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: wire.color,
                        foregroundColor: wire.textColor,
                        disabledBackgroundColor: wire.color,
                        disabledForegroundColor: wire.textColor.withValues(
                          alpha: 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              wire.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Icon(Icons.content_cut_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset game', onPressed: _resetGame),
        ],
      ),
    );
  }
}

enum _WireGroup { warm, cool, neutral }

class _WireData {
  const _WireData(this.name, this.color, this.group);

  final String name;
  final Color color;
  final _WireGroup group;

  Color get textColor {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    return brightness == Brightness.dark
        ? Colors.white
        : const Color(0xff111827);
  }
}

class _RoundRule {
  const _RoundRule({required this.clue, required this.answer});

  final String clue;
  final _WireData answer;
}
