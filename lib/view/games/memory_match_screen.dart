import 'dart:math';

import 'package:flutter/material.dart';

import 'game_scaffold.dart';
import 'game_stats_store.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  final Random _random = Random();

  late List<_MemoryCard> _cards;
  int? _firstIndex;
  int _moves = 0;
  int _matches = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _setupBoard();
  }

  void _setupBoard() {
    const symbols = ['🎯', '🎲', '🚀', '🌟', '🎮', '⚡', '🔥', '🧠'];
    final items = [...symbols, ...symbols]..shuffle(_random);

    final cards = items
        .map((symbol) => _MemoryCard(symbol: symbol))
        .toList(growable: false);

    if (!mounted) {
      _cards = cards;
      _firstIndex = null;
      _moves = 0;
      _matches = 0;
      _busy = false;
      return;
    }

    setState(() {
      _cards = cards;
      _firstIndex = null;
      _moves = 0;
      _matches = 0;
      _busy = false;
    });
  }

  Future<void> _onCardTap(int index) async {
    if (_busy || _cards[index].isMatched || _cards[index].isFlipped) return;

    setState(() {
      _cards[index] = _cards[index].copyWith(isFlipped: true);
    });

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    _moves += 1;
    final first = _firstIndex!;
    _firstIndex = null;

    if (_cards[first].symbol == _cards[index].symbol) {
      setState(() {
        _cards[first] = _cards[first].copyWith(isMatched: true);
        _cards[index] = _cards[index].copyWith(isMatched: true);
        _matches += 1;
      });
      if (_matches == 8) {
        GameStatsStore.instance.recordMemoryBest(_moves);
      }
      return;
    }

    _busy = true;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _cards[first] = _cards[first].copyWith(isFlipped: false);
      _cards[index] = _cards[index].copyWith(isFlipped: false);
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completed = _matches == 8;

    return GameScaffold(
      title: 'Memory Match',
      subtitle: 'Flip pairs, remember positions, and try to finish cleanly.',
      accent: const [Color(0xff6366f1), Color(0xff8b5cf6)],
      child: Column(
        children: [
          ScorePanel(
            leftLabel: 'Moves',
            leftValue: _moves.toString(),
            rightLabel: 'Pairs',
            rightValue: '$_matches/8',
            footer: completed
                ? 'Board cleared. Shuffle and play again.'
                : 'Find all matching pairs.',
          ),
          const SizedBox(height: 20),
          GamePanel(
            padding: const EdgeInsets.all(14),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final card = _cards[index];
                final visible = card.isFlipped || card.isMatched;

                return GestureDetector(
                  onTap: () => _onCardTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: visible
                          ? const LinearGradient(
                              colors: [Color(0xfff59e0b), Color(0xffef4444)],
                            )
                          : const LinearGradient(
                              colors: [Color(0xff1e293b), Color(0xff334155)],
                            ),
                      boxShadow: visible
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xfff59e0b,
                                ).withValues(alpha: 0.18),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          visible ? card.symbol : '?',
                          key: ValueKey('${card.symbol}_${visible.toString()}'),
                          style: TextStyle(
                            fontSize: visible ? 32 : 28,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          StatusCard(
            message: completed
                ? 'Board cleared in $_moves moves. Shuffle for a new round.'
                : _busy
                ? 'Cards are flipping back. Keep track of the symbols.'
                : _firstIndex == null
                ? 'Tap a card to reveal your next match.'
                : 'Pick one more card to complete the turn.',
            accent: const Color(0xff8b5cf6),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _setupBoard,
            child: const Text('Shuffle board'),
          ),
        ],
      ),
    );
  }
}

class _MemoryCard {
  const _MemoryCard({
    required this.symbol,
    this.isFlipped = false,
    this.isMatched = false,
  });

  final String symbol;
  final bool isFlipped;
  final bool isMatched;

  _MemoryCard copyWith({bool? isFlipped, bool? isMatched}) {
    return _MemoryCard(
      symbol: symbol,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}
