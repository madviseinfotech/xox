import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class PokerBluffScreen extends StatefulWidget {
  const PokerBluffScreen({super.key});

  @override
  State<PokerBluffScreen> createState() => _PokerBluffScreenState();
}

class _PokerBluffScreenState extends State<PokerBluffScreen> {
  static const List<String> _suits = ['♠', '♥', '♦', '♣'];
  static const List<String> _ranks = [
    '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A',
  ];

  final Random _rng = Random();

  List<_Card> _deck = [];
  List<_Card> _playerHand = [];
  List<_Card> _cpuHand = [];
  List<bool> _revealed = [];

  int _playerWins = 0;
  int _cpuWins = 0;
  int _bestStreak = 0;
  int _streak = 0;
  int _round = 0;
  bool _dealt = false;
  bool _showResult = false;
  bool _playerWon = false;
  String _playerRank = '';
  String _cpuRank = '';
  String _message = 'Tap Deal to get your 5-card hand and beat the CPU.';

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final snapshot = await GameStatsStore.instance.loadSnapshot();
    if (!mounted) return;
    setState(() => _bestStreak = snapshot.pokerBluffBestStreak);
  }

  void _buildDeck() {
    _deck = [];
    for (final suit in _suits) {
      for (int i = 0; i < _ranks.length; i++) {
        _deck.add(_Card(rank: _ranks[i], suit: suit, value: i + 2));
      }
    }
    _deck.shuffle(_rng);
  }

  void _deal() {
    _buildDeck();
    final playerHand = _deck.sublist(0, 5);
    final cpuHand = _deck.sublist(5, 10);
    setState(() {
      _playerHand = playerHand;
      _cpuHand = cpuHand;
      _revealed = List.filled(5, false);
      _dealt = true;
      _showResult = false;
      _playerWon = false;
      _playerRank = '';
      _cpuRank = '';
      _message = 'Your hand is dealt. Tap Reveal to see who wins.';
    });
    // Reveal cards one by one
    for (int i = 0; i < 5; i++) {
      Future<void>.delayed(Duration(milliseconds: 150 * (i + 1)), () {
        if (!mounted) return;
        setState(() => _revealed[i] = true);
      });
    }
  }

  Future<void> _reveal() async {
    if (!_dealt || _showResult) return;

    final playerScore = _handScore(_playerHand);
    final cpuScore = _handScore(_cpuHand);
    final won = playerScore >= cpuScore;

    final nextStreak = won ? _streak + 1 : 0;
    final nextBest = nextStreak > _bestStreak ? nextStreak : _bestStreak;

    if (nextBest > _bestStreak) {
      await GameStatsStore.instance.recordPokerBluffBestStreak(nextBest);
    }

    setState(() {
      _showResult = true;
      _playerWon = won;
      _playerRank = _handName(_playerHand);
      _cpuRank = _handName(_cpuHand);
      _round++;
      if (won) {
        _playerWins++;
        _streak = nextStreak;
      } else {
        _cpuWins++;
        _streak = 0;
      }
      _bestStreak = nextBest;
      _message = won
          ? 'You win! $_playerRank beats $_cpuRank.'
          : 'CPU wins with $_cpuRank. Your hand: $_playerRank.';
    });

    GameInterstitialService.instance.registerRoundCompletion();
    if (_round % 4 == 0) {
      unawaited(GameInterstitialService.instance.maybeShow());
    }
  }

  // Hand scoring: higher = better
  int _handScore(List<_Card> hand) {
    final values = hand.map((c) => c.value).toList()..sort();
    final suits = hand.map((c) => c.suit).toSet();
    final valueCounts = <int, int>{};
    for (final v in values) {
      valueCounts[v] = (valueCounts[v] ?? 0) + 1;
    }
    final counts = valueCounts.values.toList()..sort((a, b) => b.compareTo(a));
    final isFlush = suits.length == 1;
    final isStraight = values.last - values.first == 4 && valueCounts.length == 5;

    if (isFlush && isStraight) return 8000 + values.last;
    if (counts[0] == 4) return 7000 + _topValue(valueCounts, 4);
    if (counts[0] == 3 && counts[1] == 2) return 6000 + _topValue(valueCounts, 3);
    if (isFlush) return 5000 + values.last;
    if (isStraight) return 4000 + values.last;
    if (counts[0] == 3) return 3000 + _topValue(valueCounts, 3);
    if (counts[0] == 2 && counts[1] == 2) return 2000 + _topValue(valueCounts, 2);
    if (counts[0] == 2) return 1000 + _topValue(valueCounts, 2);
    return values.last;
  }

  int _topValue(Map<int, int> counts, int target) {
    return counts.entries
        .where((e) => e.value == target)
        .map((e) => e.key)
        .reduce(max);
  }

  String _handName(List<_Card> hand) {
    final values = hand.map((c) => c.value).toList()..sort();
    final suits = hand.map((c) => c.suit).toSet();
    final valueCounts = <int, int>{};
    for (final v in values) {
      valueCounts[v] = (valueCounts[v] ?? 0) + 1;
    }
    final counts = valueCounts.values.toList()..sort((a, b) => b.compareTo(a));
    final isFlush = suits.length == 1;
    final isStraight = values.last - values.first == 4 && valueCounts.length == 5;

    if (isFlush && isStraight) return 'Straight Flush';
    if (counts[0] == 4) return 'Four of a Kind';
    if (counts[0] == 3 && counts[1] == 2) return 'Full House';
    if (isFlush) return 'Flush';
    if (isStraight) return 'Straight';
    if (counts[0] == 3) return 'Three of a Kind';
    if (counts[0] == 2 && counts[1] == 2) return 'Two Pair';
    if (counts[0] == 2) return 'One Pair';
    return 'High Card';
  }

  @override
  Widget build(BuildContext context) {
    const accent = [Color(0xff166534), Color(0xff14532d)];
    return GameScaffold(
      title: 'Poker Bluff',
      subtitle: 'Get a 5-card hand and beat the CPU with a stronger rank.',
      accent: accent,
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Your Wins',
            leftValue: '$_playerWins',
            rightLabel: 'CPU Wins',
            rightValue: '$_cpuWins',
            footer:
                'Streak $_streak  •  Best streak $_bestStreak  •  Round $_round',
          ),
          const SizedBox(height: 8),
          StatusCard(
            message: _message,
            accent: _showResult
                ? (_playerWon
                      ? const Color(0xff22c55e)
                      : const Color(0xffef4444))
                : const Color(0xff22c55e),
            highlight: _showResult,
            headline: _showResult ? (_playerWon ? '🏆 You Win!' : '💀 CPU Wins') : null,
          ),
          const SizedBox(height: 8),
          // Player hand
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Your Hand',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    if (_showResult) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0xff22c55e).withValues(alpha: 0.2),
                          border: Border.all(
                            color: const Color(0xff22c55e),
                          ),
                        ),
                        child: Text(
                          _playerRank,
                          style: const TextStyle(
                            color: Color(0xff22c55e),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _dealt
                      ? List.generate(5, (i) => _revealed.length > i && _revealed[i]
                            ? _CardWidget(card: _playerHand[i])
                            : _CardBack())
                      : List.generate(5, (_) => _CardBack()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // CPU hand
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'CPU Hand',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    if (_showResult) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0xffef4444).withValues(alpha: 0.2),
                          border: Border.all(color: const Color(0xffef4444)),
                        ),
                        child: Text(
                          _cpuRank,
                          style: const TextStyle(
                            color: Color(0xffef4444),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _dealt
                      ? List.generate(
                          5,
                          (i) => _showResult
                              ? _CardWidget(card: _cpuHand[i])
                              : _CardBack(),
                        )
                      : List.generate(5, (_) => _CardBack()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _deal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xff166534),
                  ),
                  child: const Text(
                    '🃏 Deal',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _dealt && !_showResult ? _reveal : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    '👁 Reveal',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card {
  const _Card({required this.rank, required this.suit, required this.value});
  final String rank;
  final String suit;
  final int value;
  bool get isRed => suit == '♥' || suit == '♦';
}

class _CardWidget extends StatelessWidget {
  const _CardWidget({required this.card});
  final _Card card;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 3,
            child: Text(
              card.rank,
              style: TextStyle(
                color: card.isRed ? const Color(0xffdc2626) : const Color(0xff111827),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          Center(
            child: Text(
              card.suit,
              style: TextStyle(
                color: card.isRed ? const Color(0xffdc2626) : const Color(0xff111827),
                fontSize: 20,
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 3,
            child: RotatedBox(
              quarterTurns: 2,
              child: Text(
                card.rank,
                style: TextStyle(
                  color: card.isRed ? const Color(0xffdc2626) : const Color(0xff111827),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1e3a5f), Color(0xff0f172a)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '🂠',
          style: TextStyle(
            fontSize: 28,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
