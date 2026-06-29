import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class SuitStreakScreen extends StatefulWidget {
  const SuitStreakScreen({super.key});

  @override
  State<SuitStreakScreen> createState() => _SuitStreakScreenState();
}

class _SuitStreakScreenState extends State<SuitStreakScreen> {
  final Random _random = Random();

  static const int _maxLives = 3;
  static const List<_SuitCard> _deck = <_SuitCard>[
    _SuitCard('A', 'Hearts', Color(0xffef4444), Icons.favorite_rounded),
    _SuitCard('K', 'Spades', Color(0xffcbd5e1), Icons.spa_rounded),
    _SuitCard('Q', 'Diamonds', Color(0xfff97316), Icons.diamond_rounded),
    _SuitCard('J', 'Clubs', Color(0xff22c55e), Icons.filter_vintage_rounded),
  ];

  late List<_SuitCard> _shownCards;
  late String _targetSuit;
  int _score = 0;
  int _round = 1;
  int _lives = _maxLives;
  String _message = 'Count the shown cards and pick which suit appears most.';

  @override
  void initState() {
    super.initState();
    _nextRound(resetGame: true);
  }

  void _nextRound({bool resetGame = false}) {
    late List<_SuitCard> cards;
    late String targetSuit;

    while (true) {
      cards = List<_SuitCard>.generate(
        6 + min(4, _round - 1),
        (_) => _deck[_random.nextInt(_deck.length)],
      );
      final counts = <String, int>{};
      for (final card in cards) {
        counts.update(card.suit, (value) => value + 1, ifAbsent: () => 1);
      }
      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.length > 1 && sorted[0].value != sorted[1].value) {
        targetSuit = sorted.first.key;
        break;
      }
    }

    setState(() {
      if (resetGame) {
        _score = 0;
        _round = 1;
        _lives = _maxLives;
      }
      _shownCards = cards;
      _targetSuit = targetSuit;
      _message = 'Study the spread and tap the suit with the highest count.';
    });
  }

  Future<void> _pickSuit(String suit) async {
    if (_lives == 0) return;

    if (suit == _targetSuit) {
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
      if (!mounted) return;
      setState(() {
        _score += 1;
        _round += 1;
        _message = '$suit leads the spread. Next hand coming up.';
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
        _message = 'Wrong suit. Game over. Correct answer was $_targetSuit.';
      });
      return;
    }

    setState(() {
      _lives = nextLives;
      _message =
          'Not quite. $_targetSuit had the most cards. Lives left: $nextLives.';
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
      title: 'Suit Streak',
      subtitle: 'Read the card spread and spot which suit appears most often.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Round',
            leftValue: _round.toString(),
            rightLabel: 'Score',
            rightValue: _score.toString(),
            footer:
                'Lives: $_lives/$_maxLives • Offline card counting challenge',
          ),
          const SizedBox(height: 18),
          StatusCard(
            headline: 'Card rules',
            message:
                'A short spread of cards appears each round. Count the suits and tap the one with the highest total.',
            accent: accent.last,
            highlight: true,
          ),
          const SizedBox(height: 14),
          StatusCard(message: _message, accent: accent.first),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _shownCards
                      .map(
                        (card) => Container(
                          width: 86,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
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
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  card.rank,
                                  style: TextStyle(
                                    color: card.color,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Icon(card.icon, color: card.color, size: 30),
                              const SizedBox(height: 8),
                              Text(
                                card.suit,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _deck
                      .map(
                        (card) => SizedBox(
                          width: 140,
                          child: ElevatedButton.icon(
                            onPressed: _lives == 0
                                ? null
                                : () => _pickSuit(card.suit),
                            icon: Icon(card.icon, color: card.color),
                            label: Text(card.suit),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ResetActionButton(label: 'Reset cards', onPressed: _resetGame),
        ],
      ),
    );
  }
}

class _SuitCard {
  const _SuitCard(this.rank, this.suit, this.color, this.icon);

  final String rank;
  final String suit;
  final Color color;
  final IconData icon;
}
