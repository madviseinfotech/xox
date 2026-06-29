import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class SymbolMemoryScreen extends StatefulWidget {
  const SymbolMemoryScreen({super.key});

  @override
  State<SymbolMemoryScreen> createState() => _SymbolMemoryScreenState();
}

class _SymbolMemoryScreenState extends State<SymbolMemoryScreen> {
  final Random _random = Random();
  static const List<String> _symbols = ['★', '●', '▲', '■', '◆', '♥'];

  late List<String> _sequence;
  late List<String> _options;
  int _round = 1;
  int _score = 0;
  int _bestRound = 1;
  String _message = 'Memorize the pattern, then pick the correct order.';

  @override
  void initState() {
    super.initState();
    _startRound(resetGame: true);
  }

  int get _sequenceLength => min(3 + (_round - 1), 6);

  void _startRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final length = min(3 + (nextRound - 1), 6);
    final nextSequence = List<String>.generate(
      length,
      (_) => _symbols[_random.nextInt(_symbols.length)],
    );
    final nextOptions = List<String>.from(nextSequence)..shuffle(_random);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _bestRound = 1;
      }
      _sequence = nextSequence;
      _options = nextOptions;
      _message = 'Round $nextRound: tap the symbols in the same order.';
    });
  }

  Future<void> _pickOption(String symbol) async {
    final expected = _sequence[_score % _sequenceLength];
    if (symbol != expected) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _message =
            'Wrong order. The next symbol was $expected. Tap reset to try again.';
      });
      return;
    }

    final nextScore = _score + 1;
    final roundComplete = (nextScore % _sequenceLength) == 0;

    if (!roundComplete) {
      setState(() {
        _score = nextScore;
        _message =
            'Good. ${_sequenceLength - (_score % _sequenceLength)} symbols left this round.';
      });
      return;
    }

    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
    if (!mounted) return;
    setState(() {
      _score = nextScore;
      _round += 1;
      if (_round > _bestRound) {
        _bestRound = _round;
      }
    });
    _startRound();
  }

  void _resetGame() {
    _startRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff8b5cf6), Color(0xff6366f1)];
    return GameScaffold(
      title: 'Symbol Memory',
      subtitle: 'Remember the symbol order and tap it back correctly.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Best',
            rightValue: _bestRound.toString(),
            footer: 'Sequence length: $_sequenceLength • Score: $_score',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remember this order',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _sequence
                      .map(
                        (symbol) => Container(
                          height: 56,
                          width: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            symbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tap in order',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _options
                      .map(
                        (symbol) => SizedBox(
                          width: 72,
                          child: ElevatedButton(
                            onPressed: () => _pickOption(symbol),
                            child: Text(symbol),
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
