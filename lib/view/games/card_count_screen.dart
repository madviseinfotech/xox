import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class CardCountScreen extends StatefulWidget {
  const CardCountScreen({super.key});

  @override
  State<CardCountScreen> createState() => _CardCountScreenState();
}

class _CardCountScreenState extends State<CardCountScreen> {
  final Random _random = Random();
  static const List<String> _suits = ['♠', '♥', '♦', '♣'];

  late List<_CardTile> _cards;
  late List<int> _options;
  int _answer = 0;
  int _round = 1;
  int _score = 0;
  int _lives = 3;
  String _message = 'Add the card values and pick the correct total.';

  @override
  void initState() {
    super.initState();
    _nextRound(resetGame: true);
  }

  void _nextRound({bool resetGame = false}) {
    final nextRound = resetGame ? 1 : _round;
    final cardCount = min(3 + ((nextRound - 1) ~/ 2), 5);
    final cards = List<_CardTile>.generate(
      cardCount,
      (_) => _CardTile(
        suit: _suits[_random.nextInt(_suits.length)],
        value: _random.nextInt(9) + 1,
      ),
    );
    final answer = cards.fold<int>(0, (sum, card) => sum + card.value);
    final options = <int>{answer};
    while (options.length < 4) {
      final guess = max(3, answer + _random.nextInt(7) - 3);
      options.add(guess);
    }
    final shuffledOptions = options.toList()..shuffle(_random);

    setState(() {
      if (resetGame) {
        _round = 1;
        _score = 0;
        _lives = 3;
      }
      _cards = cards;
      _answer = answer;
      _options = shuffledOptions;
      _message = 'Round $nextRound: count the ${cards.length} cards.';
    });
  }

  Future<void> _pickTotal(int total) async {
    if (_lives == 0) return;
    if (total == _answer) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = 'Correct total: $_answer.';
      });
      _nextRound();
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
            'Wrong total. Correct answer was $_answer. Tap reset to try again.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          'Wrong total. Correct answer was $_answer. Lives left: $nextLives.';
    });
    _nextRound();
  }

  void _resetGame() {
    _nextRound(resetGame: true);
  }

  @override
  Widget build(BuildContext context) {
    final accent = const [Color(0xff166534), Color(0xff14532d)];
    return GameScaffold(
      title: 'Card Count',
      subtitle: 'Read the cards, add the values, and choose the right total.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer: 'Lives: $_lives • Cards: ${_cards.length}',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: accent.last),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _cards
                      .map(
                        (card) => Container(
                          width: 78,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${card.value}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                card.suit,
                                style: TextStyle(
                                  color: card.suit == '♥' || card.suit == '♦'
                                      ? const Color(0xfffb7185)
                                      : Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _options
                      .map(
                        (option) => SizedBox(
                          width: 86,
                          child: ElevatedButton(
                            onPressed: _lives == 0
                                ? null
                                : () => _pickTotal(option),
                            child: Text('$option'),
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

class _CardTile {
  const _CardTile({required this.suit, required this.value});

  final String suit;
  final int value;
}
