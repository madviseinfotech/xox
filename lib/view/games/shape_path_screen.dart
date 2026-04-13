import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class ShapePathScreen extends StatefulWidget {
  const ShapePathScreen({super.key});

  @override
  State<ShapePathScreen> createState() => _ShapePathScreenState();
}

class _ShapePathScreenState extends State<ShapePathScreen> {
  final Random _random = Random();
  static const List<String> _shapes = ['Circle', 'Square', 'Triangle', 'Star'];

  late List<String> _path;
  late List<String> _options;
  int _index = 0;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  String _message = 'Follow the shape path in the correct order.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  int get _pathLength => min(3 + (_round - 1), 6);

  void _startRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final nextPath = List<String>.generate(
      min(3 + (nextRound - 1), 6),
      (_) => _shapes[_random.nextInt(_shapes.length)],
    );
    final nextOptions = List<String>.from(_shapes)..shuffle(_random);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _path = nextPath;
      _options = nextOptions;
      _index = 0;
      _message = 'Round $nextRound: tap ${_path.first} first.';
    });
  }

  Future<void> _pickShape(String shape) async {
    if (_lives == 0) return;

    final expected = _path[_index];
    if (shape != expected) {
      final nextLives = _lives - 1;
      if (nextLives <= 0) {
        GameInterstitialService.instance.registerRoundCompletion();
        await GameInterstitialService.instance.maybeShow();
        if (!mounted) return;
        setState(() {
          _lives = 0;
          _message = 'Wrong shape. Game over. Tap reset to start again.';
        });
        return;
      }

      setState(() {
        _lives = nextLives;
        _message = 'Wrong shape. $nextLives lives left. Still need $expected.';
      });
      return;
    }

    final nextIndex = _index + 1;
    if (nextIndex == _path.length) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
      });
      _startRound();
      return;
    }

    setState(() {
      _index = nextIndex;
      _message = 'Good. Next shape is ${_path[_index]}.';
    });
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff22c55e), Color(0xff10b981)];
    return GameScaffold(
      title: 'Shape Path',
      subtitle: 'Remember the path and tap each shape in the right order.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Step: ${_index + 1}/$_pathLength',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Path to follow',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _path
                      .asMap()
                      .entries
                      .map(
                        (entry) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: entry.key < _index
                                ? const Color(0xff22c55e).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _options
                      .map(
                        (shape) => SizedBox(
                          width: 128,
                          child: ElevatedButton(
                            onPressed: () => _pickShape(shape),
                            child: Text(shape),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
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
