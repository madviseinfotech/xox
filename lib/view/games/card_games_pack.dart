import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xox_madvise/services/game_ad_service.dart';

import 'game_scaffold.dart';

class BlackjackScreen extends StatefulWidget {
  const BlackjackScreen({super.key});

  @override
  State<BlackjackScreen> createState() => _BlackjackScreenState();
}

class _BlackjackScreenState extends State<BlackjackScreen> {
  final Random _random = Random();
  final List<_CardFace> _playerHand = [];
  final List<_CardFace> _dealerHand = [];

  bool _roundOver = false;
  String _message = 'Tap Deal to start, then hit or stand.';

  @override
  void initState() {
    super.initState();
    _dealRound();
  }

  void _dealRound() {
    _playerHand
      ..clear()
      ..addAll([_drawCard(), _drawCard()]);
    _dealerHand
      ..clear()
      ..addAll([_drawCard(), _drawCard()]);
    setState(() {
      _roundOver = false;
      _message = 'Your move. Get close to 21 without going over.';
    });
  }

  _CardFace _drawCard() {
    final ranks = [
      'A',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
    ];
    final suits = ['♠', '♥', '♦', '♣'];
    final rank = ranks[_random.nextInt(ranks.length)];
    final suit = suits[_random.nextInt(suits.length)];
    return _CardFace(rank: rank, suit: suit);
  }

  int _scoreHand(List<_CardFace> hand) {
    var total = 0;
    var aces = 0;
    for (final card in hand) {
      switch (card.rank) {
        case 'A':
          aces += 1;
          total += 11;
          break;
        case 'K':
        case 'Q':
        case 'J':
          total += 10;
          break;
        default:
          total += int.parse(card.rank);
      }
    }
    while (total > 21 && aces > 0) {
      total -= 10;
      aces -= 1;
    }
    return total;
  }

  Future<void> _hit() async {
    if (_roundOver) return;
    setState(() {
      _playerHand.add(_drawCard());
    });
    final playerScore = _scoreHand(_playerHand);
    if (playerScore > 21) {
      setState(() {
        _roundOver = true;
        _message = 'Bust. Dealer wins this round.';
      });
      GameInterstitialService.instance.registerRoundCompletion();
      await GameInterstitialService.instance.maybeShow();
    }
  }

  Future<void> _stand() async {
    if (_roundOver) return;
    while (_scoreHand(_dealerHand) < 17) {
      _dealerHand.add(_drawCard());
    }
    final playerScore = _scoreHand(_playerHand);
    final dealerScore = _scoreHand(_dealerHand);
    setState(() {
      _roundOver = true;
      if (dealerScore > 21 || playerScore > dealerScore) {
        _message = 'You win. Nice hand.';
      } else if (playerScore == dealerScore) {
        _message = 'Push. It is a tie.';
      } else {
        _message = 'Dealer wins this round.';
      }
    });
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
  }

  @override
  Widget build(BuildContext context) {
    final playerScore = _scoreHand(_playerHand);
    final dealerScore = _roundOver
        ? _scoreHand(_dealerHand)
        : (_dealerHand.isEmpty ? 0 : _scoreHand([_dealerHand.first]));

    return GameScaffold(
      title: 'Blackjack',
      subtitle: 'Beat the dealer by getting closer to 21.',
      accent: const [Color(0xff16a34a), Color(0xff14532d)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'You',
            leftValue: playerScore.toString(),
            rightLabel: 'Dealer',
            rightValue: dealerScore.toString(),
            footer: _roundOver ? 'Round finished' : 'Hit or stand',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xff16a34a)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _roundOver ? _dealRound : _hit,
                  child: Text(_roundOver ? 'Deal again' : 'Hit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _roundOver ? null : _stand,
                  child: const Text('Stand'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GamePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dealer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_dealerHand.length, (index) {
                    final hidden = !_roundOver && index == 1;
                    return _PlayingCard(
                      face: hidden ? null : _dealerHand[index],
                    );
                  }),
                ),
                const SizedBox(height: 18),
                const Text(
                  'You',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _playerHand
                      .map((card) => _PlayingCard(face: card))
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WarCardsScreen extends StatefulWidget {
  const WarCardsScreen({super.key});

  @override
  State<WarCardsScreen> createState() => _WarCardsScreenState();
}

class _WarCardsScreenState extends State<WarCardsScreen> {
  final Random _random = Random();
  int _playerWins = 0;
  int _cpuWins = 0;
  _CardFace? _playerCard;
  _CardFace? _cpuCard;
  String _message = 'Tap Flip Cards to compare the two cards.';

  _CardFace _drawCard() {
    final ranks = [
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
      'A',
    ];
    final suits = ['♠', '♥', '♦', '♣'];
    return _CardFace(
      rank: ranks[_random.nextInt(ranks.length)],
      suit: suits[_random.nextInt(suits.length)],
    );
  }

  int _value(_CardFace card) {
    const order = {
      '2': 2,
      '3': 3,
      '4': 4,
      '5': 5,
      '6': 6,
      '7': 7,
      '8': 8,
      '9': 9,
      '10': 10,
      'J': 11,
      'Q': 12,
      'K': 13,
      'A': 14,
    };
    return order[card.rank]!;
  }

  Future<void> _flipCards() async {
    final player = _drawCard();
    final cpu = _drawCard();
    final playerValue = _value(player);
    final cpuValue = _value(cpu);

    setState(() {
      _playerCard = player;
      _cpuCard = cpu;
      if (playerValue > cpuValue) {
        _playerWins += 1;
        _message = 'You win this flip.';
      } else if (playerValue < cpuValue) {
        _cpuWins += 1;
        _message = 'CPU wins this flip.';
      } else {
        _message = 'Tie. Flip again.';
      }
    });
    GameInterstitialService.instance.registerRoundCompletion();
    await GameInterstitialService.instance.maybeShow();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'War Cards',
      subtitle: 'Flip one card each and the higher card wins.',
      accent: const [Color(0xfff97316), Color(0xffef4444)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'You',
            leftValue: _playerWins.toString(),
            rightLabel: 'CPU',
            rightValue: _cpuWins.toString(),
            footer: 'Higher card wins each round',
          ),
          const SizedBox(height: 18),
          StatusCard(message: _message, accent: const Color(0xffef4444)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _flipCards,
              child: const Text('Flip cards'),
            ),
          ),
          const SizedBox(height: 18),
          GamePanel(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text(
                      'You',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PlayingCard(face: _playerCard),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'CPU',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PlayingCard(face: _cpuCard),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFace {
  const _CardFace({required this.rank, required this.suit});

  final String rank;
  final String suit;
}

class _PlayingCard extends StatelessWidget {
  const _PlayingCard({required this.face});

  final _CardFace? face;

  @override
  Widget build(BuildContext context) {
    final isRed = face?.suit == '♥' || face?.suit == '♦';
    return Container(
      height: 104,
      width: 72,
      decoration: BoxDecoration(
        color: face == null ? const Color(0xff1e3a8a) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: face == null
          ? const Center(
              child: Icon(Icons.style_rounded, color: Colors.white, size: 28),
            )
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    face!.rank,
                    style: TextStyle(
                      color: isRed
                          ? const Color(0xffdc2626)
                          : const Color(0xff0f172a),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Text(
                      face!.suit,
                      style: TextStyle(
                        fontSize: 24,
                        color: isRed
                            ? const Color(0xffdc2626)
                            : const Color(0xff0f172a),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      face!.rank,
                      style: TextStyle(
                        color: isRed
                            ? const Color(0xffdc2626)
                            : const Color(0xff0f172a),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
